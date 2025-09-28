// lib/theme/theme_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const _key = 'theme_mode'; // 'light' | 'dark' | 'system'
  ThemeMode _mode = ThemeMode.system;

  ThemeMode get mode => _mode;
  bool get isDark => _mode == ThemeMode.dark;

  ThemeProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_key) ?? 'system';
    _mode = _parse(value);
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, _stringify(_mode));
  }

  // Toggle strictly between light and dark (no system)
  Future<void> toggle() async {
    _mode = _mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await _save();
    notifyListeners();
  }

  // Optional: choose explicit mode, e.g., from a settings menu
  Future<void> setMode(ThemeMode mode) async {
    _mode = mode;
    await _save();
    notifyListeners();
  }

  String _stringify(ThemeMode m) =>
      m == ThemeMode.dark ? 'dark' : m == ThemeMode.light ? 'light' : 'system';
  ThemeMode _parse(String s) =>
      s == 'dark' ? ThemeMode.dark : s == 'light' ? ThemeMode.light : ThemeMode.system;
}
