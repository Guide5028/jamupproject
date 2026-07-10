// MessagesController — loads the chat inbox via MessagesRepository.
//
// Mirrors the fake-repository pattern used by booking_controller_test.dart:
// a fake subclasses the repository and overrides the one method that talks
// to Supabase, so the controller's own load/error/loading logic is what
// actually gets exercised.

import 'package:flutter_test/flutter_test.dart';
import 'package:jamup_app/features/messages/controllers/messages_controller.dart';
import 'package:jamup_app/features/messages/data/messages_repository.dart';

class _FakeMessagesRepository extends MessagesRepository {
  List<Map<String, dynamic>> seedConversations = [];
  bool throwOnLoad = false;

  @override
  Future<List<Map<String, dynamic>>> fetchConversations() async {
    if (throwOnLoad) throw Exception('network unavailable');
    return seedConversations;
  }
}

void main() {
  group('MessagesController — load happy path', () {
    test('populates conversations and clears loading', () async {
      final repo = _FakeMessagesRepository()
        ..seedConversations = [
          {'chat_id': 'c1', 'other_name': 'The Jazz Cellar', 'unread_count': 2},
          {'chat_id': 'c2', 'other_name': 'Nadia Siriwan', 'unread_count': 0},
        ];
      final ctrl = MessagesController(repo);

      var updateCount = 0;
      await ctrl.load(() => updateCount++);

      expect(ctrl.conversations.length, 2);
      expect(ctrl.isLoading, false);
    });

    test('loading flag is true during the fetch and false after', () async {
      final repo = _FakeMessagesRepository();
      final ctrl = MessagesController(repo);

      final loadingStates = <bool>[];
      await ctrl.load(() => loadingStates.add(ctrl.isLoading));

      // First callback fires right after loading=true is set, the second
      // after it's reset to false — the UI's spinner-then-content contract.
      expect(loadingStates.first, true);
      expect(loadingStates.last, false);
    });
  });

  group('MessagesController — load error path', () {
    test('error lands in `error`, loading clears, conversations stay empty',
        () async {
      final repo = _FakeMessagesRepository()..throwOnLoad = true;
      final ctrl = MessagesController(repo);

      await ctrl.load(() {});

      expect(ctrl.error, contains('network unavailable'));
      // Loading must still be reset even though the fetch failed, otherwise
      // the page would be stuck showing a spinner forever.
      expect(ctrl.isLoading, false);
      expect(ctrl.conversations, isEmpty);
    });
  });
}
