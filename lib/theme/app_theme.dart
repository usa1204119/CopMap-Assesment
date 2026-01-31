import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color background = Color(0xFF1E293B); // Dark Slate
  static const Color card = Color(0xFF334155);
  static const Color primary = Color(0xFF6366F1); // Indigo
  static const Color secondary = Color(0xFF475569);
  
  static const Color statusActive = Color(0xFF22C55E); // Green
  static const Color statusWarning = Color(0xFFEAB308); // Yellow
  static const Color statusOffline = Color(0xFFEF4444); // Red

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: background,
    primaryColor: primary,
    colorScheme: const ColorScheme.dark(
      primary: primary,
      secondary: secondary,
      surface: card,
      error: statusOffline,
      // background is deprecated, surface covers it in M3
    ),
    /* cardTheme: CardTheme(
      color: card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFF475569), width: 1),
      ),
    ), */
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).apply(
      bodyColor: Colors.white,
      displayColor: Colors.white,
    ),
    iconTheme: const IconThemeData(color: Colors.white70),
  );
}
