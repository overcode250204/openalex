import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import '../models/trend/trend_report_snapshot.dart';
import 'pdf_report_layout_service.dart';

typedef ExportDirectoryResolver = Future<Directory> Function();

class PdfExportResult {
  final File file;
  final Uint8List bytes;
  final int byteLength;
  final DateTime generatedAt;

  const PdfExportResult({
    required this.file,
    required this.bytes,
    required this.byteLength,
    required this.generatedAt,
  });
}

class PdfExportService {
  final PdfReportLayoutService _layoutService;
  final ExportDirectoryResolver _directoryResolver;

  const PdfExportService({
    required PdfReportLayoutService layoutService,
    ExportDirectoryResolver directoryResolver = _defaultExportDirectory,
  }) : _layoutService = layoutService,
       _directoryResolver = directoryResolver;

  Future<PdfExportResult> exportDashboardPdfReport(
    TrendReportSnapshot report, {
    DateTime? generatedAt,
  }) async {
    final layout = await _layoutService.buildDashboardReport(
      report,
      generatedAt: generatedAt,
    );
    final directory = await _directoryResolver();
    final file = File(
      '${directory.path}${Platform.pathSeparator}${layout.fileName}',
    );

    await file.writeAsBytes(layout.bytes, flush: true);

    return PdfExportResult(
      file: file,
      bytes: layout.bytes,
      byteLength: layout.bytes.length,
      generatedAt: layout.generatedAt,
    );
  }

  static Future<Directory> _defaultExportDirectory() async {
    final baseDirectory = await getApplicationDocumentsDirectory();
    final exportDirectory = Directory(
      '${baseDirectory.path}${Platform.pathSeparator}OpenAlexReports',
    );

    return exportDirectory.create(recursive: true);
  }
}
