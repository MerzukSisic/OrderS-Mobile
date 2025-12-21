import 'package:intl/intl.dart';

class Formatters {
  // Currency formatter
  static String currency(double amount, {String symbol = 'KM'}) {
    return '';
  }

  // Date formatter
  static String date(DateTime dateTime, {String format = 'dd.MM.yyyy'}) {
    return DateFormat(format).format(dateTime);
  }

  // Time formatter
  static String time(DateTime dateTime, {String format = 'HH:mm'}) {
    return DateFormat(format).format(dateTime);
  }

  // DateTime formatter
  static String dateTime(DateTime dateTime,
      {String format = 'dd.MM.yyyy HH:mm'}) {
    return DateFormat(format).format(dateTime);
  }

  // Relative time (e.g., 2 hours ago)
  static String relativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return 'd ago';
    } else if (difference.inHours > 0) {
      return 'h ago';
    } else if (difference.inMinutes > 0) {
      return 'm ago';
    } else {
      return 'Just now';
    }
  }

  // Phone number formatter
  static String phoneNumber(String phone) {
    if (phone.length <= 3) return phone;
    final cleaned = phone.replaceAll(RegExp(r'[^d]'), '');
    if (cleaned.length <= 3) return cleaned;
    if (cleaned.length <= 6) {
      return '-';
    }
    return '--';
  }

  // Capitalize first letter
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  // Truncate text
  static String truncate(String text, int length, {String suffix = '...'}) {
    if (text.length <= length) return text;
    return text.substring(0, length) + suffix;
  }
}
