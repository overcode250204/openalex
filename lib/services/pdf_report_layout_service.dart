import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/publication/publication.dart';
import '../models/trend/trend_report_snapshot.dart';

class PdfReportLayoutResult {
  final Uint8List bytes;
  final String fileName;
  final DateTime generatedAt;

  const PdfReportLayoutResult({
    required this.bytes,
    required this.fileName,
    required this.generatedAt,
  });
}

class PdfReportLayoutService {
  const PdfReportLayoutService();

  Future<PdfReportLayoutResult> buildDashboardReport(
    TrendReportSnapshot report, {
    DateTime? generatedAt,
  }) async {
    final timestamp = generatedAt ?? DateTime.now();
    final fonts = await _loadFonts();
    final document = _buildDocument(
      report,
      generatedAt: timestamp,
      fonts: fonts,
    );
    final bytes = await document.save();

    return PdfReportLayoutResult(
      bytes: bytes,
      fileName: _buildFileName(report.topic, timestamp),
      generatedAt: timestamp,
    );
  }

  pw.Document _buildDocument(
    TrendReportSnapshot report, {
    required DateTime generatedAt,
    required _PdfReportFonts fonts,
  }) {
    final document = pw.Document(
      title: 'Journal Trend Analyzer Report',
      author: 'Journal Trend Analyzer',
      subject: _value(report.topic),
      creator: 'Journal Trend Analyzer',
      compress: false,
    );

    document.addPage(
      pw.MultiPage(
        pageTheme: _pageTheme(fonts),
        header: (context) => _pageHeader(report),
        footer: (context) => _pageFooter(context),
        build: (context) => [
          _heroSection(report, generatedAt),
          pw.SizedBox(height: 18),
          _summaryGrid(report),
          pw.SizedBox(height: 22),
          _sectionTitle('Publication Trend By Year'),
          _trendTable(report.publicationCountByYear),
          pw.SizedBox(height: 18),
          _sectionTitle('Top Influential Papers'),
          _publicationTable(report.topInfluentialPapers),
          pw.SizedBox(height: 18),
          _sectionTitle('Top Research Journals'),
          _rankingTable(report.topJournals.entries, unit: 'papers'),
          pw.SizedBox(height: 18),
          _sectionTitle('Top Contributing Authors'),
          _rankingTable(report.topAuthors.entries, unit: 'papers'),
          pw.SizedBox(height: 18),
          _sectionTitle('Insight Summary'),
          _insightSummary(report),
        ],
      ),
    );

    return document;
  }

  pw.PageTheme _pageTheme(_PdfReportFonts fonts) {
    return pw.PageTheme(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(36, 42, 36, 42),
      theme: _theme(fonts),
    );
  }

  pw.ThemeData _theme(_PdfReportFonts fonts) {
    return pw.ThemeData.withFont(base: fonts.regular, bold: fonts.bold);
  }

  Future<_PdfReportFonts> _loadFonts() async {
    final regularData = await rootBundle.load('assets/fonts/DroidSans.ttf');
    final boldData = await rootBundle.load('assets/fonts/DroidSans-Bold.ttf');

    return _PdfReportFonts(
      regular: pw.Font.ttf(regularData),
      bold: pw.Font.ttf(boldData),
    );
  }

  pw.Widget _pageHeader(TrendReportSnapshot report) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.6),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Text(
            'Journal Trend Analyzer',
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blueGrey800,
            ),
          ),
          pw.Text(
            _value(report.topic),
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  pw.Widget _pageFooter(pw.Context context) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.grey300, width: 0.6),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Generated for academic trend analysis',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
          pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  pw.Widget _heroSection(TrendReportSnapshot report, DateTime generatedAt) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.blueGrey900,
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Journal Trend Analyzer Report',
            style: pw.TextStyle(
              color: PdfColors.white,
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            _value(report.topic),
            style: const pw.TextStyle(
              color: PdfColors.blueGrey100,
              fontSize: 15,
            ),
          ),
          pw.SizedBox(height: 14),
          pw.Text(
            'Generated at ${_formatDateTime(generatedAt)}',
            style: const pw.TextStyle(
              color: PdfColors.blueGrey200,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _summaryGrid(TrendReportSnapshot report) {
    final items = [
      _SummaryItem('Total publications', report.totalPublications.toString()),
      _SummaryItem(
        'Average citations',
        report.averageCitationCount.toStringAsFixed(2),
      ),
      _SummaryItem(
        'Most active year',
        report.mostActiveYear?.toString() ?? 'N/A',
      ),
      _SummaryItem('Top journal', _value(report.topJournal)),
      _SummaryItem('Top author', _value(report.topAuthor)),
      _SummaryItem(
        'Most influential paper',
        report.mostInfluentialPaper == null
            ? 'N/A'
            : _publicationTitle(report.mostInfluentialPaper!),
      ),
    ];

    return pw.Wrap(
      spacing: 10,
      runSpacing: 10,
      children: items.map(_summaryCard).toList(),
    );
  }

  pw.Widget _summaryCard(_SummaryItem item) {
    return pw.Container(
      width: 160,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300, width: 0.7),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            item.label,
            style: pw.TextStyle(
              fontSize: 8,
              color: PdfColors.grey600,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            item.value,
            maxLines: 3,
            overflow: pw.TextOverflow.clip,
            style: pw.TextStyle(
              fontSize: 11,
              color: PdfColors.blueGrey900,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _sectionTitle(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 15,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.blueGrey900,
        ),
      ),
    );
  }

  pw.Widget _trendTable(Map<int, int> data) {
    if (data.isEmpty) {
      return _emptyMessage('No publication trend data is available.');
    }

    return _table(
      headers: const ['Year', 'Publications'],
      rows: data.entries
          .map((entry) => [entry.key.toString(), entry.value.toString()])
          .toList(),
      columnWidths: const {0: pw.FixedColumnWidth(80), 1: pw.FlexColumnWidth()},
    );
  }

  pw.Widget _publicationTable(List<Publication> publications) {
    if (publications.isEmpty) {
      return _emptyMessage('No publications are available.');
    }

    return _table(
      headers: const ['Rank', 'Title', 'Year', 'Journal', 'Citations'],
      rows: [
        for (var index = 0; index < publications.length; index++)
          [
            '${index + 1}',
            _publicationTitle(publications[index]),
            publications[index].displayYear,
            _value(publications[index].displayJournal),
            publications[index].citedByCount.toString(),
          ],
      ],
      columnWidths: const {
        0: pw.FixedColumnWidth(36),
        1: pw.FlexColumnWidth(2.4),
        2: pw.FixedColumnWidth(56),
        3: pw.FlexColumnWidth(1.4),
        4: pw.FixedColumnWidth(56),
      },
    );
  }

  pw.Widget _rankingTable(
    Iterable<MapEntry<String, int>> entries, {
    required String unit,
  }) {
    final ranking = entries.toList();

    if (ranking.isEmpty) {
      return _emptyMessage('No ranking data is available.');
    }

    return _table(
      headers: const ['Rank', 'Name', 'Count'],
      rows: [
        for (var index = 0; index < ranking.length; index++)
          [
            '${index + 1}',
            _value(ranking[index].key),
            '${ranking[index].value} $unit',
          ],
      ],
      columnWidths: const {
        0: pw.FixedColumnWidth(42),
        1: pw.FlexColumnWidth(),
        2: pw.FixedColumnWidth(78),
      },
    );
  }

  pw.Widget _table({
    required List<String> headers,
    required List<List<String>> rows,
    required Map<int, pw.TableColumnWidth> columnWidths,
  }) {
    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: rows,
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.45),
      cellAlignment: pw.Alignment.centerLeft,
      headerAlignment: pw.Alignment.centerLeft,
      columnWidths: columnWidths,
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey50),
      headerStyle: pw.TextStyle(
        color: PdfColors.blueGrey900,
        fontSize: 9,
        fontWeight: pw.FontWeight.bold,
      ),
      cellStyle: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey900),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
    );
  }

  pw.Widget _insightSummary(TrendReportSnapshot report) {
    if (report.publications.isEmpty) {
      return _emptyMessage(
        'No insights can be generated without publications.',
      );
    }

    final insights = [
      'The topic contains ${report.totalPublications} publications in the retrieved OpenAlex result set.',
      'The average citation count is ${report.averageCitationCount.toStringAsFixed(2)}.',
      'The most active publication year is ${report.mostActiveYear ?? 'N/A'}.',
      'The publication trend is ${_trendDirection(report.publicationCountByYear)}.',
      if (report.mostInfluentialPaper != null)
        'The most influential paper is "${_publicationTitle(report.mostInfluentialPaper!)}" with ${report.mostInfluentialPaper!.citedByCount} citations.',
    ];

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: insights
          .map(
            (insight) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 6),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    '- ',
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.blueGrey700,
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Text(
                      insight,
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  pw.Widget _emptyMessage(String message) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Text(
        message,
        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
      ),
    );
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

    return 'trend-report-${safeTopic.isEmpty ? 'topic' : safeTopic}-$timestamp.pdf';
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

  static String _publicationTitle(Publication publication) {
    final title = _normalizeText(publication.title).trim();

    if (title.isEmpty) {
      return 'Untitled publication';
    }

    return title;
  }

  static String _value(String? value) {
    final normalized = _normalizeText(value).trim();

    if (normalized.isEmpty) {
      return 'N/A';
    }

    return normalized;
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
        .replaceAll('\u00C2', '')
        .replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'), '');
  }
}

class _SummaryItem {
  final String label;
  final String value;

  const _SummaryItem(this.label, this.value);
}

class _PdfReportFonts {
  final pw.Font regular;
  final pw.Font bold;

  const _PdfReportFonts({required this.regular, required this.bold});
}
