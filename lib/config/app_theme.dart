import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_fonts.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primaryGold,
      textTheme: AppFonts.textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        titleTextStyle: AppFonts.appBarTitle,
        iconTheme: const IconThemeData(color: AppColors.darkBrown),
      ),
      colorScheme: ColorScheme.fromSwatch().copyWith(
        secondary: AppColors.secondaryGold,
      ),
    );
  }
}
