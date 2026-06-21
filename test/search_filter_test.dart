import 'package:flutter_test/flutter_test.dart';
import 'package:openalex/models/search_filter.dart';

void main() {
  group('SearchFilter', () {
    test('builds default OpenAlex query parameters', () {
      final params = const SearchFilter().toQueryParams(
        'artificial intelligence',
        List.empty(),
      );

      expect(params, {
        'search': 'artificial intelligence',
        'per-page': '50',
        'mailto': 'trandinhbao222@gmail.com',
      });
      expect(params, isNot(contains('filter')));
      expect(params, isNot(contains('sort')));
    });

    test('builds combined filter and sort query parameters', () {
      final params = const SearchFilter(
        yearFrom: 2020,
        yearTo: 2024,
        isOpenAccess: true,
        language: 'en',
        documentType: DocumentType.article,
        sortOption: SortOption.citedDesc,
      ).toQueryParams('machine learning', List.empty());

      expect(params['search'], 'machine learning');
      expect(params['per-page'], '50');
      expect(
        params['filter'],
        'publication_year:2020-2024,is_oa:true,language:en,type:article',
      );
      expect(params['sort'], 'cited_by_count:desc');
    });

    test('builds one-sided year filters and ascending sorts', () {
      final fromOnly = const SearchFilter(
        yearFrom: 2020,
        sortOption: SortOption.yearAsc,
      ).toQueryParams('ai', List.empty());
      final toOnly = const SearchFilter(
        yearTo: 2024,
        sortOption: SortOption.yearDesc,
      ).toQueryParams('ai', List.empty());

      expect(fromOnly['filter'], 'publication_year:>2020');
      expect(fromOnly['sort'], 'publication_date:asc');
      expect(toOnly['filter'], 'publication_year:<2024');
      expect(toOnly['sort'], 'publication_date:desc');
    });

    test('copyWith updates selected fields and can clear open access', () {
      final filter = const SearchFilter(
        yearFrom: 2020,
        isOpenAccess: true,
        documentType: DocumentType.article,
      );

      final updated = filter.copyWith(
        yearTo: 2024,
        clearOpenAccess: true,
        sortOption: SortOption.citedAsc,
      );

      expect(updated.yearFrom, 2020);
      expect(updated.yearTo, 2024);
      expect(updated.isOpenAccess, isNull);
      expect(updated.documentType, DocumentType.article);
      expect(updated.sortOption, SortOption.citedAsc);
    });
  });
}
