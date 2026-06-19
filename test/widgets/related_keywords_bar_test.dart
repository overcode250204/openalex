import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openalex/models/publication.dart';
import 'package:openalex/providers/publication_provider.dart';
import 'package:openalex/services/openalex_service.dart';
import 'package:openalex/services/suggestion_service.dart';
import 'package:openalex/widgets/related_keyworks_bar.dart';
import 'package:provider/provider.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class _FakeOpenAlexService extends OpenAlexService {
  @override
  Future<(int, List<Publication>)> searchPublications({
    required String keyword,
    int perPage = 50,
    String sort = 'cited_by_count:desc',
    List<String>? topicIds,
  }) async => (0, <Publication>[]);
}

class _FakeSuggestionService extends SuggestionService {
  final List<String> keywords;

  _FakeSuggestionService({this.keywords = const []});

  @override
  Future<List<String>> fetchRelatedKeywords(String keyword) async {
    return keywords;
  }
}

Widget _buildWithProvider({
  required Widget child,
  required PublicationProvider provider,
}) {
  return ChangeNotifierProvider.value(
    value: provider,
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('RelatedKeywordsBar', () {
    testWidgets('shows nothing when relatedKeywords is empty', (tester) async {
      final provider = PublicationProvider(
        _FakeOpenAlexService(),
        suggestionService: _FakeSuggestionService(keywords: []),
      );

      await tester.pumpWidget(
        _buildWithProvider(
          child: RelatedKeywordsBar(onKeywordTap: (_) {}),
          provider: provider,
        ),
      );

      expect(find.text('Related Topic'), findsNothing);
    });

    testWidgets('renders chip for each related keyword', (tester) async {
      final suggestionService = _FakeSuggestionService(
        keywords: ['Machine Learning', 'Deep Learning'],
      );
      final provider = PublicationProvider(
        _FakeOpenAlexService(),
        suggestionService: suggestionService,
      );

      // Trigger keyword loading so relatedKeywords gets populated
      await provider.searchPublications(keyword: 'AI');

      await tester.pumpWidget(
        _buildWithProvider(
          child: RelatedKeywordsBar(onKeywordTap: (_) {}),
          provider: provider,
        ),
      );
      await tester.pump();

      expect(find.text('Related Topic'), findsOneWidget);
      expect(find.text('Machine Learning'), findsOneWidget);
      expect(find.text('Deep Learning'), findsOneWidget);
    });

    testWidgets('calls onKeywordTap with correct keyword on chip press', (
      tester,
    ) async {
      final suggestionService = _FakeSuggestionService(
        keywords: ['Neural Networks'],
      );
      final provider = PublicationProvider(
        _FakeOpenAlexService(),
        suggestionService: suggestionService,
      );
      await provider.searchPublications(keyword: 'AI');

      String? tappedKeyword;

      await tester.pumpWidget(
        _buildWithProvider(
          child: RelatedKeywordsBar(onKeywordTap: (k) => tappedKeyword = k),
          provider: provider,
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Neural Networks'));
      await tester.pump();

      expect(tappedKeyword, 'Neural Networks');
    });
  });
}
