import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openalex/models/auth/app_user.dart';
import 'package:openalex/models/publication/publication.dart';
import 'package:openalex/viewmodels/publication_detail_view_model.dart';
import 'package:openalex/screens/publication/publication_detail_screen.dart';
import 'package:openalex/services/analytics/app_analytics_service.dart';
import 'package:provider/provider.dart';

class FakePublicationDetailViewModel extends PublicationDetailViewModel {
  FakePublicationDetailViewModel({
    required DetailState fakeState,
    Publication? fakePublication,
    String? fakeError,
  }) : _fakeState = fakeState,
       _fakePublication = fakePublication,
       _fakeError = fakeError;

  final DetailState _fakeState;
  final Publication? _fakePublication;
  final String? _fakeError;

  bool loadDetailCalled = false;
  String? requestedWorkId;

  @override
  DetailState get state => _fakeState;

  @override
  Publication? get publication => _fakePublication;

  @override
  String? get error => _fakeError;

  @override
  Future<void> loadDetail(String workId) async {
    loadDetailCalled = true;
    requestedWorkId = workId;
  }
}

class FakeFirebaseAnalyticsService implements AppAnalyticsService {
  final List<({String title, int? year})> viewEvents = [];

  @override
  Future<void> clearUser() async {}

  @override
  Future<void> logLogin({
    required AppUser user,
    required String method,
  }) async {}

  @override
  Future<void> logLogout({
    required AppUser? user,
    required String method,
  }) async {}

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
  Future<void> logViewPublication({
    required String publicationTitle,
    required int? publicationYear,
  }) async {
    if (publicationTitle.trim().isEmpty || publicationYear == null) return;
    viewEvents.add((title: publicationTitle.trim(), year: publicationYear));
  }

  @override
  Future<void> logViewKeyword({required String keyword}) async {}
}

Publication fakePublication({
  String id = 'https://openalex.org/W1',
  String title = 'Test AI Publication',
  int? year = 2024,
  String? journalName = 'IEEE Access',
  String? doi = 'https://doi.org/10.1000/test',
  String? abstractText =
      'This is a long abstract about artificial intelligence research. '
      'It explains the method, result, contribution, and limitation.',
  int citedByCount = 123,
  List<String> authors = const ['John Doe', 'Jane Smith'],
  List<String> relatedWorkIds = const ['W2', 'W3'],
  List<String> referencedWorkIds = const ['W4'],
}) {
  return Publication.fromJson({
    'id': id,
    'display_name': title,
    'publication_year': year,
    'cited_by_count': citedByCount,
    'doi': doi,
    'abstract_inverted_index': abstractText == null
        ? null
        : {
            'This': [0],
            'abstract': [1],
            'describes': [2],
            'artificial': [3],
            'intelligence': [4],
            'research': [5],
            'methods': [6],
            'results': [7],
            'contribution': [8],
            'limitation': [9],
          },
    'primary_location': {
      'source': {'display_name': journalName},
    },
    'authorships': authors
        .map(
          (name) => {
            'author': {'display_name': name},
          },
        )
        .toList(),
    'related_works': relatedWorkIds,
    'referenced_works': referencedWorkIds,
    'open_access': {'is_oa': true, 'oa_url': 'https://example.com/paper.pdf'},
    'best_oa_location': {
      'pdf_url': 'https://example.com/paper.pdf',
      'landing_page_url': 'https://example.com',
    },
  });
}

Widget buildScreen({
  required FakePublicationDetailViewModel provider,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<PublicationDetailViewModel>.value(value: provider),
    ],
    child: const MaterialApp(
      home: PublicationDetailScreen(
        workId: 'W1',
        initialTitle: 'Initial title',
      ),
    ),
  );
}

void main() {
  group('PublicationDetailScreen extra coverage', () {
    testWidgets('loads detail when the screen is mounted', (tester) async {
      final provider = FakePublicationDetailViewModel(
        fakeState: DetailState.success,
        fakePublication: fakePublication(title: 'Tracked Paper', year: 2023),
      );

      await tester.pumpWidget(buildScreen(provider: provider));
      await tester.pumpAndSettle();

      expect(provider.loadDetailCalled, isTrue);
      expect(provider.requestedWorkId, 'W1');
    });

    testWidgets('shows loading state with initial title', (tester) async {
      final provider = FakePublicationDetailViewModel(
        fakeState: DetailState.loading,
      );

      await tester.pumpWidget(buildScreen(provider: provider));
      await tester.pump();

      expect(find.text('Initial title'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(provider.loadDetailCalled, isTrue);
      expect(provider.requestedWorkId, 'W1');
    });

    testWidgets('shows error state', (tester) async {
      final provider = FakePublicationDetailViewModel(
        fakeState: DetailState.error,
        fakeError: 'Cannot load publication detail.',
      );

      await tester.pumpWidget(buildScreen(provider: provider));
      await tester.pump();

      expect(find.text('Cannot load publication detail.'), findsOneWidget);
    });

    testWidgets('shows publication info section with full data', (
      tester,
    ) async {
      final provider = FakePublicationDetailViewModel(
        fakeState: DetailState.success,
        fakePublication: fakePublication(),
      );

      await tester.pumpWidget(buildScreen(provider: provider));
      await tester.pumpAndSettle();

      expect(find.text('Test AI Publication'), findsWidgets);
      expect(find.text('Authors'), findsOneWidget);
      expect(find.text('John Doe, Jane Smith'), findsOneWidget);
      expect(find.text('Publication year'), findsOneWidget);
      expect(find.text('2024'), findsOneWidget);
      expect(find.text('Journal'), findsOneWidget);
      expect(find.text('IEEE Access'), findsOneWidget);
      expect(find.text('Cited'), findsOneWidget);
      expect(find.text('123'), findsOneWidget);
      expect(find.text('DOI'), findsOneWidget);
      expect(find.text('https://doi.org/10.1000/test'), findsWidgets);
    });

    testWidgets('shows fallback values when optional data is missing', (
      tester,
    ) async {
      final provider = FakePublicationDetailViewModel(
        fakeState: DetailState.success,
        fakePublication: fakePublication(
          year: null,
          journalName: null,
          doi: null,
          abstractText: null,
          authors: const [],
          citedByCount: 0,
          relatedWorkIds: const [],
          referencedWorkIds: const [],
        ),
      );

      await tester.pumpWidget(buildScreen(provider: provider));
      await tester.pumpAndSettle();

      expect(find.text('Unknown authors'), findsOneWidget);
      expect(find.text('Unknown year'), findsOneWidget);
      expect(find.text('Unknown journal'), findsOneWidget);
      expect(find.text('No DOI available'), findsOneWidget);
      expect(
        find.text('No abstract available for this publication.'),
        findsOneWidget,
      );

      expect(find.text('Open DOI'), findsNothing);
      expect(find.text('Origin Page'), findsNothing);
      expect(find.text('Copy DOI'), findsNothing);
    });

    testWidgets('abstract section expands and collapses', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final provider = FakePublicationDetailViewModel(
        fakeState: DetailState.success,
        fakePublication: fakePublication(
          abstractText:
              'This abstract describes artificial intelligence research methods results contribution limitation. '
              'This section is intentionally long enough to test expand and collapse behavior. '
              'The user should be able to tap View more and then tap Collapse.',
        ),
      );

      await tester.pumpWidget(buildScreen(provider: provider));
      await tester.pumpAndSettle();

      expect(find.text('Abstract'), findsOneWidget);
      expect(find.text('View more'), findsOneWidget);

      final viewMoreFinder = find.text('View more');

      await tester.ensureVisible(viewMoreFinder);
      await tester.pumpAndSettle();

      await tester.tap(viewMoreFinder, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text('Collapse'), findsOneWidget);

      final collapseFinder = find.text('Collapse');

      await tester.ensureVisible(collapseFinder);
      await tester.pumpAndSettle();

      await tester.tap(collapseFinder, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text('View more'), findsOneWidget);
    });
    testWidgets('shows action buttons when DOI and OA URL exist', (
      tester,
    ) async {
      final provider = FakePublicationDetailViewModel(
        fakeState: DetailState.success,
        fakePublication: fakePublication(),
      );

      await tester.pumpWidget(buildScreen(provider: provider));
      await tester.pumpAndSettle();

      expect(find.text('View PDF'), findsOneWidget);
      expect(find.text('Origin Page'), findsOneWidget);
      expect(find.text('Copy DOI'), findsOneWidget);
      expect(find.text('Save to Zotero'), findsOneWidget);
      expect(find.text('Open DOI'), findsOneWidget);
    });

    testWidgets('copy DOI button shows snackbar', (tester) async {
      final provider = FakePublicationDetailViewModel(
        fakeState: DetailState.success,
        fakePublication: fakePublication(),
      );

      await tester.pumpWidget(buildScreen(provider: provider));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Copy DOI'));
      await tester.pumpAndSettle();

      expect(find.text('Already copy DOI'), findsOneWidget);
    });

    testWidgets('shows discovery navigation cards', (tester) async {
      final provider = FakePublicationDetailViewModel(
        fakeState: DetailState.success,
        fakePublication: fakePublication(),
      );

      await tester.pumpWidget(buildScreen(provider: provider));
      await tester.pumpAndSettle();

      expect(find.text('Discovery More'), findsOneWidget);
      expect(find.text('Related Articles'), findsOneWidget);
      expect(find.text('2 papers'), findsOneWidget);
      expect(find.text('Cited By'), findsOneWidget);
      expect(find.text('Citation Counts 123'), findsOneWidget);
      expect(find.text('References'), findsOneWidget);
      expect(find.text('1 references'), findsOneWidget);
    });

    testWidgets('disabled discovery cards show block icon when no data', (
      tester,
    ) async {
      final provider = FakePublicationDetailViewModel(
        fakeState: DetailState.success,
        fakePublication: fakePublication(
          citedByCount: 0,
          relatedWorkIds: const [],
          referencedWorkIds: const [],
        ),
      );

      await tester.pumpWidget(buildScreen(provider: provider));
      await tester.pumpAndSettle();

      expect(find.text('0 papers'), findsOneWidget);
      expect(find.text('Citation Counts 0'), findsOneWidget);
      expect(find.text('0 references'), findsOneWidget);
      expect(find.byIcon(Icons.block), findsNWidgets(3));
    });
  });
}
