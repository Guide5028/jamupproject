import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppFonts {
  // AppBar title style
  static final appBarTitle = GoogleFonts.roboto(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: const Color(0xFF2C1810),
  );

  // Main text theme
  static final textTheme = TextTheme(
    bodyLarge: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF2C1810)),
    bodyMedium: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF8B7355)),
    headlineLarge: GoogleFonts.interTight(
        fontSize: 28, fontWeight: FontWeight.bold, color: const Color(0xFF2C1810)),
    headlineMedium: GoogleFonts.roboto(
        fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF2C1810)),
  );
}
