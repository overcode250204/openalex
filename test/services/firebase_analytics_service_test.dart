import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:openalex/models/auth/app_user.dart';
import 'package:openalex/services/analytics/app_analytics_service.dart';
import 'package:openalex/services/firebase/firebase_analytics_service.dart';

class _MockFirebaseAnalytics extends Mock implements FirebaseAnalytics {}

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

class _LoggedEvent {
  const _LoggedEvent(this.name, this.parameters);

  final String name;
  final Map<String, Object> parameters;
}

void main() {
  late _MockFirebaseAnalytics analytics;
  late _MockFirebaseAuth firebaseAuth;
  late FirebaseAnalyticsService service;
  late List<_LoggedEvent> loggedEvents;

  const user = AppUser(
    uid: 'user-1',
    email: 'researcher@example.com',
    displayName: 'Researcher One',
    photoUrl: null,
    isEmailVerified: true,
  );

  setUp(() {
    analytics = _MockFirebaseAnalytics();
    firebaseAuth = _MockFirebaseAuth();
    loggedEvents = [];

    when(
      () => analytics.setAnalyticsCollectionEnabled(any()),
    ).thenAnswer((_) async {});
    when(
      () => analytics.setUserId(id: any(named: 'id')),
    ).thenAnswer((_) async {});
    when(
      () => analytics.logEvent(
        name: any(named: 'name'),
        parameters: any(named: 'parameters'),
      ),
    ).thenAnswer((invocation) async {
      loggedEvents.add(
        _LoggedEvent(
          invocation.namedArguments[#name] as String,
          Map<String, Object>.from(
            invocation.namedArguments[#parameters] as Map<String, Object>,
          ),
        ),
      );
    });
    when(() => firebaseAuth.currentUser).thenReturn(null);

    service = FirebaseAnalyticsService(
      analytics: analytics,
      firebaseAuth: firebaseAuth,
    );
  });

  test('tracks required assignment event names and parameters', () async {
    await service.logLogin(
      user: user,
      method: AppAnalyticsService.googleAuthMethod,
    );
    await service.logLogout(
      user: user,
      method: AppAnalyticsService.googleAuthMethod,
    );
    await service.logSearchTopic(
      'Artificial Intelligence',
      resultCount: 42,
      searchSource: 'manual',
      topicId: 'T123',
      hasValidTopic: 1,
      filterYearFrom: 2020,
      filterYearTo: 2024,
      openAccessOnly: 1,
      sortOption: 'relevance',
    );
    await service.logViewPublication(
      publicationTitle: 'Reliable Research',
      publicationYear: 2024,
    );
    await service.logViewJournal(
      journalName: 'Journal of Tests',
      journalId: 'S123',
      worksCount: 12,
      citedByCount: 300,
    );
    await service.logViewKeyword(keyword: 'machine learning');
    await service.logExportPdf(
      topic: 'Artificial Intelligence',
      publicationCount: 42,
    );

    expect(loggedEvents.map((event) => event.name), [
      'login',
      'logout',
      'search_topic',
      'view_publication',
      'view_journal',
      'view_keyword',
      'export_pdf',
    ]);

    expect(loggedEvents[0].parameters, {'auth_provider': 'google'});
    expect(loggedEvents[1].parameters, {
      'auth_provider': 'google',
      'had_user': 1,
    });
    expect(loggedEvents[2].parameters, {
      'keyword': 'Artificial Intelligence',
      'result_count': 42,
      'search_source': 'manual',
      'topic_id': 'T123',
      'has_valid_topic': 1,
      'filter_year_from': 2020,
      'filter_year_to': 2024,
      'open_access_only': 1,
      'sort_option': 'relevance',
    });
    expect(loggedEvents[3].parameters, {
      'publication_title': 'Reliable Research',
      'publication_year': 2024,
    });
    expect(loggedEvents[4].parameters, {
      'journal_name': 'Journal of Tests',
      'journal_id': 'S123',
      'works_count': 12,
      'cited_by_count': 300,
    });
    expect(loggedEvents[5].parameters, {'keyword': 'machine learning'});
    expect(loggedEvents[6].parameters, {
      'topic': 'Artificial Intelligence',
      'publication_count': 42,
    });

    verify(() => analytics.setUserId(id: user.uid)).called(1);
  });

  test('skips blank analytics values that would create noisy events', () async {
    await service.logSearchTopic('   ');
    await service.logViewPublication(
      publicationTitle: '   ',
      publicationYear: 2024,
    );
    await service.logViewJournal(journalName: '   ', journalId: 'S123');
    await service.logViewKeyword(keyword: '   ');

    expect(loggedEvents, isEmpty);
  });
}
