import 'package:flutter/widgets.dart';

/// Stable widget keys used by interaction tests and accessibility tooling.
abstract final class AppKeys {
  static const homeTab = Key('bottom_nav_home');
  static const journalsTab = Key('bottom_nav_journals');
  static const navKeywordsTab = Key('nav_keywords_tab');
  static const keywordsTab = navKeywordsTab;
  static const profileTab = Key('bottom_nav_profile');

  static const searchTopicField = Key('search_topic_field');
  static const searchTopicButton = Key('search_topic_button');
  static const publicationList = Key('publication_list');
  static const journalList = Key('journal_list');
  static const keywordList = Key('keyword_list');
  static const keywordSearchField = Key('keyword_search_field');
  static const keywordAnalyzeButton = Key('keyword_analyze_button');
  static const keywordAnalysisLoading = Key('keyword_analysis_loading');
  static const keywordAnalysisResult = Key('keyword_analysis_result');
  static const keywordDetailScreen = Key('keyword_detail_screen');
  static const keywordDetailTitle = Key('keyword_detail_title');
  static const keywordMetricsSection = Key('keyword_metrics_section');
  static const keywordTrendChart = Key('keyword_trend_chart');
  static const authorRankingSection = Key('author_ranking_section');
  static const authorRankingList = Key('author_ranking_list');
  static const authorRank1 = Key('author_rank_1');
  static const authorName1 = Key('author_name_1');
  static const exportPdfButton = Key('export_pdf_button');
  static const logoutButton = Key('logout_button');
  static const googleSignInButton = Key('google_sign_in_button');

  static Key publicationItem(String id) => Key('publication_item_$id');
  static Key journalItem(String id) => Key('journal_item_$id');
  static Key keywordItem(String id) => Key('keyword_item_$id');
  static Key keywordSuggestionItem(String id) =>
      Key('keyword_suggestion_item_$id');
}
