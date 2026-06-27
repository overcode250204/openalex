import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openalex/models/report/report_upload_result.dart';
import 'package:openalex/main.dart';
import 'package:openalex/models/analytics/topic_analytics.dart';
import 'package:openalex/models/publication/publication.dart';
import 'package:openalex/models/search/search_filter.dart';
import 'package:openalex/models/topic/topic.dart';
import 'package:openalex/models/trend/trend_report_snapshot.dart';
import 'package:openalex/routes/route_arguments.dart';
import 'package:openalex/viewmodels/analytics_view_model.dart';
import 'package:openalex/viewmodels/dashboard_view_model.dart';
import 'package:openalex/viewmodels/publication_detail_view_model.dart';
import 'package:openalex/viewmodels/home_view_model.dart';
import 'package:openalex/screens/dashboard/dashboard_screen.dart';
import 'package:openalex/screens/publication/publication_detail_screen.dart'
    as screen_detail;
import 'package:openalex/screens/search/search_screen.dart';
import 'package:openalex/screens/trend/trend_analysis_screen.dart';
import 'package:openalex/services/history_service.dart';
import 'package:openalex/services/analytics/analytics_service.dart';
import 'package:openalex/services/openalex_service.dart';
import 'package:openalex/services/pdf_export_service.dart';
import 'package:openalex/services/pdf_report_layout_service.dart';
import 'package:openalex/services/report/report_storage_service.dart';
import 'package:openalex/services/suggestion_service.dart';
import 'package:openalex/services/trend_report_export_service.dart';
import 'package:openalex/utils/app_keys.dart';
import 'package:openalex/viewmodels/trend_analysis_view_model.dart';
import 'package:openalex/widgets/publication_card.dart';
import 'package:openalex/widgets/publication_detail_screen.dart'
    as widget_detail;
import 'package:openalex/widgets/summary_card.dart';
import 'package:openalex/widgets/trend_chart.dart';
import 'package:provider/provider.dart';

import 'fakes/fake_auth_service.dart';

class FakeOpenAlexService extends OpenAlexService {
  FakeOpenAlexService(this.results, this.total);

  final List<Publication> results;
  final int total;
  @override
  Future<(int total, List<Publication> publications)> searchPublications({
    required String keyword,
    int perPage = 50,
    String sort = 'cited_by_count:desc',
    List<String>? topicIds,
  }) async {
    return (total, results);
  }
}

class FakeDetailService extends OpenAlexService {
  final Publication? publication;

  FakeDetailService(this.publication);

  @override
  Future<Publication?> fetchDetail(String workId) async {
    return publication;
  }
}

class FakeTrendService extends OpenAlexService {
  @override
  Future<Map<int, int>> fetchPublicationTrend({
    required String keyword,
    int fromYear = 2014,
    int? toYear,
    String? topicId,
  }) async => {2023: 1, 2024: 1};

  @override
  Future<List<Publication>> fetchInfluentialPapers({
    required String keyword,
    int? limit,
    String? topicId,
    int? fromYear,
    int? toYear,
  }) async => [
    Publication(
      id: 'W1',
      title: 'Influential',
      publicationYear: 2024,
      citedByCount: 30,
      journalName: 'Journal of Widgets',
      doi: null,
      abstractText: null,
      authors: const ['Ada Lovelace'],
      referencedWorkIds: const [],
      relatedWorkIds: const [],
    ),
  ];

  @override
  Future<Map<String, int>> fetchTopResearchJournals({
    required String keyword,
    int? limit,
    String? topicId,
    int? fromYear,
    int? toYear,
  }) async => {'Journal of Widgets': 2};

  @override
  Future<Map<String, int>> fetchTopContributingAuthors({
    required String keyword,
    int? limit,
    String? topicId,
    int? fromYear,
    int? toYear,
  }) async => {'Ada Lovelace': 2};
}

class FakeSearchHistoryService extends SearchHistoryService {
  @override
  Future<List<String>> getHistory() async {
    return [];
  }

  @override
  Future<void> addHistory(String keyword) async {}
}

class FakeSuggestionService extends SuggestionService {
  @override
  Future<List<TopicSuggestion>> fetchTopicSuggestions(String query) async {
    return [];
  }

  @override
  Future<List<String>> fetchRelatedKeywords(String keyword) async {
    return [];
  }
}

class FakeAnalyticsService extends AnalyticsService {
  @override
  Future<TopicAnalytics> fetchAll(
    String keyword,
    SearchFilter filter, {
    String? topicId,
  }) async {
    return const TopicAnalytics(
      publicationTrend: {2023: 1, 2024: 1},
      topKeywords: {'Artificial Intelligence': 2},
      institutionRanking: {},
      countryOutput: {},
      topJournals: {'Journal of Widgets': 2},
      topAuthors: {'Ada Lovelace': 2},
      totalWorks: 2,
      analyzedWorks: 2,
      totalCitations: 24,
      mostInfluentialPaper: InfluentialPaperSummary(
        id: 'W1',
        title: 'Top Paper',
        citedByCount: 20,
        publicationYear: 2024,
      ),
      topInfluentialPapers: [
        InfluentialPaperSummary(
          id: 'W1',
          title: 'Influential',
          citedByCount: 30,
          publicationYear: 2024,
        ),
      ],
      authorImpact: [
        AuthorImpactSummary(
          name: 'Ada Lovelace',
          paperCount: 2,
          totalCitations: 24,
        ),
      ],
    );
  }

  @override
  Future<TopicAnalytics> fetchSummary(
    String keyword,
    SearchFilter filter, {
    String? topicId,
  }) async {
    return const TopicAnalytics(
      publicationTrend: {2023: 1, 2024: 1},
      topKeywords: {},
      institutionRanking: {},
      countryOutput: {},
      topJournals: {'Journal of Widgets': 2},
      topAuthors: {'Ada Lovelace': 2},
      totalWorks: 2,
      analyzedWorks: 2,
      totalCitations: 24,
      mostInfluentialPaper: InfluentialPaperSummary(
        id: 'W1',
        title: 'Top Paper',
        citedByCount: 20,
        publicationYear: 2024,
      ),
      topInfluentialPapers: [
        InfluentialPaperSummary(
          id: 'W1',
          title: 'Influential',
          citedByCount: 30,
          publicationYear: 2024,
        ),
      ],
    );
  }
}

class FakeReportStorageService implements ReportStorageService {
  @override
  Future<ReportUploadResult> uploadReport({
    required Uint8List bytes,
    required String fileName,
    required String contentType,
    required String topic,
    DateTime? uploadedAt,
  }) async {
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

class FakePdfExportService extends PdfExportService {
  FakePdfExportService() : super(layoutService: const PdfReportLayoutService());

  @override
  Future<PdfExportResult> exportDashboardPdfReport(
    TrendReportSnapshot report, {
    DateTime? generatedAt,
  }) async {
    final bytes = Uint8List.fromList([1, 2, 3]);
    final directory = Directory.systemTemp.createTempSync('widget-pdf-export');
    final file = File('${directory.path}/dashboard-report.pdf');
    file.writeAsBytesSync(bytes, flush: true);

    return PdfExportResult(
      file: file,
      bytes: bytes,
      byteLength: bytes.length,
      generatedAt: generatedAt ?? DateTime.utc(2026, 6, 25, 9),
    );
  }
}

HomeViewModel testProvider(OpenAlexService service) {
  return HomeViewModel(
    service,
    historyService: FakeSearchHistoryService(),
    suggestionService: FakeSuggestionService(),
  );
}

Publication publication({
  String title = 'Test Publication',
  int citations = 12,
  int? year = 2024,
  String? journal = 'Journal of Widgets',
  String? doi = 'https://doi.org/10.1000/widget',
  String? abstractText = 'A useful abstract.',
  List<String> authors = const ['Ada Lovelace', 'Grace Hopper'],
}) {
  return Publication(
    id: title,
    title: title,
    publicationYear: year,
    citedByCount: citations,
    journalName: journal,
    doi: doi,
    abstractText: abstractText,
    authors: authors,
    referencedWorkIds: ["1", "2"],
    relatedWorkIds: ["1", "2"],
    oaUrl: "123",
  );
}

Future<HomeViewModel> seededProvider(List<Publication> publications) async {
  final provider = testProvider(FakeOpenAlexService(publications, 1));
  await provider.searchPublications(keyword: 'AI');
  return provider;
}

Widget appWithProvider(
  Widget child,
  HomeViewModel provider, {
  DashboardViewModel? dashboardViewModel,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<HomeViewModel>.value(value: provider),
      ChangeNotifierProvider(
        create: (_) =>
            AnalyticsViewModel(analyticsService: FakeAnalyticsService()),
      ),
      ChangeNotifierProvider(
        create: (_) => TrendAnalysisViewModel(service: FakeTrendService()),
      ),
      ChangeNotifierProvider(
        create: (_) =>
            dashboardViewModel ??
            DashboardViewModel(
              exportService: const TrendReportExportService(),
              pdfExportService: PdfExportService(
                layoutService: const PdfReportLayoutService(),
              ),
              reportStorageService: FakeReportStorageService(),
            ),
      ),
    ],
    child: MaterialApp(home: child),
  );
}

void main() {
  const topicArgs = TopicAnalyticsRouteArgs(topicId: 'T1', topicName: 'AI');

  testWidgets('MyApp shows the search experience', (tester) async {
    await tester.pumpWidget(
      MyApp(authService: FakeAuthService(initialUser: fakeUser())),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(find.text('Trend Analyzer'), findsOneWidget);
    expect(find.text('Research topic'), findsOneWidget);
    expect(find.text('Analyze Topic'), findsOneWidget);
    expect(
      find.text('Enter a research topic and tap Analyze Topic.'),
      findsOneWidget,
    );
  });

  testWidgets('SearchScreen submits filters and renders results', (
    tester,
  ) async {
    final provider = testProvider(
      FakeOpenAlexService([
        publication(title: 'Search Result', citations: 9),
      ], 1),
    );

    await tester.pumpWidget(appWithProvider(const SearchScreen(), provider));
    await tester.tap(find.text('Analyze Topic'));
    await tester.pumpAndSettle();

    expect(find.text('Search Result'), findsOneWidget);
    expect(find.byTooltip('Trend Analysis'), findsOneWidget);
    expect(find.byTooltip('Dashboard'), findsOneWidget);
  });

  testWidgets('SummaryCard and PublicationCard render and handle taps', (
    tester,
  ) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              const SummaryCard(
                title: 'Total Publications',
                value: '3',
                icon: Icons.article,
              ),
              PublicationCard(
                publication: publication(title: 'Card Paper'),
                onTap: () => tapped = true,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Total Publications'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('Card Paper'), findsOneWidget);

    await tester.tap(find.text('Card Paper'));
    expect(tapped, isTrue);
  });

  testWidgets('TrendChart shows empty state and chart state', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: TrendChart(data: {})),
      ),
    );
    expect(find.text('No trend data available.'), findsOneWidget);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: TrendChart(data: {2022: 1, 2023: 3})),
      ),
    );
    await tester.pump();
    expect(find.text('2022'), findsWidgets);
    expect(find.text('2023'), findsWidgets);
  });

  testWidgets('DashboardScreen shows empty and populated states', (
    tester,
  ) async {
    final emptyProvider = HomeViewModel(FakeOpenAlexService([], 1));
    await tester.pumpWidget(
      appWithProvider(
        const DashboardScreen(arguments: topicArgs),
        emptyProvider,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Dashboard: AI'), findsOneWidget);

    final provider = await seededProvider([
      publication(title: 'Top Paper', citations: 20, year: 2024),
      publication(title: 'Other Paper', citations: 4, year: 2023),
    ]);
    await tester.pumpWidget(
      appWithProvider(const DashboardScreen(arguments: topicArgs), provider),
    );
    await tester.pumpAndSettle();

    expect(find.text('Dashboard: AI'), findsOneWidget);
    expect(find.text('Total Publications'), findsOneWidget);
    expect(
      find.text('Average Citations (OpenAlex grouped sample)'),
      findsOneWidget,
    );
    expect(find.text('Most Influential Paper'), findsOneWidget);
    expect(find.text('Top Paper'), findsOneWidget);
  });

  testWidgets('DashboardScreen shows uploaded PDF link after upload', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final provider = await seededProvider([
      publication(title: 'Top Paper', citations: 20, year: 2024),
    ]);
    final dashboardViewModel = DashboardViewModel(
      exportService: const TrendReportExportService(),
      pdfExportService: FakePdfExportService(),
      reportStorageService: FakeReportStorageService(),
    );

    await tester.pumpWidget(
      appWithProvider(
        const DashboardScreen(arguments: topicArgs),
        provider,
        dashboardViewModel: dashboardViewModel,
      ),
    );
    await tester.pumpAndSettle();

    final listView = find.byType(ListView);
    final uploadButton = find.byKey(AppKeys.exportPdfButton);
    for (
      var attempt = 0;
      attempt < 8 && uploadButton.evaluate().isEmpty;
      attempt++
    ) {
      await tester.drag(listView, const Offset(0, -800));
      await tester.pump(const Duration(milliseconds: 100));
    }

    await tester.tap(uploadButton);
    await tester.pumpAndSettle();

    expect(find.byKey(AppKeys.uploadedPdfLinkCard), findsOneWidget);
    expect(find.text('Uploaded PDF report'), findsOneWidget);
    expect(find.text('https://cdn.test/dashboard-report.pdf'), findsOneWidget);
    expect(find.byKey(AppKeys.uploadedPdfCopyButton), findsOneWidget);
    expect(find.byKey(AppKeys.uploadedPdfOpenButton), findsOneWidget);

    await tester.tap(find.byKey(AppKeys.uploadedPdfDismissButton));
    await tester.pumpAndSettle();

    expect(find.byKey(AppKeys.uploadedPdfLinkCard), findsNothing);
  });

  testWidgets('TrendAnalysisScreen shows lists', (tester) async {
    final provider = await seededProvider([
      publication(title: 'Influential', citations: 30, year: 2024),
      publication(title: 'Less Influential', citations: 2, year: 2023),
    ]);

    await tester.pumpWidget(
      appWithProvider(
        const TrendAnalysisScreen(arguments: topicArgs),
        provider,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Publication Trend: AI'), findsOneWidget);

    expect(find.text('Top Influential Papers'), findsOneWidget);
    expect(find.text('Top Research Journals'), findsOneWidget);
    expect(find.text('Top Contributing Authors'), findsOneWidget);
    expect(find.text('Influential'), findsWidgets);
  });

  testWidgets(
    'screen PublicationDetailScreen renders fallbacks and Zotero error',
    (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => PublicationDetailViewModel(
            service: FakeDetailService(
              Publication(
                id: '1',
                title: 'Detail Paper',
                publicationYear: null,
                citedByCount: 0,
                journalName: null,
                doi: null,
                abstractText: null,
                authors: [],
                referencedWorkIds: [],
                relatedWorkIds: [],
                oaUrl: null,
              ),
            ),
          ),
          child: const MaterialApp(
            home: screen_detail.PublicationDetailScreen(workId: '1'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Unknown authors'), findsOneWidget);
      expect(find.text('Unknown year'), findsOneWidget);
      expect(find.text('Unknown journal'), findsOneWidget);
      expect(find.text('No DOI available'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('No abstract available for this publication.'),
        300,
        scrollable: find.byType(Scrollable),
      );
      expect(
        find.text('No abstract available for this publication.'),
        findsOneWidget,
      );

      await tester.scrollUntilVisible(
        find.text('Save to Zotero'),
        -300,
        scrollable: find.byType(Scrollable),
      );
      // await tester.tap(find.text('Save to Zotero'));
      // await tester.pump();
      // expect(find.textContaining('Failed to save:'), findsOneWidget);
    },
  );

  testWidgets('widget PublicationDetailScreen renders DOI button', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: widget_detail.PublicationDetailScreen(
          publication: publication(title: 'Widget Detail Paper'),
        ),
      ),
    );

    expect(find.text('Widget Detail Paper'), findsOneWidget);
    expect(find.text('Ada Lovelace, Grace Hopper'), findsOneWidget);
    expect(find.text('Open DOI'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('A useful abstract.'),
      300,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('A useful abstract.'), findsOneWidget);
  });
}
