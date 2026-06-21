import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openalex/widgets/top_selector_dropdown.dart';

void main() {
  group('TopSelectorDropdown', () {
    testWidgets('renders default options and selected value', (tester) async {
      int? selected;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TopSelectorDropdown(value: 5, onChanged: (v) => selected = v),
          ),
        ),
      );

      // Current selection should display 'Top 5'
      expect(find.text('Top 5'), findsOneWidget);
      expect(selected, isNull); // Not changed yet
    });

    testWidgets('renders All label for null option', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TopSelectorDropdown(value: null, onChanged: (_) {}),
          ),
        ),
      );

      expect(find.text('All'), findsOneWidget);
    });

    testWidgets('calls onChanged when an option is selected', (tester) async {
      int? changedValue = 5;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => TopSelectorDropdown(
                value: changedValue,
                onChanged: (v) => setState(() => changedValue = v),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Top 5'));
      await tester.pumpAndSettle();

      // Find and tap the 'Top 10' option in the dropdown
      await tester.tap(find.text('Top 10').last);
      await tester.pumpAndSettle();

      expect(changedValue, 10);
    });

    testWidgets('renders custom options', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TopSelectorDropdown(
              value: 3,
              onChanged: (_) {},
              options: const [3, 6, null],
            ),
          ),
        ),
      );

      expect(find.text('Top 3'), findsOneWidget);
    });
  });
}
