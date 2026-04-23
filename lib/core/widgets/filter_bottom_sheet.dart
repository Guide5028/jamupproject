import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

void showFilterBottomSheet({
  required BuildContext context,
  required String title,
  required List<String> options,
  required Set<String> selectedSet,
  required VoidCallback refresh,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF121212),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),

              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              ...options.map((o) {
                final selected = selectedSet.contains(o);

                return ListTile(
                  title: Text(
                    o,
                    style: TextStyle(
                      color: selected ? AppColors.primaryGold : Colors.white,
                      fontWeight:
                          selected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  trailing: selected
                      ? const Icon(Icons.check, color: AppColors.primaryGold)
                      : null,
                  onTap: () {
                    setModalState(() {
                      if (selected) {
                        selectedSet.remove(o);
                      } else {
                        selectedSet.add(o);
                      }
                    });

                    refresh();
                  },
                );
              }),

              const SizedBox(height: 20),
            ],
          );
        },
      );
    },
  );
}