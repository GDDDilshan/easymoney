import 'package:flutter/material.dart';
import '../services/secure_storage_service.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  final SecureStorageService _secureStorage = SecureStorageService();

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  ThemeProvider() {
    _loadThemeMode();
  }

  /// 🔒 ENCRYPTED: Load theme preference from secure storage
  Future<void> _loadThemeMode() async {
    try {
      final isDark = await _secureStorage.readBool(key: StorageKeys.theme);
      if (isDark != null) {
        _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
        notifyListeners();
        debugPrint('✅ Theme loaded (encrypted): ${_themeMode.name}');
      }
    } catch (e) {
      debugPrint('❌ Error loading theme: $e');
    }
  }

  /// 🔒 ENCRYPTED: Save theme preference to secure storage
  Future<void> toggleTheme() async {
    _themeMode =
        _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;

    try {
      await _secureStorage.writeBool(
        key: StorageKeys.theme,
        value: _themeMode == ThemeMode.dark,
      );
      debugPrint('✅ Theme saved (encrypted): ${_themeMode.name}');
    } catch (e) {
      debugPrint('❌ Error saving theme: $e');
    }

    notifyListeners();
  }

  /// 🔒 ENCRYPTED: Set specific theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;

    try {
      await _secureStorage.writeBool(
        key: StorageKeys.theme,
        value: mode == ThemeMode.dark,
      );
      debugPrint('✅ Theme set (encrypted): ${mode.name}');
    } catch (e) {
      debugPrint('❌ Error setting theme: $e');
    }

    notifyListeners();
  }
}
