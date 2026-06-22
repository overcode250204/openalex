import 'package:intl/intl.dart';

class Formatters {
  static String truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  static String formatCitation(int value) {
    return NumberFormat.decimalPattern().format(value);
  }

  static String formatNumber(int value) {
    return value.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );
  }

  static String formatCompactAxis(int value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(value % 1000000 == 0 ? 0 : 1)}M';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(value % 1000 == 0 ? 0 : 1)}K';
    }
    return value.toString();
  }

  /// Returns a human-readable compact number (e.g. 42.7M, 128.5K)
  static String formatCompactNumber(int value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toString();
  }

  /// Caps extreme growth rates so they never show absurd %.
  /// Returns strings like "+287.4%", ">500%", "Newly emerging"
  static String formatGrowthRate(double growthRate, {int? previousCount}) {
    // If the baseline is tiny (< 50), the % is statistically meaningless
    if (previousCount != null && previousCount < 50) {
      return 'Newly emerging';
    }
    if (growthRate > 500) return '>500%';
    if (growthRate < -100) return '-100%';
    final sign = growthRate >= 0 ? '+' : '';
    return '$sign${growthRate.toStringAsFixed(1)}%';
  }
}
