import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openalex/models/journal/journal_source.dart';
import 'package:openalex/screens/journal/journals_screen.dart';
import 'package:openalex/services/openalex_journal_service.dart';
import 'package:openalex/viewmodels/journal_view_model.dart';
import 'package:provider/provider.dart';

class _FakeJournalService extends OpenAlexJournalService {
  final Future<List<JournalSource>> Function() onFetch;

  _FakeJournalService(this.onFetch);

  @override
  Future<List<JournalSource>> fetchTopJournals({int perPage = 20}) =>
      onFetch();

  @override
  Future<List<JournalSource>> searchJournals(
    String query, {
    int perPage = 20,
  }) async => onFetch();
}

Widget _wrap(JournalViewModel viewModel) {
  return ChangeNotifierProvider<JournalViewModel>.value(
    value: viewModel,
    child: const MaterialApp(home: JournalsScreen()),
  );
}

JournalViewModel _vm(Future<List<JournalSource>> Function() onFetch) {
  return JournalViewModel(_FakeJournalService(onFetch));
}

void main() {
  testWidgets('shows loading state while journals are being fetched', (
    tester,
  ) async {
    final completer = Completer<List<JournalSource>>();
    final viewModel = _vm(() => completer.future);

    await tester.pumpWidget(_wrap(viewModel));
    unawaited(viewModel.loadTopJournals());
    await tester.pump();

    expect(find.text('Loading journals...'), findsOneWidget);
    completer.complete([]);
  });

  testWidgets('shows error state when fetch fails', (tester) async {
    final viewModel = _vm(() async => throw Exception('network error'));

    await tester.pumpWidget(_wrap(viewModel));
    await viewModel.loadTopJournals();
    await tester.pump();

    expect(
      find.text('Failed to load journals. Please try again.'),
      findsOneWidget,
    );
  });

  testWidgets('shows empty state when journal list is empty', (tester) async {
    final viewModel = _vm(() async => []);

    await tester.pumpWidget(_wrap(viewModel));
    await viewModel.loadTopJournals();
    await tester.pump();

    expect(find.text('No journals available.'), findsOneWidget);
  });

  testWidgets('shows journal list on success', (tester) async {
    final journals = [
      const JournalSource(
        id: 'S1',
        displayName: 'Nature',
        worksCount: 1000,
        citedByCount: 50000,
      ),
      const JournalSource(
        id: 'S2',
        displayName: 'Science',
        worksCount: 800,
        citedByCount: 40000,
      ),
    ];
    final viewModel = _vm(() async => journals);

    await tester.pumpWidget(_wrap(viewModel));
    await viewModel.loadTopJournals();
    await tester.pump();

    expect(find.text('Top Journals'), findsOneWidget);
    expect(find.text('Nature'), findsWidgets);
    expect(find.text('Science'), findsWidgets);
  });

  testWidgets('shows "No journals found" when search returns empty', (
    tester,
  ) async {
    final viewModel = _vm(() async => []);

    await tester.pumpWidget(_wrap(viewModel));
    await viewModel.search('xyz unknown journal');
    await tester.pump();

    expect(
      find.text('No journals found for "xyz unknown journal".'),
      findsOneWidget,
    );
  });
}
