import 'dart:io';

import '../models/publication.dart';
import '../models/trend_report_snapshot.dart';

class TrendReportExportResult {
  final File file;
  final String markdown;

  const TrendReportExportResult({required this.file, required this.markdown});
}

class TrendReportExportService {

  const TrendReportExportService();

  Future<TrendReportExportResult> exportMarkdownReport(
    TrendReportSnapshot report, {
    DateTime? generatedAt,
  }) async {
    final timestamp = generatedAt ?? DateTime.now();
    final markdown = buildMarkdownReport(report, generatedAt: timestamp);
    final directory = await _resolveExportDirectory();
    final fileName = _buildFileName(report.topic, timestamp);
    final file = File('${directory.path}${Platform.pathSeparator}$fileName');

    await file.writeAsString(markdown);

    return TrendReportExportResult(file: file, markdown: markdown);
  }

  String buildMarkdownReport(
    TrendReportSnapshot report, {
    DateTime? generatedAt,
  }) {
    final buffer = StringBuffer();
    final timestamp = generatedAt ?? DateTime.now();
    final mostInfluentialPaper = report.mostInfluentialPaper;

    buffer.writeln('# Journal Trend Analyzer Report');
    buffer.writeln();
    buffer.writeln('- Topic: ${_markdownValue(report.topic)}');
    buffer.writeln('- Generated at: ${_formatDateTime(timestamp)}');
    buffer.writeln('- Total publications: ${report.totalPublications}');
    buffer.writeln(
      '- Average citation count: '
      '${report.averageCitationCount.toStringAsFixed(2)}',
    );
    buffer.writeln('- Citation median: ${report.citationMedian}');
    buffer.writeln(
      '- Publication growth rate: '
      '${report.publicationGrowthRate >= 0 ? '+' : ''}'
      '${report.publicationGrowthRate.toStringAsFixed(1)}%',
    );
    buffer.writeln(
      '- Most active publication year: ${report.mostActiveYear ?? 'N/A'}',
    );
    buffer.writeln('- Top journal: ${_markdownValue(report.topJournal)}');
    buffer.writeln('- Top author: ${_markdownValue(report.topAuthor)}');
    buffer.writeln(
      '- Most influential paper: '
      '${mostInfluentialPaper == null ? 'N/A' : _publicationTitle(mostInfluentialPaper)}',
    );
    buffer.writeln();

    _writeTrendSection(buffer, report.publicationCountByYear);
    _writePublicationSection(
      buffer,
      title: 'Top Influential Papers',
      publications: report.topInfluentialPapers,
    );
    _writeRankingSection(
      buffer,
      title: 'Top Research Journals',
      entries: report.topJournals.entries,
      unit: 'papers',
    );
    _writeRankingSection(
      buffer,
      title: 'Top Contributing Authors',
      entries: report.topAuthors.entries,
      unit: 'papers',
    );
    _writeInsightSection(buffer, report);

    return buffer.toString();
  }

  static void _writeTrendSection(StringBuffer buffer, Map<int, int> data) {
    buffer.writeln('## Publication Trend By Year');
    buffer.writeln();

    if (data.isEmpty) {
      buffer.writeln('No publication trend data is available.');
      buffer.writeln();
      return;
    }

    buffer.writeln('| Year | Publications |');
    buffer.writeln('| --- | ---: |');
    for (final entry in data.entries) {
      buffer.writeln('| ${entry.key} | ${entry.value} |');
    }
    buffer.writeln();
  }

  static void _writePublicationSection(
    StringBuffer buffer, {
    required String title,
    required List<Publication> publications,
  }) {
    buffer.writeln('## $title');
    buffer.writeln();

    if (publications.isEmpty) {
      buffer.writeln('No publications are available.');
      buffer.writeln();
      return;
    }

    buffer.writeln('| Rank | Title | Year | Journal | Citations |');
    buffer.writeln('| ---: | --- | ---: | --- | ---: |');
    for (var index = 0; index < publications.length; index++) {
      final publication = publications[index];
      buffer.writeln(
        '| ${index + 1} | '
        '${_escapeTableValue(_publicationTitle(publication))} | '
        '${publication.displayYear} | '
        '${_escapeTableValue(publication.displayJournal)} | '
        '${publication.citedByCount} |',
      );
    }
    buffer.writeln();
  }

  static void _writeRankingSection(
    StringBuffer buffer, {
    required String title,
    required Iterable<MapEntry<String, int>> entries,
    required String unit,
  }) {
    final ranking = entries.toList();
    buffer.writeln('## $title');
    buffer.writeln();

    if (ranking.isEmpty) {
      buffer.writeln('No ranking data is available.');
      buffer.writeln();
      return;
    }

    buffer.writeln('| Rank | Name | Count |');
    buffer.writeln('| ---: | --- | ---: |');
    for (var index = 0; index < ranking.length; index++) {
      final entry = ranking[index];
      buffer.writeln(
        '| ${index + 1} | ${_escapeTableValue(entry.key)} | '
        '${entry.value} $unit |',
      );
    }
    buffer.writeln();
  }

  static void _writeInsightSection(
    StringBuffer buffer,
    TrendReportSnapshot report,
  ) {
    buffer.writeln('## Insight Summary');
    buffer.writeln();

    if (report.publications.isEmpty) {
      buffer.writeln('No insights can be generated without publications.');
      return;
    }

    final trendDirection = _trendDirection(report.publicationCountByYear);

    buffer.writeln(
      '- The topic contains ${report.totalPublications} publications in the '
      'retrieved OpenAlex result set.',
    );
    buffer.writeln(
      '- The average citation count is '
      '${report.averageCitationCount.toStringAsFixed(2)}, '
      'with a median of ${report.citationMedian}.',
    );
    buffer.writeln(
      '- The most active publication year is '
      '${report.mostActiveYear ?? 'N/A'}.',
    );
    buffer.writeln('- The publication trend is $trendDirection.');
    buffer.writeln(
      '- Publication growth rate from first to last year: '
      '${report.publicationGrowthRate >= 0 ? '+' : ''}'
      '${report.publicationGrowthRate.toStringAsFixed(1)}%.',
    );

    final mostInfluentialPaper = report.mostInfluentialPaper;
    if (mostInfluentialPaper != null) {
      buffer.writeln(
        '- The most influential paper is '
        '"${_escapeInlineValue(_publicationTitle(mostInfluentialPaper))}" with '
        '${mostInfluentialPaper.citedByCount} citations.',
      );
    }
  }

  static Future<Directory> _resolveExportDirectory() async {
    String dirPath;

    if (Platform.isWindows) {
      dirPath = '${Platform.environment['USERPROFILE'] ?? r'C:\Users\Public'}\\Downloads';
    } else {
      dirPath = '${Platform.environment['HOME'] ?? '/tmp'}/Downloads';
    }

    final directory = Directory(dirPath);
    return directory.create(recursive: true);
  }

  static String _trendDirection(Map<int, int> data) {
    if (data.length < 2) {
      return 'not enough data to determine a clear direction';
    }

    final first = data.entries.first.value;
    final last = data.entries.last.value;

    if (last > first) {
      return 'increasing across the selected years';
    }

    if (last < first) {
      return 'decreasing across the selected years';
    }

    return 'stable across the selected years';
  }

  static String _buildFileName(String topic, DateTime generatedAt) {
    final timestamp = _compactTimestamp(generatedAt);
    final safeTopic = topic
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');

    return 'trend-report-${safeTopic.isEmpty ? 'topic' : safeTopic}-$timestamp.md';
  }

  static String _compactTimestamp(DateTime value) {
    String twoDigits(int number) => number.toString().padLeft(2, '0');

    return '${value.year}'
        '${twoDigits(value.month)}'
        '${twoDigits(value.day)}-'
        '${twoDigits(value.hour)}'
        '${twoDigits(value.minute)}'
        '${twoDigits(value.second)}';
  }

  static String _formatDateTime(DateTime value) {
    String twoDigits(int number) => number.toString().padLeft(2, '0');

    return '${value.year}-${twoDigits(value.month)}-${twoDigits(value.day)} '
        '${twoDigits(value.hour)}:${twoDigits(value.minute)}:'
        '${twoDigits(value.second)}';
  }

  static String _markdownValue(String? value) {
    final normalized = _normalizeText(value).trim();

    if (normalized.isEmpty) {
      return 'N/A';
    }

    return _escapeInlineValue(normalized);
  }

  static String _escapeInlineValue(String value) {
    return _normalizeText(
      value,
    ).replaceAll('\n', ' ').replaceAll('\r', ' ').trim();
  }

  static String _escapeTableValue(String value) {
    return _escapeInlineValue(value).replaceAll('|', r'\|');
  }

  static String _publicationTitle(Publication publication) {
    final title = _normalizeText(publication.title).trim();

    if (title.isEmpty) {
      return 'Untitled publication';
    }

    return title;
  }

  static String _normalizeText(String? value) {
    return (value ?? '')
        .replaceAll('\u00E2\u20AC\u201C', '-')
        .replaceAll('\u00E2\u20AC\u201D', '-')
        .replaceAll('\u00E2\u20AC\u00A2', '-')
        .replaceAll('\u00E2\u20AC\u2122', "'")
        .replaceAll('\u00E2\u20AC\u02DC', "'")
        .replaceAll('\u00E2\u20AC\u0153', '"')
        .replaceAll('\u00E2\u20AC\u009D', '"')
        .replaceAll('\u00C2', '');
  }
}
