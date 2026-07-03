import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openalex/models/journal/journal_source.dart';
import 'package:openalex/models/publication/publication.dart';
import 'package:openalex/models/topic/topic.dart';
import 'package:openalex/screens/journal/journal_detail_screen.dart';
import 'package:openalex/services/analytics/app_analytics_service.dart';
import 'package:openalex/services/openalex_journal_service.dart';
import 'package:openalex/services/openalex_service.dart';
import 'package:openalex/services/suggestion_service.dart';
import 'package:openalex/viewmodels/home_view_model.dart';
import 'package:openalex/viewmodels/selected_topic_view_model.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class _RecordingAnalyticsService implements AppAnalyticsService {
  final List<String> loggedJournalNames = [];

  @override
  Future<void> logViewJournal({required String journalName}) async {
    loggedJournalNames.add(journalName);
  }

  @override
  Future<void> logLogin({required user, required String method}) async {}

  @override
  Future<void> logLogout({required user, required String method}) async {}

  @override
  Future<void> clearUser() async {}

  @override
  Future<void> logSearchTopic(
    String keyword, {
    int? resultCount,
    String? searchSource,
    String? topicId,
    int? hasValidTopic,
    int? filterYearFrom,
    int? filterYearTo,
    int? openAccessOnly,
    String? sortOption,
  }) async {}

  @override
  Future<void> logViewKeyword({required String keyword}) async {}

  @override
  Future<void> logViewPublication({
    required String publicationTitle,
    required int? publicationYear,
  }) async {}

  @override
  Future<void> logExportPdf({
    required String topic,
    required int publicationCount,
  }) async {}

  @override
  Future<void> logPdfExport({
    required String topic,
    required String exportType,
    required String provider,
    required String bucket,
    required String fileName,
    required int sizeBytes,
    required int hasUploadedLink,
  }) async {}
}

class _FakeJournalService extends OpenAlexJournalService {
  final Future<List<Publication>> Function() onFetchPubs;

  _FakeJournalService(this.onFetchPubs);

  @override
  Future<List<Publication>> fetchPublicationsForJournal(
    String journalId, {
    int perPage = 10,
    int page = 1,
  }) => onFetchPubs();
}

class _FakeOpenAlexService extends OpenAlexService {
  final List<Publication> publications;

  _FakeOpenAlexService(this.publications);

  @override
  Future<(int, List<Publication>)> searchPublications({
    required String keyword,
    int perPage = 50,
    String sort = 'cited_by_count:desc',
    List<String>? topicIds,
  }) async => (publications.length, publications);

  @override
  Future<List<String>> getTopicIdsFromKeyword(String keyword) async => [];
}

class _FakeSuggestionService extends SuggestionService {
  @override
  Future<List<TopicSuggestion>> fetchTopicSuggestions(String query) async => [];

  @override
  Future<List<String>> fetchRelatedKeywords(String keyword) async => [];
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Publication _pub({
  required String id,
  String journalName = 'Nature',
  int citedByCount = 0,
}) {
  return Publication(
    id: id,
    title: 'Title $id',
    publicationYear: 2024,
    citedByCount: citedByCount,
    journalName: journalName,
    doi: null,
    abstractText: null,
    authors: const [],
    relatedWorkIds: const [],
    referencedWorkIds: const [],
  );
}

const _natureJournal = JournalSource(
  id: 'https://openalex.org/S_NATURE',
  displayName: 'Nature',
  publisher: 'Nature Portfolio',
  worksCount: 2,
  citedByCount: 30,
);

Widget _wrap(
  JournalSource journal,
  AppAnalyticsService analyticsService, {
  HomeViewModel? homeViewModel,
  OpenAlexJournalService? journalService,
}) {
  return MultiProvider(
    providers: [
      Provider<AppAnalyticsService>.value(value: analyticsService),
      if (journalService != null)
        Provider<OpenAlexJournalService>.value(value: journalService),
      if (homeViewModel != null)
        ChangeNotifierProvider<HomeViewModel>.value(value: homeViewModel),
    ],
    child: MaterialApp(home: JournalDetailScreen(journal: journal)),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('renders journal name, stats chips', (tester) async {
    await tester.pumpWidget(
      _wrap(
        _natureJournal,
        _RecordingAnalyticsService(),
        journalService: _FakeJournalService(() async => []),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Nature'), findsWidgets);
    expect(find.textContaining('2 publications'), findsOneWidget);
    expect(find.textContaining('30 citations'), findsOneWidget);
    expect(find.textContaining('15.0 avg citations'), findsOneWidget);
    expect(find.textContaining('Nature Portfolio'), findsOneWidget);
  });

  testWidgets('fetches publications from API when no topic is searched', (
    tester,
  ) async {
    final completer = Completer<List<Publication>>();
    final apiPubs = [
      _pub(id: 'api_1', journalName: 'Nature', citedByCount: 100),
      _pub(id: 'api_2', journalName: 'Nature', citedByCount: 80),
    ];

    await tester.pumpWidget(
      _wrap(
        _natureJournal,
        _RecordingAnalyticsService(),
        journalService: _FakeJournalService(() => completer.future),
      ),
    );

    // post-frame callback fires → _fetchFromApi starts → loading state
    await tester.pump();
    expect(find.text('Loading publications...'), findsOneWidget);

    // complete the fetch and let the widget rebuild
    completer.complete(apiPubs);
    await tester.pump();
    await tester.pump();

    expect(find.text('Title api_1'), findsOneWidget);
    expect(find.text('Title api_2'), findsOneWidget);
    expect(find.text('Top cited in this journal'), findsOneWidget);
  });

  testWidgets(
    'uses topic publications when HomeViewModel has matching pubs',
    (tester) async {
      final selectedTopicViewModel = SelectedTopicViewModel();
      final topicPubs = [
        _pub(id: 'topic_1', journalName: 'Nature', citedByCount: 10),
        _pub(id: 'topic_2', journalName: 'Nature', citedByCount: 20),
      ];
      final homeViewModel = HomeViewModel(
        _FakeOpenAlexService(topicPubs),
        suggestionService: _FakeSuggestionService(),
        selectedTopicViewModel: selectedTopicViewModel,
      );
      await homeViewModel.searchPublications(keyword: 'test');

      await tester.pumpWidget(
        _wrap(
          _natureJournal,
          _RecordingAnalyticsService(),
          homeViewModel: homeViewModel,
          // No journalService needed — topic path skips API call
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('Title topic_1'), findsOneWidget);
      expect(find.text('Title topic_2'), findsOneWidget);
      expect(find.text('From your current topic search'), findsOneWidget);
    },
  );

  testWidgets('shows error state when API fetch fails', (tester) async {
    await tester.pumpWidget(
      _wrap(
        _natureJournal,
        _RecordingAnalyticsService(),
        journalService: _FakeJournalService(
          () async => throw Exception('network error'),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(find.text('Could not load publications.'), findsOneWidget);
  });

  testWidgets('shows empty state when API returns no publications', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        _natureJournal,
        _RecordingAnalyticsService(),
        journalService: _FakeJournalService(() async => []),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(
      find.text('No publications found for this journal.'),
      findsOneWidget,
    );
  });

  testWidgets('logs view_journal once with the journal name', (tester) async {
    final analyticsService = _RecordingAnalyticsService();

    await tester.pumpWidget(
      _wrap(
        _natureJournal,
        analyticsService,
        journalService: _FakeJournalService(() async => []),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(analyticsService.loggedJournalNames, ['Nature']);
  });

  testWidgets('back navigation pops the screen', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MultiProvider(
                  providers: [
                    Provider<AppAnalyticsService>.value(
                      value: _RecordingAnalyticsService(),
                    ),
                    Provider<OpenAlexJournalService>.value(
                      value: _FakeJournalService(() async => []),
                    ),
                  ],
                  child: const JournalDetailScreen(journal: _natureJournal),
                ),
              ),
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Nature'), findsWidgets);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Open'), findsOneWidget);
  });
}
