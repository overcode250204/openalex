import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openalex/main.dart';
import 'package:openalex/utils/app_keys.dart';
import 'package:patrol/patrol.dart';

import '../test/fakes/fake_auth_service.dart';

const _config = PatrolTesterConfig(
  settlePolicy: SettlePolicy.noSettle,
  visibleTimeout: Duration(seconds: 35),
  existsTimeout: Duration(seconds: 35),
);

Future<void> _launchApp(PatrolIntegrationTester $) async {
  await $.pumpWidgetAndSettle(
    MyApp(authService: FakeAuthService(initialUser: fakeUser())),
  );
}

Future<void> _waitFor(
  PatrolIntegrationTester $,
  Finder finder, {
  Duration timeout = const Duration(seconds: 45),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await $.pump(const Duration(milliseconds: 500));
    if (finder.evaluate().isNotEmpty) return;
  }
  expect(finder, findsWidgets);
}

Finder _byKeyPrefix(String prefix) {
  return find.byWidgetPredicate((widget) {
    final key = widget.key;
    return key is ValueKey<String> && key.value.startsWith(prefix);
  });
}

List<String> _visibleTextsInside(Finder finder) {
  return find
      .descendant(of: finder.first, matching: find.byType(Text))
      .evaluate()
      .map((element) => (element.widget as Text).data?.trim())
      .whereType<String>()
      .where((value) => value.isNotEmpty)
      .toList();
}

void main() {
  patrolTest(
    'searches a topic and verifies publication results',
    ($) async {
      await _launchApp($);

      expect(find.byKey(AppKeys.topicSearchInput), findsOneWidget);
      await $(
        find.byKey(AppKeys.topicSearchInput),
      ).enterText('machine learning');
      await $(find.byKey(AppKeys.topicSearchButton)).tap();

      await _waitFor($, find.byKey(AppKeys.publicationResultsList));
      expect(find.byKey(AppKeys.emptySearchState), findsNothing);
      expect(find.byKey(AppKeys.searchErrorState), findsNothing);

      final resultItem = _byKeyPrefix('publication_result_item_');
      await _waitFor($, resultItem);

      final texts = _visibleTextsInside(resultItem);
      expect(texts.length, greaterThanOrEqualTo(2));
      expect(texts.first.length, greaterThan(8));
      expect(
        texts.any(
          (text) => RegExp(r'(19|20)\d{2}|Unknown year').hasMatch(text),
        ),
        isTrue,
      );
      expect(texts.skip(1).any((text) => text.length > 3), isTrue);
    },
    config: _config,
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
