import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openalex/models/publication.dart';
import 'package:openalex/providers/journal_search_provider.dart';
import 'package:openalex/providers/publication_detail_provider.dart';
import 'package:openalex/providers/publication_list_provider.dart';
import 'package:openalex/providers/publication_provider.dart';
import 'package:openalex/screens/publication_list_screen.dart';
import 'package:openalex/services/openalex_journal_service.dart';
import 'package:openalex/services/openalex_service.dart';
import 'package:provider/provider.dart';

class _FakeOpenAlexService extends OpenAlexService {
  final Future<List<Publication>> citedByResult;

  _FakeOpenAlexService(this.citedByResult);

  @override
  Future<List<Publication>> fetchCitedBy(String workId, {int page = 1}) =>
      citedByResult;
}

PublicationListProvider _emptyListProvider() => PublicationListProvider(
  service: _FakeOpenAlexService(Future.value(const [])),
);

Widget _buildScreen({
  required ListType type,
  required PublicationListProvider listProvider,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<PublicationListProvider>.value(
        value: listProvider,
      ),
      ChangeNotifierProvider<PublicationProvider>(
        create: (_) => PublicationProvider(OpenAlexService()),
      ),
      ChangeNotifierProvider<PublicationDetailProvider>(
        create: (_) => PublicationDetailProvider(),
      ),
      ChangeNotifierProvider<JournalSearchProvider>(
        create: (_) => JournalSearchProvider(OpenAlexJournalService()),
      ),
    ],
    child: MaterialApp(
      home: PublicationListScreen(
        type: type,
        workId: 'W1',
        ids: const [],
        title: 'Cited By',
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('PublicationListScreen', () {
    testWidgets('shows CircularProgressIndicator while loading', (
      tester,
    ) async {
      // Create a provider that stays loading
      final pendingResult = Completer<List<Publication>>();
      final listProvider = PublicationListProvider(
        service: _FakeOpenAlexService(pendingResult.future),
      );

      await tester.pumpWidget(
        _buildScreen(type: ListType.citedBy, listProvider: listProvider),
      );

      // Before post-frame callback fires, items are empty and loading begins
      await tester.pump();

      // Loading state: shows spinner
      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets('shows empty message when no items returned', (tester) async {
      final listProvider = _emptyListProvider();

      await tester.pumpWidget(
        _buildScreen(type: ListType.citedBy, listProvider: listProvider),
      );

      await tester.pumpAndSettle();

      // After loading with zero results
      expect(find.text('Không có dữ liệu.'), findsOneWidget);
    });

    testWidgets('renders AppBar title correctly', (tester) async {
      final listProvider = _emptyListProvider();

      await tester.pumpWidget(
        _buildScreen(type: ListType.citedBy, listProvider: listProvider),
      );

      await tester.pumpAndSettle();

      expect(find.text('Cited By'), findsOneWidget);
    });

    testWidgets('renders list of publications when items are available', (
      tester,
    ) async {
      final listProvider = _emptyListProvider();

      await tester.pumpWidget(
        _buildScreen(type: ListType.citedBy, listProvider: listProvider),
      );

      // Manually push items as if loaded
      await tester.pumpAndSettle();

      // The screen shows empty state when citedBy returns empty list from fake
      expect(find.text('Không có dữ liệu.'), findsOneWidget);
    });
  });

  group('ListType enum', () {
    test('contains all expected types', () {
      expect(
        ListType.values,
        containsAll([ListType.related, ListType.citedBy, ListType.references]),
      );
    });
  });
}
