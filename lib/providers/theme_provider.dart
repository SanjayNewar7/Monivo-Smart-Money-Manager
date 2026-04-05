import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/storage_service.dart';

class ThemeProvider extends ChangeNotifier {
  AppTheme _currentTheme = AppTheme.blue; // Default fallback

  AppTheme get currentTheme => _currentTheme;

  Color get primaryColor {
    switch (_currentTheme) {
      case AppTheme.blue:
        return const Color(0xFF007AFF);
      case AppTheme.green:
        return const Color(0xFF34C759);
      case AppTheme.purple:
        return const Color(0xFFAF52DE);
      case AppTheme.dark:
        return const Color(0xFF1C1C1E);
    }
  }

  // Load theme from saved user preferences
  Future<void> loadTheme() async {
    try {
      final user = await StorageService.getUser();
      if (user != null) {
        _currentTheme = user.theme;
        notifyListeners();
      }
    } catch (e) {
      print('Error loading theme: $e');
      // Keep default theme if error
    }
  }

  void setTheme(AppTheme theme) {
    _currentTheme = theme;
    notifyListeners();
  }
}