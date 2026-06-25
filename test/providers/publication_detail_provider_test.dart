import 'package:flutter_test/flutter_test.dart';
import 'package:openalex/models/auth/app_user.dart';
import 'package:openalex/models/publication/publication.dart';
import 'package:openalex/services/analytics/app_analytics_service.dart';
import 'package:openalex/viewmodels/publication_detail_view_model.dart';
import 'package:openalex/services/openalex_service.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class _FakeDetailService extends OpenAlexService {
  final Publication? result;
  String? requestedId;

  _FakeDetailService({this.result});

  @override
  Future<Publication?> fetchDetail(String workId) async {
    requestedId = workId;
    return result;
  }
}

Publication _samplePublication() {
  return Publication(
    id: 'https://openalex.org/W1',
    title: 'Detail Paper',
    publicationYear: 2024,
    citedByCount: 42,
    journalName: 'Test Journal',
    doi: '10.1000/test',
    abstractText: 'A test abstract.',
    authors: ['Ada Lovelace'],
    relatedWorkIds: ['W2'],
    referencedWorkIds: ['W3'],
    oaUrl: 'https://example.org/pdf',
  );
}

class _RecordingAnalyticsService implements AppAnalyticsService {
  final viewPublicationEvents = <({String title, int? year})>[];

  @override
  Future<void> clearUser() async {}

  @override
  Future<void> logLogin({
    required AppUser user,
    required String method,
  }) async {}

  @override
  Future<void> logLogout({
    required AppUser? user,
    required String method,
  }) async {}

  @override
  Future<void> logSearchTopic(
    String keyword, {
    int? resultCount,
    String? searchSource,
    String? topicId,
    int? hasValidTopic,
    int? filterYearFrom,
    int? filterYearTo,
    int? openAccessOnly,
    String? sortOption,
  }) async {}

  @override
  Future<void> logViewKeyword({required String keyword}) async {}

  @override
  Future<void> logViewPublication({
    required String publicationTitle,
    required int? publicationYear,
  }) async {
    viewPublicationEvents.add((
      title: publicationTitle.trim(),
      year: publicationYear,
    ));
  }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('PublicationDetailViewModel', () {
    test('starts in idle state with no publication', () {
      final provider = PublicationDetailViewModel(
        service: _FakeDetailService(),
      );

      expect(provider.state, DetailState.idle);
      expect(provider.publication, isNull);
      expect(provider.error, isNull);
    });

    test('transitions to loading then success on valid workId', () async {
      final service = _FakeDetailService(result: _samplePublication());
      final provider = PublicationDetailViewModel(service: service);

      final states = <DetailState>[];
      provider.addListener(() => states.add(provider.state));

      await provider.loadDetail('W1');

      expect(service.requestedId, 'W1');
      expect(states, [DetailState.loading, DetailState.success]);
      expect(provider.state, DetailState.success);
      expect(provider.publication?.title, 'Detail Paper');
      expect(provider.error, isNull);
    });

    test('logs view_publication once after loading a publication', () async {
      final analytics = _RecordingAnalyticsService();
      final service = _FakeDetailService(result: _samplePublication());
      final provider = PublicationDetailViewModel(
        service: service,
        analyticsService: analytics,
      );

      await provider.loadDetail('W1');
      await provider.loadDetail('W1');

      expect(analytics.viewPublicationEvents, hasLength(1));
      expect(analytics.viewPublicationEvents.single.title, 'Detail Paper');
      expect(analytics.viewPublicationEvents.single.year, 2024);
    });

    test('transitions to error state when service returns null', () async {
      final analytics = _RecordingAnalyticsService();
      final provider = PublicationDetailViewModel(
        service: _FakeDetailService(result: null),
        analyticsService: analytics,
      );

      final states = <DetailState>[];
      provider.addListener(() => states.add(provider.state));

      await provider.loadDetail('INVALID_ID');

      expect(states, [DetailState.loading, DetailState.error]);
      expect(provider.state, DetailState.error);
      expect(provider.publication, isNull);
      expect(provider.error, isNotNull);
      expect(provider.error, isNotEmpty);
      expect(analytics.viewPublicationEvents, isEmpty);
    });

    test('clears previous publication before loading new one', () async {
      final service = _FakeDetailService(result: _samplePublication());
      final provider = PublicationDetailViewModel(service: service);

      await provider.loadDetail('W1');
      expect(provider.publication, isNotNull);

      // On second load, publication is cleared before result arrives
      final cleared = <bool>[];
      provider.addListener(() {
        if (provider.state == DetailState.loading) {
          cleared.add(provider.publication == null);
        }
      });

      await provider.loadDetail('W2');
      expect(cleared, [true]);
    });

    test('notifies listeners on state transitions', () async {
      final provider = PublicationDetailViewModel(
        service: _FakeDetailService(result: _samplePublication()),
      );
      var notifyCount = 0;
      provider.addListener(() => notifyCount++);

      await provider.loadDetail('W1');

      // 2 notifications: loading + success
      expect(notifyCount, 2);
    });
  });
}
