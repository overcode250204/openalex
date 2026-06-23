import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openalex/models/keyword/keyword_overview.dart';
import 'package:openalex/widgets/keyword/keyword_top_n_selector.dart';
import 'package:openalex/widgets/keyword/most_frequent_keywords_chart.dart';
import 'package:openalex/widgets/keyword/trending_keywords_chart.dart';

void main() {
  final keywords = List.generate(20, _keyword);

  testWidgets('renders two independent selectors defaulting to Top 5', (
    tester,
  ) async {
    await tester.pumpWidget(_TopNHarness(keywords: keywords));

    expect(
      find.byKey(const Key('most_frequent_top_n_selector')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('trending_top_n_selector')), findsOneWidget);
    expect(_selector(tester, 'most_frequent_top_n_selector').selectedTopN, 5);
    expect(_selector(tester, 'trending_top_n_selector').selectedTopN, 5);
    expect(_frequentRows(), findsNWidgets(5));
    expect(_trendingRows(), findsNWidgets(5));
    expect(find.text('All'), findsNothing);
  });

  testWidgets('Top 10 changes only Most Frequent Keywords', (tester) async {
    await tester.pumpWidget(_TopNHarness(keywords: keywords));

    await _selectTopN(tester, 'most_frequent_top_n_selector', 10);

    expect(_frequentRows(), findsNWidgets(10));
    expect(_trendingRows(), findsNWidgets(5));
    expect(_selector(tester, 'most_frequent_top_n_selector').selectedTopN, 10);
    expect(_selector(tester, 'trending_top_n_selector').selectedTopN, 5);
  });

  testWidgets('Top 15 limits Trending Keywords to 15', (tester) async {
    await tester.pumpWidget(_TopNHarness(keywords: keywords));

    await _selectTopN(tester, 'trending_top_n_selector', 15);

    expect(_trendingRows(), findsNWidgets(15));
    expect(_frequentRows(), findsNWidgets(5));
  });

  testWidgets('Top 10 safely shows three available keywords', (tester) async {
    await tester.pumpWidget(_TopNHarness(keywords: keywords.take(3).toList()));

    await _selectTopN(tester, 'most_frequent_top_n_selector', 10);

    expect(_frequentRows(), findsNWidgets(3));
    expect(find.text('Showing 3 available keywords.'), findsWidgets);
  });

  testWidgets('sections remain usable at mobile width', (tester) async {
    tester.view.physicalSize = const Size(320, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_TopNHarness(keywords: keywords));

    expect(tester.takeException(), isNull);
    expect(
      find.byKey(const Key('most_frequent_keywords_list')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('trending_keywords_list')), findsOneWidget);
  });
}

KeywordOverview _keyword(int index) => KeywordOverview(
  id: 'K$index',
  name: 'Keyword $index',
  currentPeriodCount: 1000 - index,
  previousPeriodCount: 100 + index,
  growthRate: (20 - index).toDouble(),
  hotScore: 1,
  status: KeywordStatus.stable,
);

KeywordTopNSelector _selector(WidgetTester tester, String key) =>
    tester.widget<KeywordTopNSelector>(find.byKey(Key(key)));

Finder _frequentRows() => find.byWidgetPredicate(
  (widget) =>
      widget.key is ValueKey<String> &&
      (widget.key! as ValueKey<String>).value.startsWith(
        'most_frequent_keyword_',
      ),
);

Finder _trendingRows() => find.byWidgetPredicate(
  (widget) =>
      widget.key is ValueKey<String> &&
      (widget.key! as ValueKey<String>).value.startsWith('trending_keyword_'),
);

Future<void> _selectTopN(
  WidgetTester tester,
  String selectorKey,
  int value,
) async {
  await tester.tap(find.byKey(Key(selectorKey)));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Top $value').last);
  await tester.pumpAndSettle();
}

class _TopNHarness extends StatefulWidget {
  final List<KeywordOverview> keywords;

  const _TopNHarness({required this.keywords});

  @override
  State<_TopNHarness> createState() => _TopNHarnessState();
}

class _TopNHarnessState extends State<_TopNHarness> {
  int mostFrequentTopN = 5;
  int trendingTopN = 5;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: Column(
            children: [
              MostFrequentKeywordsChart(
                keywords: widget.keywords,
                selectedTopN: mostFrequentTopN,
                onTopNChanged: (value) =>
                    setState(() => mostFrequentTopN = value),
                onSelected: (_) {},
              ),
              TrendingKeywordsChart(
                keywords: widget.keywords,
                selectedTopN: trendingTopN,
                onTopNChanged: (value) => setState(() => trendingTopN = value),
                onSelected: (_) {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}
