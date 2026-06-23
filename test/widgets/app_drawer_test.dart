import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openalex/models/app/app_page.dart';
import 'package:openalex/widgets/app_drawer.dart';

void main() {
  Widget buildDrawer({
    AppPage selectedPage = AppPage.home,
    Function(AppPage)? onPageSelected,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: AppDrawer(
          selectedPage: selectedPage,
          onPageSelected: onPageSelected ?? (_) {},
        ),
      ),
    );
  }

  group('AppDrawer render', () {
    testWidgets('displays app logo and user profile footer', (tester) async {
      await tester.pumpWidget(buildDrawer());

      expect(find.text('openalex'), findsOneWidget);
      expect(find.text('Alex Researcher'), findsOneWidget);
      expect(find.text('researcher@example.com'), findsOneWidget);
    });

    testWidgets('renders all navigation group headers', (tester) async {
      await tester.pumpWidget(buildDrawer());

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Journal'), findsOneWidget);
      expect(find.text('Keywords'), findsOneWidget);
    });

    testWidgets('Home group is expanded and shows nav items', (tester) async {
      await tester.pumpWidget(buildDrawer());

      expect(find.text('Search Topic'), findsOneWidget);
    });
  });

  group('AppDrawer navigation callbacks', () {
    testWidgets('calls onPageSelected when a nav item is tapped', (
      tester,
    ) async {
      AppPage? selected;
      await tester.pumpWidget(
        buildDrawer(onPageSelected: (page) => selected = page),
      );

      await tester.tap(find.text('Search Topic'));
      await tester.pump();

      expect(selected, AppPage.searchTopic);
    });

    testWidgets('Search Topic item is active when selectedPage is home', (
      tester,
    ) async {
      await tester.pumpWidget(buildDrawer(selectedPage: AppPage.home));

      // The Search Topic tile should have bold styling when selected
      final tile = tester.widget<ListTile>(
        find
            .ancestor(
              of: find.text('Search Topic'),
              matching: find.byType(ListTile),
            )
            .first,
      );
      final style = (tile.title as Text).style;
      expect(style?.fontWeight, FontWeight.bold);
    });
  });

  group('AppDrawer expansion tiles', () {
    testWidgets('Journal group expands on tap and shows subitems', (
      tester,
    ) async {
      await tester.pumpWidget(buildDrawer());

      await tester.tap(find.text('Journal'));
      await tester.pumpAndSettle();

      expect(find.text('Search Journal'), findsOneWidget);
    });

    testWidgets('Keywords group expands on tap', (tester) async {
      await tester.pumpWidget(buildDrawer());

      await tester.tap(find.text('Keywords'));
      await tester.pumpAndSettle();

      expect(find.text('Trends'), findsOneWidget);
    });

    testWidgets('Journal group is pre-expanded when selectedPage is journals', (
      tester,
    ) async {
      await tester.pumpWidget(buildDrawer(selectedPage: AppPage.journals));
      await tester.pumpAndSettle();

      expect(find.text('Search Journal'), findsOneWidget);
    });
  });
}
