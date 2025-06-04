import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  final String key = "theme";
  late SharedPreferences _prefs;
  late bool _isDarkMode;

  bool get isDarkMode => _isDarkMode;

  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  ThemeProvider() {
    _isDarkMode = false;
    _loadFromPrefs();
  }

  void _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
  }

  void _loadFromPrefs() async {
    _initPrefs();
    _prefs = await SharedPreferences.getInstance();
    _isDarkMode = _prefs.getBool(key) ?? false;
    notifyListeners();
  }

  void _saveToPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    _prefs.setBool(key, _isDarkMode);
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    _saveToPrefs();
    notifyListeners();
  }
}
