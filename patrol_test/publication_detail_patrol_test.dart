import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openalex/utils/app_keys.dart';
import 'package:patrol/patrol.dart';

import 'patrol_test_harness.dart';

const _config = PatrolTesterConfig(
  settlePolicy: SettlePolicy.noSettle,
  visibleTimeout: Duration(seconds: 10),
  existsTimeout: Duration(seconds: 10),
  printLogs: true,
);

Future<void> _launchApp(PatrolIntegrationTester $) async {
  await launchPatrolApp($);
}

Future<void> _waitFor(
  PatrolIntegrationTester $,
  Finder finder, {
  Duration timeout = const Duration(seconds: 15),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await $.pump(const Duration(milliseconds: 500));
    if (finder.evaluate().isNotEmpty) return;
  }
  expect(finder, findsWidgets);
}

Future<void> _ensureVisible(PatrolIntegrationTester $, Finder finder) async {
  await _waitFor($, finder);
  await $.tester.ensureVisible(finder);
  await $.pump(const Duration(milliseconds: 250));
}

Finder _byKeyPrefix(String prefix) {
  return find.byWidgetPredicate((widget) {
    final key = widget.key;
    return key is ValueKey<String> && key.value.startsWith(prefix);
  });
}

String _firstVisibleTextInside(Finder finder) {
  final texts = find
      .descendant(of: finder.first, matching: find.byType(Text))
      .evaluate()
      .map((element) => (element.widget as Text).data?.trim())
      .whereType<String>()
      .where((value) => value.isNotEmpty)
      .toList();
  expect(texts, isNotEmpty);
  return texts.first;
}

void main() {
  patrolTest(
    'opens Publication Detail from publication results',
    ($) async {
      await _launchApp($);

      await $(
        find.byKey(AppKeys.topicSearchInput),
      ).enterText('machine learning');
      await $(find.byKey(AppKeys.topicSearchButton)).tap();
      await _waitFor($, find.byKey(AppKeys.publicationList));

      final publicationItem = _byKeyPrefix('publication_result_item_');
      await _waitFor($, publicationItem);
      final listTitle = _firstVisibleTextInside(publicationItem);

      await $(publicationItem.first).tap();
      await _waitFor($, find.byKey(AppKeys.publicationDetailScreen));
      await _waitFor($, find.byKey(AppKeys.publicationDetailTitle));

      expect(find.text(listTitle), findsWidgets);
      expect(find.byKey(AppKeys.publicationDetailAuthors), findsOneWidget);
      expect(find.byKey(AppKeys.publicationDetailYear), findsOneWidget);
      expect(find.byKey(AppKeys.publicationDetailSource), findsOneWidget);

      await _ensureVisible($, find.byKey(AppKeys.publicationDetailAbstract));
      expect(find.byKey(AppKeys.publicationDetailAbstract), findsOneWidget);
      expect($('Abstract'), findsOneWidget);
      expect($('Cited'), findsOneWidget);
    },
    config: _config,
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
