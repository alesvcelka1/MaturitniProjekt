import 'package:flutter/material.dart';

/// Utility funkce pro práci s motivy aplikace
class ThemeUtils {
  ThemeUtils._();

  /// Vrací barvu pozadí podle aktuálního motivu
  static Color getBackgroundColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1E1E1E)
        : const Color(0xFFF8F9FA);
  }

  /// Vrací barvu pro input pole podle motivu
  static Color getInputFillColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF2C2C2C)
        : Colors.white;
  }

  /// Vrací barvu pro karty podle motivu
  static Color getCardColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1E1E1E)
        : Colors.white;
  }

  /// Vrací barvu pro sekundární pozadí (např. search bar)
  static Color getSecondaryBackgroundColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.grey[850]!
        : const Color(0xFFF8F9FA);
  }

  /// Vrací barvu textu podle motivu
  static Color getTextColor(BuildContext context, {bool secondary = false}) {
    if (Theme.of(context).brightness == Brightness.dark) {
      return secondary ? Colors.white70 : Colors.white;
    }
    return secondary ? Colors.black54 : Colors.black87;
  }

  /// Vrací barvu pro hint text
  static Color getHintColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF6B7280)
        : const Color(0xFF9CA3AF);
  }

  /// Zjistí, zda je aktivní tmavý režim
  static bool isDarkMode(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  /// Vrací opačnou barvu pro kontrast
  static Color getContrastColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Colors.black;
  }
}
