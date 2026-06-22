import '../models/keyword/openalex_keyword.dart';
import '../viewmodels/publication_list_view_model.dart';

class PublicationDetailRouteArgs {
  final String workId;
  final String? initialTitle;

  const PublicationDetailRouteArgs({required this.workId, this.initialTitle});
}

class PublicationListRouteArgs {
  final ListType type;
  final String workId;
  final List<String> ids;
  final String title;

  const PublicationListRouteArgs({
    required this.type,
    required this.workId,
    required this.ids,
    required this.title,
  });
}

class KeywordDetailRouteArgs {
  final OpenAlexKeyword keyword;
  final String? originalSearchText;

  const KeywordDetailRouteArgs({
    required this.keyword,
    this.originalSearchText,
  });
}
