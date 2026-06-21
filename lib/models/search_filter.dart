enum SortOption { relevance, citedDesc, citedAsc, yearDesc, yearAsc }

enum DocumentType { all, article, preprint, book, dataset }

class SearchFilter {
  final int? yearFrom;
  final int? yearTo;
  final bool? isOpenAccess;
  final String? language;
  final DocumentType documentType;
  final SortOption sortOption;

  const SearchFilter({
    this.yearFrom,
    this.yearTo,
    this.isOpenAccess,
    this.language,
    this.documentType = DocumentType.all,
    this.sortOption = SortOption.relevance,
  });

  SearchFilter copyWith({
    int? yearFrom,
    int? yearTo,
    bool? isOpenAccess,
    bool clearOpenAccess = false,
    String? language,
    DocumentType? documentType,
    SortOption? sortOption,
  }) {
    return SearchFilter(
      yearFrom: yearFrom ?? this.yearFrom,
      yearTo: yearTo ?? this.yearTo,
      isOpenAccess: clearOpenAccess
          ? null
          : (isOpenAccess ?? this.isOpenAccess),
      language: language,
      documentType: documentType ?? this.documentType,
      sortOption: sortOption ?? this.sortOption,
    );
  }

  Map<String, String> toQueryParams(String keyword, List<String> topicIds) {
    final params = <String, String>{
      'search': keyword,
      'per-page': '50',
      'mailto': 'truongtuan20042004@gmail.com',
    };

    final filters = <String>[];

    if (yearFrom != null && yearTo != null) {
      filters.add('publication_year:$yearFrom-$yearTo');
    } else if (yearFrom != null) {
      filters.add('publication_year:>$yearFrom');
    } else if (yearTo != null) {
      filters.add('publication_year:<$yearTo');
    }

    if (isOpenAccess != null) {
      filters.add('is_oa:$isOpenAccess');
    }

    if (language != null && language!.isNotEmpty) {
      filters.add('language:$language');
    }

    if (documentType != DocumentType.all) {
      filters.add('type:${documentType.name}');
    }

    if (topicIds.isNotEmpty) {
      filters.add('primary_topic.id:${topicIds.join('|')}');
    }

    if (filters.isNotEmpty) {
      params['filter'] = filters.join(',');
    }

    switch (sortOption) {
      case SortOption.citedDesc:
        params['sort'] = 'cited_by_count:desc';
        break;
      case SortOption.citedAsc:
        params['sort'] = 'cited_by_count:asc';
        break;
      case SortOption.yearDesc:
        params['sort'] = 'publication_date:desc';
        break;
      case SortOption.yearAsc:
        params['sort'] = 'publication_date:asc';
        break;
      case SortOption.relevance:
        break;
    }
    return params;
  }
}
