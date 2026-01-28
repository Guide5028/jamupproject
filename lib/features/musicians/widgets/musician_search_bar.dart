import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class MusicianSearchBar extends StatelessWidget {
  final ValueChanged<String> onChanged;

  const MusicianSearchBar({
    super.key,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        onChanged: onChanged,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search Artists...',
          hintStyle: TextStyle(
            color: Colors.white.withOpacity(0.6),
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: Colors.white70,
          ),
          filled: true,
          fillColor: const Color(0xFF2B2B2B), // dark bar like reference
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
