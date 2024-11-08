import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:SoundScape/app_logger.dart';

final _logger = AppLogger();

class ThemeService {
  /// Loads the theme mode from shared preferences.
  Future<ThemeMode> loadThemeMode() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? theme = prefs.getString('themeMode');
      return theme == 'dark'
          ? ThemeMode.dark
          : theme == 'light'
              ? ThemeMode.light
              : ThemeMode.system;
    } catch (e) {
      _logger.error('Error loading theme mode: $e');
      return ThemeMode.system; // Default to system theme if there's an error
    }
  }

  /// Saves the theme mode to shared preferences.
  Future<void> saveThemeMode(ThemeMode themeMode) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setString(
          'themeMode',
          themeMode == ThemeMode.dark
              ? 'dark'
              : themeMode == ThemeMode.light
                  ? 'light'
                  : 'system');
    } catch (e) {
      _logger.error('Error saving theme mode: $e');
    }
  }
}
