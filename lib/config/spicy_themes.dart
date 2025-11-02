import 'package:flutter/material.dart';

// Velvet Romance (Default)
const Color velvetPlum = Color(0xFF6B3465); // Lightened from 0xFF4B2245
const Color velvetBlush = Color(0xFFF6E7E7);
const Color velvetGold = Color(0xFFC9B037);
const Color velvetMidnight = Color(0xFF232946);
const Color velvetCream = Color(0xFFFFF8E1);

final ThemeData velvetRomanceTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: velvetMidnight,
  primaryColor: velvetPlum,
  colorScheme: ColorScheme.dark(
    primary: velvetPlum,
    secondary: velvetGold,
    surface: velvetMidnight,
    surfaceTint: velvetCream,
    onPrimary: velvetBlush,
    onSecondary: velvetMidnight,
    onSurface: velvetCream,
  ),
  cardColor: velvetCream,
  appBarTheme: AppBarTheme(
    backgroundColor: velvetPlum,
    foregroundColor: velvetBlush,
    elevation: 0,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: velvetGold,
      foregroundColor: velvetPlum,
      textStyle: const TextStyle(fontWeight: FontWeight.bold),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  ),
  textTheme: const TextTheme(
    headlineLarge: TextStyle(
      color: velvetCream,
      fontFamily: 'Cinzel',
      fontWeight: FontWeight.bold,
    ),
    headlineMedium: TextStyle(color: velvetBlush, fontFamily: 'Cinzel'),
    bodyLarge: TextStyle(color: velvetCream),
    bodyMedium: TextStyle(color: velvetBlush),
    labelLarge: TextStyle(color: velvetGold),
  ),
);

// Enchanted Night (Pro theme)
const Color enchantedTeal = Color(0xFF22333B);
const Color enchantedRose = Color(0xFFF2D0A4);
const Color enchantedAmethyst = Color(0xFF6C3483);
const Color enchantedTaupe = Color(0xFFA9927D);
const Color enchantedWhite = Color(0xFFF9F6F2);

final ThemeData enchantedNightTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: enchantedTeal,
  primaryColor: enchantedAmethyst,
  colorScheme: ColorScheme.dark(
    primary: enchantedAmethyst,
    secondary: enchantedRose,
    surface: enchantedTeal,
    surfaceTint: enchantedTaupe,
    onPrimary: enchantedWhite,
    onSecondary: enchantedTeal,
    onSurface: enchantedWhite,
  ),
  cardColor: enchantedTaupe,
  appBarTheme: AppBarTheme(
    backgroundColor: enchantedAmethyst,
    foregroundColor: enchantedWhite,
    elevation: 0,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: enchantedRose,
      foregroundColor: enchantedAmethyst,
      textStyle: const TextStyle(fontWeight: FontWeight.bold),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  ),
  textTheme: const TextTheme(
    headlineLarge: TextStyle(
      color: enchantedWhite,
      fontFamily: 'Cinzel',
      fontWeight: FontWeight.bold,
    ),
    headlineMedium: TextStyle(color: enchantedRose, fontFamily: 'Cinzel'),
    bodyLarge: TextStyle(color: enchantedWhite),
    bodyMedium: TextStyle(color: enchantedRose),
    labelLarge: TextStyle(color: enchantedAmethyst),
  ),
);

// Luxe Boudoir (Pro theme)
const Color boudoirBurgundy = Color(0xFF6E2142);
const Color boudoirChampagne = Color(0xFFF7E7CE);
const Color boudoirLavender = Color(0xFFA398C2);
const Color boudoirCharcoal = Color(0xFF2D2D34);
const Color boudoirRose = Color(0xFFF5D5E0);

final ThemeData luxeBoudoirTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: boudoirCharcoal,
  primaryColor: boudoirBurgundy,
  colorScheme: ColorScheme.dark(
    primary: boudoirBurgundy,
    secondary: boudoirLavender,
    surface: boudoirCharcoal,
    surfaceTint: boudoirRose,
    onPrimary: boudoirChampagne,
    onSecondary: boudoirCharcoal,
    onSurface: boudoirChampagne,
  ),
  cardColor: boudoirRose,
  appBarTheme: AppBarTheme(
    backgroundColor: boudoirBurgundy,
    foregroundColor: boudoirChampagne,
    elevation: 0,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: boudoirLavender,
      foregroundColor: boudoirBurgundy,
      textStyle: const TextStyle(fontWeight: FontWeight.bold),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  ),
  textTheme: const TextTheme(
    headlineLarge: TextStyle(
      color: boudoirChampagne,
      fontFamily: 'Cinzel',
      fontWeight: FontWeight.bold,
    ),
    headlineMedium: TextStyle(color: boudoirRose, fontFamily: 'Cinzel'),
    bodyLarge: TextStyle(color: boudoirChampagne),
    bodyMedium: TextStyle(color: boudoirRose),
    labelLarge: TextStyle(color: boudoirLavender),
  ),
);
