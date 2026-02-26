import 'package:flutter/material.dart';
import 'package:jamup_app/features/messages/data/messages_repository.dart';

class MessagesController {
  final MessagesRepository repository;

  List<Map<String, dynamic>> conversations = [];
  bool isLoading = false;

  MessagesController(this.repository);

  Future<void> load(VoidCallback onUpdate) async {
    isLoading = true;
    onUpdate();

    conversations = await repository.fetchConversations();

    isLoading = false;
    onUpdate();
  }
}