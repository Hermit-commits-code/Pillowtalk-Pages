// lib/config/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// The Pillowtalk Pages Palette: Deep, Luxurious, and Warm
const Color primaryRose = Color(0xFF8B0000); // Deep Rose/Maroon
const Color secondaryGold = Color(0xFFFFD700); // Gold Accent
const Color backgroundMidnight = Color(0xFF0F0F0F); // Near-Black
const Color cardDark = Color(0xFF1A1A1A); // Card Background
const Color textSoftWhite = Color(0xFFF5F5F5); // Readable Text

final ThemeData pillowtalkTheme = ThemeData(
  primaryColor: primaryRose,
  scaffoldBackgroundColor: backgroundMidnight,
  brightness: Brightness.dark,

  // Elegant Typography
  textTheme: GoogleFonts.cormorantGaramondTextTheme(
    ThemeData.dark().textTheme,
  ).apply(bodyColor: textSoftWhite, displayColor: textSoftWhite),

  colorScheme: const ColorScheme.dark(
    primary: primaryRose,
    secondary: secondaryGold,
    surface: backgroundMidnight,
    onSurface: textSoftWhite,
  ),

  appBarTheme: AppBarTheme(
    backgroundColor: backgroundMidnight,
    elevation: 0,
    titleTextStyle: GoogleFonts.cormorantGaramond(
      color: textSoftWhite,
      fontSize: 24,
      fontWeight: FontWeight.bold,
    ),
  ),

  cardTheme: CardThemeData(
    color: cardDark,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
    elevation: 4.0,
  ),

  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: primaryRose,
      foregroundColor: textSoftWhite,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
    ),
  ),

  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: cardDark,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8.0),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8.0),
      borderSide: const BorderSide(color: primaryRose),
    ),
  ),
);
