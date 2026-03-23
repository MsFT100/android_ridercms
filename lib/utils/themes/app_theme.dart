import 'package:flutter/material.dart';

// Ridercms Color Palette
const Color kPrimary = Color(0xFF00C896);
const Color kPrimaryDark = Color(0xFF00A87A);
const Color kAccent = Color(0xFF3B82F6);
const Color kWarning = Color(0xFFF59E0B);
const Color kDanger = Color(0xFFEF4444);
const Color kBgDark = Color(0xFF0A0F1E);
const Color kBgDark2 = Color(0xFF0D1B2A);
const Color kBgCard = Color(0xFF111827);
const Color kBgCard2 = Color(0xFF1F2937);
const Color kTextPrimary = Color(0xFFFFFFFF);
const Color kTextSecondary = Color(0xFF9CA3AF);

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: kBgDark,
    colorScheme: const ColorScheme.dark(
      primary: kPrimary,
      secondary: kAccent,
      surface: kBgCard,
      error: kDanger,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: kTextPrimary),
      bodyMedium: TextStyle(color: kTextPrimary),
      bodySmall: TextStyle(color: kTextSecondary),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: kBgDark2,
      foregroundColor: kTextPrimary,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: kBgCard,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0x1AFFFFFF)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0x1AFFFFFF)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: kPrimary, width: 1.5),
      ),
      hintStyle: const TextStyle(color: kTextSecondary),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
  );
}