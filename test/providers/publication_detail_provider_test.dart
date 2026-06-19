import 'package:flutter_test/flutter_test.dart';
import 'package:openalex/models/publication.dart';
import 'package:openalex/providers/publication_detail_provider.dart';
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

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('PublicationDetailProvider', () {
    test('starts in idle state with no publication', () {
      final provider = PublicationDetailProvider(
        service: _FakeDetailService(),
      );

      expect(provider.state, DetailState.idle);
      expect(provider.publication, isNull);
      expect(provider.error, isNull);
    });

    test('transitions to loading then success on valid workId', () async {
      final service = _FakeDetailService(result: _samplePublication());
      final provider = PublicationDetailProvider(service: service);

      final states = <DetailState>[];
      provider.addListener(() => states.add(provider.state));

      await provider.loadDetail('W1');

      expect(service.requestedId, 'W1');
      expect(states, [DetailState.loading, DetailState.success]);
      expect(provider.state, DetailState.success);
      expect(provider.publication?.title, 'Detail Paper');
      expect(provider.error, isNull);
    });

    test('transitions to error state when service returns null', () async {
      final provider = PublicationDetailProvider(
        service: _FakeDetailService(result: null),
      );

      final states = <DetailState>[];
      provider.addListener(() => states.add(provider.state));

      await provider.loadDetail('INVALID_ID');

      expect(states, [DetailState.loading, DetailState.error]);
      expect(provider.state, DetailState.error);
      expect(provider.publication, isNull);
      expect(provider.error, isNotNull);
      expect(provider.error, isNotEmpty);
    });

    test('clears previous publication before loading new one', () async {
      final service = _FakeDetailService(result: _samplePublication());
      final provider = PublicationDetailProvider(service: service);

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
      final provider = PublicationDetailProvider(
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
