import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openalex/main.dart';
import 'package:openalex/models/analytics/topic_analytics.dart';
import 'package:openalex/models/publication/publication.dart';
import 'package:openalex/models/report/report_upload_result.dart';
import 'package:openalex/models/search/search_filter.dart';
import 'package:openalex/models/trend/trend_report_snapshot.dart';
import 'package:openalex/routes/route_arguments.dart';
import 'package:openalex/screens/dashboard/dashboard_screen.dart';
import 'package:openalex/services/analytics/analytics_service.dart';
import 'package:openalex/services/openalex_service.dart';
import 'package:openalex/services/pdf_export_service.dart';
import 'package:openalex/services/pdf_report_layout_service.dart';
import 'package:openalex/services/report/report_storage_service.dart';
import 'package:openalex/services/trend_report_export_service.dart';
import 'package:openalex/utils/app_keys.dart';
import 'package:openalex/viewmodels/analytics_view_model.dart';
import 'package:openalex/viewmodels/dashboard_view_model.dart';
import 'package:openalex/viewmodels/home_view_model.dart';
import 'package:openalex/viewmodels/selected_topic_view_model.dart';
import 'package:patrol_finders/patrol_finders.dart';
import 'package:provider/provider.dart';

import 'fakes/fake_auth_service.dart';

const _patrolConfig = PatrolTesterConfig(settlePolicy: SettlePolicy.noSettle);

class _FakeAnalyticsService extends AnalyticsService {
  @override
  Future<TopicAnalytics> fetchAll(
    String keyword,
    SearchFilter filter, {
    String? topicId,
  }) async {
    return const TopicAnalytics(
      publicationTrend: {2023: 2, 2024: 3},
      topKeywords: {'AI': 5},
      institutionRanking: {'Open Lab': 2},
      countryOutput: {'USA': 3},
      topJournals: {'Journal of Tests': 2},
      topAuthors: {'Ada Lovelace': 2},
      totalWorks: 5,
      analyzedWorks: 5,
      totalCitations: 50,
      mostInfluentialPaper: InfluentialPaperSummary(
        id: 'W1',
        title: 'Reliable Research',
        citedByCount: 30,
        publicationYear: 2024,
      ),
    );
  }
}

class _FakeOpenAlexService extends OpenAlexService {
  @override
  Future<(int total, List<Publication> publications)> searchPublications({
    required String keyword,
    int perPage = 50,
    String sort = 'cited_by_count:desc',
    List<String>? topicIds,
  }) async {
    return (0, <Publication>[]);
  }
}

class _RecordingPdfExportService extends PdfExportService {
  _RecordingPdfExportService()
    : super(layoutService: const PdfReportLayoutService());

  var exportCount = 0;

  @override
  Future<PdfExportResult> exportDashboardPdfReport(
    TrendReportSnapshot report, {
    DateTime? generatedAt,
  }) async {
    exportCount++;
    final directory = Directory.systemTemp.createTempSync('patrol-pdf-export');
    final file = File('${directory.path}/patrol-export-report.pdf');
    final bytes = Uint8List.fromList([1, 2, 3]);
    file.writeAsBytesSync(bytes, flush: true);

    return PdfExportResult(
      file: file,
      bytes: bytes,
      byteLength: bytes.length,
      generatedAt: generatedAt ?? DateTime(2026, 6, 25),
    );
  }
}

class _RecordingReportStorageService implements ReportStorageService {
  var uploadCount = 0;

  @override
  Future<ReportUploadResult> uploadReport({
    required Uint8List bytes,
    required String fileName,
    required String contentType,
    required String topic,
    DateTime? uploadedAt,
  }) async {
    uploadCount++;

    return ReportUploadResult(
      provider: 'fake',
      bucket: 'reports',
      objectKey: 'reports/$fileName',
      fileName: fileName,
      downloadUrl: 'https://cdn.test/$fileName',
      sizeBytes: bytes.length,
      uploadedAt: uploadedAt ?? DateTime.utc(2026, 6, 25),
    );
  }
}

class _FakeRemoteConfigService {
  Future<Map<String, Object>> fetchAndActivate() async {
    return {
      'profile_enabled': true,
      'pdf_export_enabled': true,
      'logout_confirmation_enabled': true,
    };
  }
}

class _RemoteConfigProbe extends StatefulWidget {
  const _RemoteConfigProbe({required this.service});

  final _FakeRemoteConfigService service;

  @override
  State<_RemoteConfigProbe> createState() => _RemoteConfigProbeState();
}

class _RemoteConfigProbeState extends State<_RemoteConfigProbe> {
  Map<String, Object>? _values;

  @override
  void initState() {
    super.initState();
    widget.service.fetchAndActivate().then((values) {
      if (!mounted) return;
      setState(() => _values = values);
    });
  }

  @override
  Widget build(BuildContext context) {
    final values = _values;
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: values == null
              ? const CircularProgressIndicator()
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Remote Config'),
                    Text('Profile enabled: ${values['profile_enabled']}'),
                    Text('PDF export enabled: ${values['pdf_export_enabled']}'),
                    Text(
                      'Logout confirmation enabled: '
                      '${values['logout_confirmation_enabled']}',
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

Widget _dashboardHarness(
  _RecordingPdfExportService exportService,
  _RecordingReportStorageService storageService,
) {
  final openAlexService = _FakeOpenAlexService();
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => SelectedTopicViewModel()),
      ChangeNotifierProvider(create: (_) => HomeViewModel(openAlexService)),
      ChangeNotifierProvider(
        create: (_) =>
            AnalyticsViewModel(analyticsService: _FakeAnalyticsService()),
      ),
      ChangeNotifierProvider(
        create: (_) => DashboardViewModel(
          exportService: const TrendReportExportService(),
          pdfExportService: exportService,
          reportStorageService: storageService,
        ),
      ),
    ],
    child: const MaterialApp(
      home: DashboardScreen(
        arguments: TopicAnalyticsRouteArgs(
          topicId: 'T1',
          topicName: 'Artificial Intelligence',
        ),
      ),
    ),
  );
}

void main() {
  patrolWidgetTest('Profile shows Firebase Auth user data', ($) async {
    await $.tester.pumpWidget(
      MyApp(authService: FakeAuthService(initialUser: fakeUser())),
    );
    await $.tester.pump();
    await $.tester.pump(const Duration(milliseconds: 300));

    await $(find.byKey(AppKeys.profileTab)).tap();
    await $.tester.pump(const Duration(milliseconds: 300));

    expect($('Profile'), findsWidgets);
    expect($('Researcher One'), findsOneWidget);
    expect($('researcher@example.com'), findsOneWidget);
    expect($('Google via Firebase Auth'), findsOneWidget);
  }, config: _patrolConfig);

  patrolWidgetTest(
    'Remote Config values can be fetched and reflected in UI',
    ($) async {
      await $.tester.pumpWidget(
        _RemoteConfigProbe(service: _FakeRemoteConfigService()),
      );
      await $.tester.pump();
      await $.tester.pump(const Duration(milliseconds: 50));

      expect($('Remote Config'), findsOneWidget);
      expect($('Profile enabled: true'), findsOneWidget);
      expect($('PDF export enabled: true'), findsOneWidget);
      expect($('Logout confirmation enabled: true'), findsOneWidget);
    },
    config: _patrolConfig,
  );

  patrolWidgetTest('PDF export action creates an export result', ($) async {
    final exportService = _RecordingPdfExportService();
    final storageService = _RecordingReportStorageService();
    $.tester.view.physicalSize = const Size(1200, 1800);
    $.tester.view.devicePixelRatio = 1;
    addTearDown($.tester.view.resetPhysicalSize);
    addTearDown($.tester.view.resetDevicePixelRatio);

    await $.tester.pumpWidget(_dashboardHarness(exportService, storageService));
    await $.tester.pump();
    await $.tester.pump(const Duration(milliseconds: 300));
    final listView = find.byType(ListView);
    final exportButton = find.byKey(AppKeys.exportPdfButton);
    for (
      var attempt = 0;
      attempt < 8 && exportButton.evaluate().isEmpty;
      attempt++
    ) {
      await $.tester.drag(listView, const Offset(0, -800));
      await $.tester.pump(const Duration(milliseconds: 100));
    }

    expect(exportButton, findsOneWidget);

    await $.tester.tap(exportButton);
    await $.tester.pump();
    for (
      var attempt = 0;
      attempt < 10 && storageService.uploadCount == 0;
      attempt++
    ) {
      await $.tester.pump(const Duration(milliseconds: 100));
    }

    expect(exportService.exportCount, 1);
    expect(storageService.uploadCount, 1);
    expect(
      $('Dashboard PDF uploaded: https://cdn.test/patrol-export-report.pdf'),
      findsOneWidget,
    );
  }, config: _patrolConfig);

  patrolWidgetTest('Logout redirects to Login Screen', ($) async {
    final authService = FakeAuthService(initialUser: fakeUser());

    await $.tester.pumpWidget(MyApp(authService: authService));
    await $.tester.pump();
    await $.tester.pump(const Duration(milliseconds: 300));
    await $(find.byKey(AppKeys.profileTab)).tap();
    await $.tester.pump(const Duration(milliseconds: 300));

    await $(find.byKey(AppKeys.logoutButton)).tap();
    await $.tester.pump();
    await $.tester.pump(const Duration(milliseconds: 300));

    await $(find.widgetWithText(FilledButton, 'Sign out')).tap();
    await $.tester.pump();
    await $.tester.pump(const Duration(milliseconds: 300));

    expect(authService.signOutCount, 1);
    expect($('Journal Trend Analyzer'), findsOneWidget);
    expect($('Continue with Google'), findsOneWidget);
    expect($('Profile'), findsNothing);
  }, config: _patrolConfig);
}
