import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openalex/widgets/keyword/keyword_autocomplete_search.dart';
import 'package:openalex/models/keyword/openalex_keyword.dart';

void main() {
  Widget buildTestWidget({
    required TextEditingController controller,
    Function(OpenAlexKeyword)? onSelected,
    void Function(String)? onAnalyze,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: KeywordAutocompleteSearch(
          controller: controller,
          onKeywordSelected: onSelected ?? (_) {},
          onAnalyzePressed: onAnalyze ?? (_) {},
        ),
      ),
    );
  }

  group('KeywordAutocompleteSearch Tests', () {
    testWidgets('empty input hides suggestions', (tester) async {
      final controller = TextEditingController();
      await tester.pumpWidget(buildTestWidget(controller: controller));
      expect(find.byType(ListView), findsNothing);
    });

    testWidgets('clear action clears text', (tester) async {
      final controller = TextEditingController();
      await tester.pumpWidget(buildTestWidget(controller: controller));
      
      await tester.enterText(find.byType(TextField), 'test');
      await tester.pumpAndSettle();
      
      final clearButton = find.byIcon(Icons.clear);
      expect(clearButton, findsOneWidget);
      await tester.tap(clearButton);
      await tester.pumpAndSettle();
      
      expect(controller.text, isEmpty);
    });
  });
}

