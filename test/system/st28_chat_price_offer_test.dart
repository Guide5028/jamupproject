// ST-28 — Chat Price Offer Negotiation
//
// Pumps ChatPage with a fake MessagesRepository and verifies the new
// structured "price offer" flow: sending an offer, validating the amount,
// rendering it as a distinct card, and the recipient accepting/declining it.
// Also covers the "Posted rate" context banner pulled from the gig.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jamup_app/features/messages/pages/chat_page.dart';
import 'package:jamup_app/features/messages/data/messages_repository.dart';

// ── Fake repository ────────────────────────────────────────────────────────

class _FakeMessagesRepo extends MessagesRepository {
  List<Map<String, dynamic>> seedMessages = [];

  String? lastOfferChatId;
  double? lastOfferAmount;
  String? lastOfferUnit;

  String? lastRespondedMessageId;
  String? lastRespondedStatus;

  @override
  Stream<List<Map<String, dynamic>>> messageStream({required String chatId}) =>
      Stream.value(seedMessages);

  @override
  Future<void> markAsRead({required String chatId}) async {}

  @override
  Future<void> sendPriceOffer({
    required String chatId,
    required double amount,
    required String unit,
  }) async {
    lastOfferChatId = chatId;
    lastOfferAmount = amount;
    lastOfferUnit = unit;
  }

  @override
  Future<void> respondToPriceOffer({
    required String messageId,
    required String status,
  }) async {
    lastRespondedMessageId = messageId;
    lastRespondedStatus = status;
  }

  @override
  Future<void> sendNotification({
    required String receiverId,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
  }) async {}

  @override
  Future<String?> resolveReceiverId({
    required String bookingId,
    required String? myUserId,
  }) async =>
      null;
}

// ── Fixtures ─────────────────────────────────────────────────────────────

Map<String, dynamic> _offerFixture({required String senderId}) => {
      'id': 'msg-offer-1',
      'sender_id': senderId,
      'text': 'Price offer: ฿1,500/hr',
      'type': 'offer',
      'offer_amount': 1500.0,
      'offer_unit': 'per_hour',
      'offer_status': 'pending',
      'created_at': DateTime(2026, 1, 1).toIso8601String(),
      'read_at': null,
    };

Widget _buildPage(
  _FakeMessagesRepo repo, {
  double? gigPayment,
  String? gigPaymentUnit,
}) {
  return MaterialApp(
    home: ChatPage(
      name: 'Test Venue',
      avatar: '',
      chatId: 'chat-1',
      bookingId: 'b1',
      otherUserId: 'other-1',
      messagesRepository: repo,
      gigPayment: gigPayment,
      gigPaymentUnit: gigPaymentUnit,
    ),
  );
}

// ── Tests ────────────────────────────────────────────────────────────────

void main() {
  group('ST-28 — Chat Price Offer Negotiation', () {
    testWidgets('Tapping the offer button opens the Send Offer sheet',
        (tester) async {
      final repo = _FakeMessagesRepo();
      await tester.pumpWidget(_buildPage(repo));
      await tester.pump();

      await tester.tap(find.byKey(const Key('send_offer_button')));
      await tester.pumpAndSettle();

      expect(find.text('Send a Price Offer'), findsOneWidget,
          reason: 'Tapping the money icon must open the offer composer');
      expect(find.byKey(const Key('offer_amount_field')), findsOneWidget);
    });

    testWidgets(
        'Sending a valid offer calls sendPriceOffer and renders an offer bubble',
        (tester) async {
      final repo = _FakeMessagesRepo();
      await tester.pumpWidget(_buildPage(repo));
      await tester.pump();

      await tester.tap(find.byKey(const Key('send_offer_button')));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const Key('offer_amount_field')), '1500');
      await tester.tap(find.text('Per Hour'));
      await tester.pump();

      await tester.tap(find.byKey(const Key('confirm_offer_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(repo.lastOfferChatId, 'chat-1');
      expect(repo.lastOfferAmount, 1500.0,
          reason: 'Repository must receive the parsed numeric amount');
      expect(repo.lastOfferUnit, 'per_hour');

      expect(find.text('฿1,500/hr'), findsOneWidget,
          reason: 'The new offer must render immediately as a bubble');
      expect(find.text('Pending'), findsOneWidget);
    });

    testWidgets('An empty amount shows a validation error and never calls the repo',
        (tester) async {
      final repo = _FakeMessagesRepo();
      await tester.pumpWidget(_buildPage(repo));
      await tester.pump();

      await tester.tap(find.byKey(const Key('send_offer_button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('confirm_offer_button')));
      await tester.pump();

      expect(find.text('Enter a valid amount'), findsOneWidget);
      expect(repo.lastOfferAmount, isNull,
          reason: 'An invalid amount must never reach sendPriceOffer');
    });

    testWidgets('An incoming pending offer shows Accept and Decline buttons',
        (tester) async {
      final repo = _FakeMessagesRepo()
        ..seedMessages = [_offerFixture(senderId: 'other-1')];
      await tester.pumpWidget(_buildPage(repo));
      await tester.pump();
      await tester.pump();

      expect(find.text('Accept'), findsOneWidget,
          reason: 'Recipient of a pending offer must be able to accept it');
      expect(find.text('Decline'), findsOneWidget);
    });

    testWidgets('Tapping Accept calls respondToPriceOffer and updates the badge',
        (tester) async {
      final repo = _FakeMessagesRepo()
        ..seedMessages = [_offerFixture(senderId: 'other-1')];
      await tester.pumpWidget(_buildPage(repo));
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('Accept'));
      await tester.pump();

      expect(repo.lastRespondedMessageId, 'msg-offer-1');
      expect(repo.lastRespondedStatus, 'accepted');
      expect(find.text('Accepted'), findsOneWidget);
      expect(find.text('Accept'), findsNothing,
          reason: 'Buttons must disappear once the offer is decided');
      expect(find.text('Decline'), findsNothing);
    });

    testWidgets('Tapping Decline calls respondToPriceOffer with declined',
        (tester) async {
      final repo = _FakeMessagesRepo()
        ..seedMessages = [_offerFixture(senderId: 'other-1')];
      await tester.pumpWidget(_buildPage(repo));
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('Decline'));
      await tester.pump();

      expect(repo.lastRespondedStatus, 'declined');
      expect(find.text('Declined'), findsOneWidget);
    });

    testWidgets('My own pending offer never shows Accept/Decline buttons',
        (tester) async {
      final repo = _FakeMessagesRepo()
        ..seedMessages = [_offerFixture(senderId: 'me')];
      await tester.pumpWidget(_buildPage(repo));
      await tester.pump();
      await tester.pump();

      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('Accept'), findsNothing,
          reason: 'A sender must not be able to accept/decline their own offer');
      expect(find.text('Decline'), findsNothing);
    });

    testWidgets('Posted rate banner shows the gig payment when supplied',
        (tester) async {
      final repo = _FakeMessagesRepo();
      await tester.pumpWidget(
        _buildPage(repo, gigPayment: 2500, gigPaymentUnit: 'per_day'),
      );
      await tester.pump();

      expect(find.textContaining('Posted rate'), findsOneWidget);
      expect(find.textContaining('2,500/day'), findsOneWidget);
    });
  });
}
