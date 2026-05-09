// ST-27 — Venue Edits an Existing Gig
//
// Pumps EditGigPage with a pre-populated Gig and a fake GigRepository.
// Verifies that the form pre-fills existing values, accepts changes to
// title, and calls updateGig with the new values on save.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jamup_app/features/gigs/pages/edit_gig_page.dart';
import 'package:jamup_app/features/gigs/data/gig_repository.dart';
import 'package:jamup_app/models/gig.dart';

// ── Fake repository ────────────────────────────────────────────────────────

class _FakeGigRepo extends GigRepository {
  Map<String, dynamic>? lastUpdate;

  @override
  Future<void> updateGig({
    required String gigId,
    required String title,
    required String description,
    required DateTime date,
    required String location,
    required List<String> genres,
    String imageUrl = '',
    double? latitude,
    double? longitude,
    double? payment,
    String? paymentUnit,
    String? roleNeeded,
    int? slots,
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    lastUpdate = {
      'gigId': gigId,
      'title': title,
      'description': description,
    };
  }
}

// ── Fixture ────────────────────────────────────────────────────────────────

Gig _existingGig() => Gig(
      id: 'g1',
      title: 'Original Jazz Night',
      description: 'Original description',
      location: 'Bangkok',
      date: DateTime(2026, 8, 15, 20, 0),
      imageUrl: '',
      genres: const ['Jazz'],
      venueId: 'v1',
      musicianId: '',
      latitude: 13.7,
      longitude: 100.5,
      roleNeeded: 'Singer',
      payment: 3000,
    );

/// The save button key declared in EditGigPage.
final _saveBtn = find.byKey(const Key('save_gig_button'));

/// Scrolls the form ListView until the save button is in the viewport.
Future<void> _scrollToSave(WidgetTester tester) =>
    tester.scrollUntilVisible(_saveBtn, 200,
        scrollable: find.byType(Scrollable).first);

// ── Test ───────────────────────────────────────────────────────────────────

void main() {
  group('ST-27 — Venue Edits an Existing Gig', () {
    /// Give the test a tall viewport so the Save button is reachable.
    setUp(() async {});

    testWidgets('Edit Gig page pre-fills the existing title', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(home: EditGigPage(gig: _existingGig())),
      );
      await tester.pump();

      expect(find.text('Original Jazz Night'), findsOneWidget,
          reason: 'Title field must be pre-populated with the existing value');
    });

    testWidgets('Edit Gig page shows a Save Changes button', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(home: EditGigPage(gig: _existingGig())),
      );
      await tester.pump();
      await _scrollToSave(tester);

      expect(_saveBtn, findsOneWidget,
          reason: 'Edit page must have a Save Changes button');
    });

    testWidgets('Clearing title and saving shows validation error',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(home: EditGigPage(gig: _existingGig())),
      );
      await tester.pump();

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Title'), '');

      await _scrollToSave(tester);
      await tester.tap(_saveBtn);
      await tester.pump();

      expect(find.text('Title required'), findsOneWidget,
          reason: 'Empty title must trigger a validation error');
    });

    testWidgets('Updating title calls updateGig with new title', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final fakeRepo = _FakeGigRepo();

      await tester.pumpWidget(
        MaterialApp(home: EditGigPage(gig: _existingGig(), repo: fakeRepo)),
      );
      await tester.pump();

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Title'), 'Updated Title ST-27');
      await tester.pump();

      await _scrollToSave(tester);
      await tester.tap(_saveBtn);
      await tester.pump(const Duration(seconds: 1));

      expect(fakeRepo.lastUpdate, isNotNull,
          reason: 'updateGig must be called when the form is valid');
      expect(fakeRepo.lastUpdate!['title'], 'Updated Title ST-27',
          reason: 'New title must be passed to the repository');
      expect(fakeRepo.lastUpdate!['gigId'], 'g1');
    });

    testWidgets('No error snackbar shown after successful save', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final fakeRepo = _FakeGigRepo();

      await tester.pumpWidget(
        MaterialApp(home: EditGigPage(gig: _existingGig(), repo: fakeRepo)),
      );
      await tester.pump();

      await _scrollToSave(tester);
      await tester.tap(_saveBtn);
      await tester.pump(const Duration(seconds: 1));

      expect(find.textContaining('Error'), findsNothing);
      expect(find.textContaining('failed'), findsNothing);
    });
  });
}
