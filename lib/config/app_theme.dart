// lib/config/app_theme.dart
import 'package:flutter/material.dart';

import 'spicy_themes.dart';

// Default theme: Velvet Romance
final ThemeData spicyDarkTheme = velvetRomanceTheme;

// Light theme fallback (can be customized or replaced)
final ThemeData spicyLightTheme = ThemeData.light();

// Pro themes (for theme selector)
final ThemeData proThemeEnchantedNight = enchantedNightTheme;
final ThemeData proThemeLuxeBoudoir = luxeBoudoirTheme;

// TODO: Add theme switching logic and Pro gating for extra themes
// Example usage: Theme.of(context) or pass selected theme to MaterialApp
