import 'package:flutter/material.dart';
import 'package:jamup_app/features/messages/data/messages_repository.dart';

class MessagesController {
  final MessagesRepository repository;

  List<Map<String, dynamic>> conversations = [];
  bool isLoading = false;
  String? error;

  MessagesController(this.repository);

  Future<void> load(VoidCallback onUpdate) async {
    isLoading = true;
    error = null;
    onUpdate();

    try {
      conversations = await repository.fetchConversations();
    } catch (e) {
      // loading must still clear on failure, or the caller is stuck
      // showing a spinner forever with no way to retry (matches the
      // pattern used by BookingController.loadBookingsFor*).
      error = e.toString();
    }

    isLoading = false;
    onUpdate();
  }
}