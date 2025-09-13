import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppFonts {
  // AppBar title style
  static final appBarTitle = GoogleFonts.roboto(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.darkBrown,
  );

  // Main TextTheme
  static final textTheme = TextTheme(
    bodyLarge: GoogleFonts.inter(fontSize: 14, color: AppColors.darkBrown),
    bodyMedium: GoogleFonts.inter(fontSize: 12, color: AppColors.accentBrown),
    headlineLarge: GoogleFonts.interTight(
        fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.darkBrown),
    headlineMedium: GoogleFonts.roboto(
        fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.darkBrown),
  );
}
