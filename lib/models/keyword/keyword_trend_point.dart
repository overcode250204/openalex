class KeywordTrendPoint {
  final int year;
  final int count;

  const KeywordTrendPoint({required this.year, required this.count});

  factory KeywordTrendPoint.fromJson(Map<String, dynamic> json) {
    final year =
        _parseYear(json['key']) ?? _parseYear(json['key_display_name']);
    if (year == null) {
      throw const FormatException('Invalid publication year');
    }

    return KeywordTrendPoint(year: year, count: json['count'] as int? ?? 0);
  }

  static List<KeywordTrendPoint> parseGroupBy(List<dynamic> items) {
    final points = <KeywordTrendPoint>[];
    final currentYear = DateTime.now().toUtc().year;

    for (final item in items) {
      if (item is! Map<String, dynamic>) continue;

      try {
        final point = KeywordTrendPoint.fromJson(item);
        if (point.year >= 1900 && point.year <= currentYear) {
          points.add(point);
        }
      } on FormatException {
        continue;
      }
    }

    points.sort((a, b) => a.year.compareTo(b.year));
    return points;
  }

  static List<KeywordTrendPoint> latestPoints(
    List<KeywordTrendPoint> points, {
    int limit = 15,
  }) {
    if (points.length <= limit) {
      return List<KeywordTrendPoint>.from(points);
    }

    return points.sublist(points.length - limit);
  }

  static int? _parseYear(Object? value) {
    if (value == null) return null;
    return int.tryParse(value.toString());
  }
}
