import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openalex/models/journal/journal_publication.dart';
import 'package:openalex/models/journal/journal_source.dart';
import 'package:openalex/providers/journal_search_provider.dart';
import 'package:openalex/screens/journal/journal_search_screen.dart';
import 'package:openalex/services/openalex_journal_service.dart';
import 'package:provider/provider.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

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
      String sourceId) async {
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

Widget _buildScreen(JournalSearchProvider provider) {
  return ChangeNotifierProvider.value(
    value: provider,
    child: const MaterialApp(home: JournalSearchScreen()),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('JournalSearchScreen initial state', () {
    testWidgets('renders search field pre-filled with IEEE Access',
        (tester) async {
      final provider =
          JournalSearchProvider(_FakeJournalService(journalResults: []));
      await tester.pumpWidget(_buildScreen(provider));

      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);

      final tf = tester.widget<TextField>(textField);
      expect(tf.controller?.text, 'IEEE Access');
    });

    testWidgets('renders Search Journal label', (tester) async {
      final provider = JournalSearchProvider(_FakeJournalService());
      await tester.pumpWidget(_buildScreen(provider));

      expect(find.text('Journal Search'), findsOneWidget);
    });
  });

  group('JournalSearchScreen – journal list', () {
    testWidgets('shows journal cards after successful search', (tester) async {
      final service = _FakeJournalService(
        journalResults: [_source(name: 'Nature'), _source(id: 'S2', name: 'Science')],
      );
      final provider = JournalSearchProvider(service);
      await tester.pumpWidget(_buildScreen(provider));

      // Trigger search
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();
      print('Journals after search: ${provider.journals.length}, error: ${provider.errorMessage}');

      expect(find.text('Nature'), findsOneWidget);
      expect(find.text('Science', skipOffstage: false), findsOneWidget);
    });

    testWidgets('shows error message when no journals found', (tester) async {
      final provider = JournalSearchProvider(
        _FakeJournalService(journalResults: []),
      );
      await tester.pumpWidget(_buildScreen(provider));

      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(find.text('No matching journal found.'), findsOneWidget);
    });

    testWidgets('shows error message when query is blank', (tester) async {
      final provider = JournalSearchProvider(_FakeJournalService());
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
    testWidgets('tapping a journal card loads its publications area',
        (tester) async {
      final source = _source(name: 'IEEE Access');
      final service = _FakeJournalService(
        journalResults: [source],
        publications: [],
      );
      final provider = JournalSearchProvider(service);
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
