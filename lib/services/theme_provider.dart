import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;

  ThemeProvider() {
    _loadTheme();
  }

  ThemeMode get themeMode => _themeMode;

  void setTheme(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('themeMode', mode.toString());
  }

  void _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final mode = prefs.getString('themeMode');
    if (mode == 'ThemeMode.light') {
      _themeMode = ThemeMode.light;
    } else if (mode == 'ThemeMode.dark') {
      _themeMode = ThemeMode.dark;
    } else if (mode == 'ThemeMode.system') {
      _themeMode = ThemeMode.system;
    }
    notifyListeners();
  }
}
