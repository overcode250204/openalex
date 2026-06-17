import 'package:intl/intl.dart';

class Formatters {
  static String truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  static String formatCitation(int value) {
    return NumberFormat.decimalPattern().format(value);
  }

  static String formatCompactAxis(int value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(value % 1000 == 0 ? 0 : 1)}K';
    }
    return value.toString();
  }
}
