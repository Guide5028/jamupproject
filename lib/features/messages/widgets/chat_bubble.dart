import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class ChatBubble extends StatelessWidget {
  final String text;
  final bool fromMe;

  const ChatBubble({super.key, required this.text, required this.fromMe});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: fromMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: fromMe ? AppColors.primaryGold : Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: fromMe ? Colors.white : AppColors.darkBrown,
          ),
        ),
      ),
    );
  }
}
