import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service pro správu motivů aplikace s podporou systémového nastavení
class ThemeService extends ChangeNotifier {
  static const String _themeModeKey = 'theme_mode';
  
  // ThemeMode může být: system, light, dark
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;
  
  bool get isDarkMode {
    // Pro UI zobrazení - když je system, vrátíme false (default)
    return _themeMode == ThemeMode.dark;
  }
  
  bool get isLightMode => _themeMode == ThemeMode.light;
  bool get isSystemMode => _themeMode == ThemeMode.system;

  ThemeService() {
    _loadThemeMode();
  }

  /// Načte uložený ThemeMode z SharedPreferences
  Future<void> _loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedMode = prefs.getString(_themeModeKey);
      
      if (savedMode != null) {
        _themeMode = switch (savedMode) {
          'light' => ThemeMode.light,
          'dark' => ThemeMode.dark,
          _ => ThemeMode.system,
        };
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Chyba při načítání theme mode: $e');
    }
  }

  /// Uloží ThemeMode do SharedPreferences
  Future<void> _saveThemeMode(ThemeMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final modeString = switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      };
      
      await prefs.setString(_themeModeKey, modeString);
    } catch (e) {
      debugPrint('Chyba při ukládání theme mode: $e');
    }
  }

  /// Přepne mezi světlým a tmavým režimem (nepoužívá system)
  Future<void> toggleTheme() async {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    await _saveThemeMode(_themeMode);
    notifyListeners();
  }

  /// Nastaví konkrétní ThemeMode
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _saveThemeMode(mode);
    notifyListeners();
  }

  /// Nastaví světlý režim
  Future<void> setLightMode() => setThemeMode(ThemeMode.light);
  
  /// Nastaví tmavý režim
  Future<void> setDarkMode() => setThemeMode(ThemeMode.dark);
  
  /// Nastaví systémový režim
  Future<void> setSystemMode() => setThemeMode(ThemeMode.system);
}
