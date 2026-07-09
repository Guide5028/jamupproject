import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_fonts.dart';

/// EmptyState
/// ----------
/// One consistent, friendly "nothing here yet" view used across the app
/// (favorites, applications, search results, schedule…). A soft circular icon
/// + a clear title + a helpful next-step line reads far more polished than bare
/// grey text, and keeps every empty screen feeling like the same product.
///
/// It builds its own scrollable so it still works inside a RefreshIndicator
/// (pull-to-refresh) without throwing.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primaryGold.withOpacity(0.12),
                      ),
                      child: Icon(icon, size: 44, color: AppColors.primaryGold),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: AppFonts.textTheme.headlineMedium?.copyWith(
                        color: AppColors.darkBrown,
                      ),
                    ),
                    if (message != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        message!,
                        textAlign: TextAlign.center,
                        style: AppFonts.textTheme.bodyMedium?.copyWith(
                          color: AppColors.accentBrown,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
