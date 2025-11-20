import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

/// Utility funkce pro práci s datumy a Firestore timestampy
class DateTimeUtils {
  DateTimeUtils._();

  /// Převede Firestore Timestamp na DateTime
  static DateTime? timestampToDateTime(dynamic timestamp) {
    if (timestamp == null) return null;
    if (timestamp is Timestamp) return timestamp.toDate();
    if (timestamp is DateTime) return timestamp;
    return null;
  }

  /// Formátuje DateTime do českého formátu (dd.MM.yyyy)
  static String formatDate(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('dd.MM.yyyy').format(date);
  }

  /// Formátuje DateTime do českého formátu s časem (dd.MM.yyyy HH:mm)
  static String formatDateTime(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('dd.MM.yyyy HH:mm').format(date);
  }

  /// Formátuje čas (HH:mm)
  static String formatTime(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('HH:mm').format(date);
  }

  /// Vrací relativní čas (např. "před 2 hodinami")
  static String getRelativeTime(DateTime? date) {
    if (date == null) return '-';

    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return formatDate(date);
    } else if (difference.inDays > 0) {
      return 'před ${difference.inDays} ${_dayPlural(difference.inDays)}';
    } else if (difference.inHours > 0) {
      return 'před ${difference.inHours} ${_hourPlural(difference.inHours)}';
    } else if (difference.inMinutes > 0) {
      return 'před ${difference.inMinutes} ${_minutePlural(difference.inMinutes)}';
    } else {
      return 'právě teď';
    }
  }

  /// Převede sekundy na formát MM:SS
  static String formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  /// Převede sekundy na formát HH:MM:SS
  static String formatDurationLong(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainingSeconds = seconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m ${remainingSeconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${remainingSeconds}s';
    } else {
      return '${remainingSeconds}s';
    }
  }

  /// Vrátí datum YYYY-MM-DD pro Firestore ukládání
  static String getDateString(DateTime date) {
    return date.toIso8601String().split('T')[0];
  }

  /// Vrací začátek dne (00:00:00)
  static DateTime getStartOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Vrací konec dne (23:59:59)
  static DateTime getEndOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
  }

  /// Vrací začátek týdne (pondělí)
  static DateTime getStartOfWeek(DateTime date) {
    final weekday = date.weekday;
    return getStartOfDay(date.subtract(Duration(days: weekday - 1)));
  }

  /// Vrací konec týdne (neděle)
  static DateTime getEndOfWeek(DateTime date) {
    final weekday = date.weekday;
    return getEndOfDay(date.add(Duration(days: 7 - weekday)));
  }

  // Helper metody pro český plurál
  static String _dayPlural(int count) {
    if (count == 1) return 'den';
    if (count < 5) return 'dny';
    return 'dní';
  }

  static String _hourPlural(int count) {
    if (count == 1) return 'hodinou';
    if (count < 5) return 'hodinami';
    return 'hodinami';
  }

  static String _minutePlural(int count) {
    if (count == 1) return 'minutou';
    if (count < 5) return 'minutami';
    return 'minutami';
  }
}
