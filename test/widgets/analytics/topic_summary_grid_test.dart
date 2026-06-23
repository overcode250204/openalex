import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openalex/widgets/analytics/topic_summary_grid.dart';

Widget _subject({
  bool loading = false,
  String topAuthor = 'Ada Lovelace',
  String topJournal = 'Journal of Computing',
  String paper = 'A Highly Influential Paper',
  VoidCallback? onPaperTap,
}) {
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(8),
        child: TopicSummaryGrid(
          isLoading: loading,
          totalPublications: '1.2k',
          averageCitations: '12.5',
          mostActiveYear: '2024',
          topAuthor: topAuthor,
          topJournal: topJournal,
          mostInfluentialPaper: paper,
          influentialPaperDetails: '120 citations • 2024',
          onInfluentialPaperTap: onPaperTap,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('renders all six topic summary cards', (tester) async {
    await tester.pumpWidget(_subject());

    for (final label in [
      'Total Publications',
      'Average Citations',
      'Most Active Year',
      'Top Author',
      'Top Journal',
      'Most Influential Paper',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('1.2k'), findsOneWidget);
    expect(find.text('12.5'), findsOneWidget);
  });

  testWidgets('renders a loading indicator in every card', (tester) async {
    await tester.pumpWidget(_subject(loading: true));

    expect(
      find.byKey(const Key('summary_card_loading')),
      findsNWidgets(6),
    );
  });

  testWidgets('most influential paper card is tappable', (tester) async {
    var tapped = false;
    await tester.pumpWidget(_subject(onPaperTap: () => tapped = true));

    await tester.tap(find.text('A Highly Influential Paper'));

    expect(tapped, isTrue);
  });

  testWidgets('long values do not overflow on a small mobile screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _subject(
        topAuthor: 'An Extremely Long Author Name That Must Stay In Its Card',
        topJournal:
            'International Journal of Very Long Interdisciplinary Research',
        paper:
            'A Very Long and Detailed Paper Title That Cannot Overflow Its Card',
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('topic_summary_grid')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
