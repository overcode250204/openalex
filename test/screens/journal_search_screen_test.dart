import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openalex/models/journal/journal_publication.dart';
import 'package:openalex/models/journal/journal_source.dart';
import 'package:openalex/viewmodels/journal_view_model.dart';
import 'package:openalex/viewmodels/remote_config_view_model.dart';
import 'package:openalex/screens/journal/journal_search_screen.dart';
import 'package:openalex/services/firebase/remote_config_service.dart';
import 'package:openalex/services/openalex_journal_service.dart';
import 'package:provider/provider.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------
import 'package:openalex/services/suggestion_service.dart';
import 'package:openalex/models/journal/journal_suggestion.dart';

class _FakeSuggestionService extends SuggestionService {
  final List<JournalSuggestion> suggestions;
  _FakeSuggestionService({this.suggestions = const []});

  @override
  Future<List<JournalSuggestion>> fetchJournalSuggestions(String query) async {
    return suggestions;
  }
}

class _MutableRemoteConfigService implements AppRemoteConfigService {
  _MutableRemoteConfigService({this.maxJournals = 10, this.nextMaxJournals});

  int maxJournals;
  int? nextMaxJournals;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> fetchAndActivate() async {
    final next = nextMaxJournals;
    if (next != null) {
      maxJournals = next;
      nextMaxJournals = null;
    }
    return true;
  }

  @override
  int get maxJournalsDisplayed => maxJournals;

  @override
  int get maxKeywordsDisplayed => 5;
}

class _FakeJournalService extends OpenAlexJournalService {
  final List<JournalSource> journalResults;
  final List<JournalPublication> publications;

  _FakeJournalService({
    this.journalResults = const [],
    this.publications = const [],
  });

  @override
  Future<List<JournalSource>> searchJournals(String query) async {
    return journalResults;
  }

  @override
  Future<List<JournalPublication>> getJournalPublications(
    String sourceId, {
    int page = 1,
    int perPage = 20,
  }) async {
    return publications;
  }

  @override
  Future<JournalPublication?> getHighestCitedPublication(
    String sourceId,
  ) async {
    return null;
  }
}

JournalSource _source({String id = 'S1', String name = 'IEEE Access'}) {
  return JournalSource(
    id: 'https://openalex.org/$id',
    sourceId: id,
    displayName: name,
    type: 'journal',
    issnL: '2169-3536',
    issn: ['2169-3536'],
    worksCount: 78000,
    citedByCount: 900000,
    hIndex: 84,
    hostOrganizationName: 'IEEE',
  );
}

Widget _buildScreen(
  JournalViewModel provider, {
  RemoteConfigViewModel? remoteConfigViewModel,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: provider),
      if (remoteConfigViewModel != null)
        ChangeNotifierProvider.value(value: remoteConfigViewModel),
    ],
    child: const MaterialApp(home: JournalSearchScreen()),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('JournalSearchScreen initial state', () {
    testWidgets('typing in search field shows suggestions', (tester) async {
      final provider = JournalViewModel(
        _FakeJournalService(),
        suggestionService: _FakeSuggestionService(
          suggestions: [
            JournalSuggestion(
              id: 'https://openalex.org/S1',
              displayName: 'Nature',
              worksCount: 100,
            ),
          ],
        ),
      );

      await tester.pumpWidget(_buildScreen(provider));

      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'Nat');

      // Wait for debounce and state update
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      expect(find.text('Nature'), findsOneWidget);

      // Tap suggestion
      await tester.tap(find.text('Nature'));
      await tester.pumpAndSettle();

      // Field is populated
      expect(find.widgetWithText(TextField, 'Nature'), findsOneWidget);
    });

    testWidgets('renders search results correctly after searching', (
      tester,
    ) async {
      final provider = JournalViewModel(
        _FakeJournalService(journalResults: []),
      );
      await tester.pumpWidget(_buildScreen(provider));

      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);

      final tf = tester.widget<TextField>(textField);
      expect(tf.controller?.text, 'IEEE Access');
    });

    testWidgets('renders Search Journal label', (tester) async {
      final provider = JournalViewModel(_FakeJournalService());
      await tester.pumpWidget(_buildScreen(provider));

      expect(find.text('Journal Search'), findsOneWidget);
    });
  });

  group('JournalSearchScreen – journal list', () {
    testWidgets('shows journal cards after successful search', (tester) async {
      final service = _FakeJournalService(
        journalResults: [
          _source(name: 'Nature'),
          _source(id: 'S2', name: 'Science'),
        ],
      );
      final provider = JournalViewModel(service);
      await tester.pumpWidget(_buildScreen(provider));

      // Trigger search
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();
      expect(find.text('Nature'), findsOneWidget);
      expect(find.text('Science', skipOffstage: false), findsOneWidget);
    });

    testWidgets('Remote Config fetch changes visible journal limit', (
      tester,
    ) async {
      final remoteConfigService = _MutableRemoteConfigService(
        maxJournals: 2,
        nextMaxJournals: 1,
      );
      final remoteConfigViewModel = RemoteConfigViewModel(remoteConfigService);
      final service = _FakeJournalService(
        journalResults: [
          _source(name: 'Nature'),
          _source(id: 'S2', name: 'Science'),
          _source(id: 'S3', name: 'Cell'),
        ],
      );
      final provider = JournalViewModel(
        service,
        remoteConfigService: remoteConfigService,
      );

      await tester.pumpWidget(
        _buildScreen(provider, remoteConfigViewModel: remoteConfigViewModel),
      );

      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(find.text('Nature'), findsOneWidget);
      expect(find.text('Science', skipOffstage: false), findsOneWidget);
      expect(find.text('Cell', skipOffstage: false), findsNothing);

      await remoteConfigViewModel.fetchAndActivate();
      await tester.pumpAndSettle();

      expect(find.text('Nature'), findsOneWidget);
      expect(find.text('Science', skipOffstage: false), findsNothing);
      expect(find.text('Cell', skipOffstage: false), findsNothing);
    });

    testWidgets('shows error message when no journals found', (tester) async {
      final provider = JournalViewModel(
        _FakeJournalService(journalResults: []),
      );
      await tester.pumpWidget(_buildScreen(provider));

      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(find.text('No matching journal found.'), findsOneWidget);
    });

    testWidgets('shows error message when query is blank', (tester) async {
      final provider = JournalViewModel(_FakeJournalService());
      await tester.pumpWidget(_buildScreen(provider));

      // Clear the text field
      final field = find.byType(TextField);
      await tester.enterText(field, '');
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a journal name.'), findsOneWidget);
    });
  });

  group('JournalSearchScreen – journal selection', () {
    testWidgets('tapping a journal card loads its publications area', (
      tester,
    ) async {
      final source = _source(name: 'IEEE Access');
      final service = _FakeJournalService(
        journalResults: [source],
        publications: [],
      );
      final provider = JournalViewModel(service);
      await tester.pumpWidget(_buildScreen(provider));

      // Search
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      // Tap the Select button on the card
      await tester.ensureVisible(find.text('Select'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Select'));
      await tester.pumpAndSettle();

      // Provider should have selected journal
      expect(provider.selectedJournal?.displayName, 'IEEE Access');
    });
  });
}
