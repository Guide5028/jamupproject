import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_fonts.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,

      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primaryGold,

      // Smooth, consistent screen transitions everywhere (every Navigator.push
      // gets a gentle fade + upward slide automatically — no per-call work).
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          // FadeUpwards (a built-in material transition) on both platforms for
          // a consistent gentle fade + rise. CupertinoPageTransitionsBuilder
          // lives in flutter/cupertino.dart, not material — using a material
          // builder here avoids an extra import.
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: FadeUpwardsPageTransitionsBuilder(),
        },
      ),

      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryGold,
        secondary: AppColors.secondaryGold,
        background: AppColors.background,
        error: AppColors.error,
      ),

      textTheme: AppFonts.textTheme,

      // APP BAR
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.darkBrown),
      ),

      // CARDS
      cardTheme: CardThemeData(
        color: AppColors.cardBackground,
        elevation: 4,
        shadowColor: AppColors.shadowColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),

      // INPUT (SEARCH BAR)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cardBackground,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: Colors.grey.shade300,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: AppColors.primaryGold,
            width: 1.5,
          ),
        ),
      ),

      // BUTTON
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGold,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 14,
          ),
        ),
      ),

      // BOTTOM NAV
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primaryGold,
        unselectedItemColor: AppColors.accentBrown,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }
}
