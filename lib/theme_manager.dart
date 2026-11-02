import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeManager extends ChangeNotifier {
  ThemeManager._();

  static final ThemeManager instance = ThemeManager._();

  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  Future<void> loadTheme() async {
    final preferences = await SharedPreferences.getInstance();
    final savedTheme = preferences.getString('theme_mode');

    switch (savedTheme) {
      case 'dark':
        _themeMode = ThemeMode.dark;
        break;
      case 'system':
        _themeMode = ThemeMode.system;
        break;
      default:
        _themeMode = ThemeMode.light;
    }

    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;

    final preferences = await SharedPreferences.getInstance();
    final value = switch (mode) {
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
      ThemeMode.light => 'light',
    };

    await preferences.setString('theme_mode', value);
    notifyListeners();
  }
}