import 'package:flutter/widgets.dart';

/// Stable widget keys used by interaction tests and accessibility tooling.
abstract final class AppKeys {
  static const homeTab = Key('bottom_nav_home');
  static const journalsTab = Key('bottom_nav_journals');
  static const keywordsTab = Key('keywords_tab');
  static const profileTab = Key('bottom_nav_profile');

  static const searchTopicField = Key('topic_search_input');
  static const topicSearchInput = searchTopicField;
  static const searchTopicButton = Key('topic_search_button');
  static const topicSearchButton = searchTopicButton;
  static const topicSearchLoading = Key('topic_search_loading');
  static const publicationList = Key('publication_list');
  static const publicationResultsList = publicationList;
  static const journalList = Key('journal_list');
  static const keywordList = Key('keyword_list');
  static const journalSearchInput = Key('journal_search_input');
  static const keywordSearchInput = Key('keyword_search_input');
  static const keywordSearchButton = Key('keyword_search_button');
  static const keywordDetailScreen = Key('keyword_detail_screen');
  static const keywordAnalysisSection = Key('keyword_analysis_section');
  static const keywordTrendSection = Key('keyword_trend_section');
  static const authorRankingSection = Key('author_ranking_section');
  static const keywordPublicationsSection = Key('keyword_publications_section');
  static const journalDetailScreen = Key('journal_detail_screen');
  static const journalStatsSection = Key('journal_stats_section');
  static const journalChartSection = Key('journal_chart_section');
  static const journalPublicationsSection = Key('journal_publications_section');
  static const publicationDetailScreen = Key('publication_detail_screen');
  static const publicationDetailTitle = Key('publication_detail_title');
  static const publicationDetailAuthors = Key('publication_detail_authors');
  static const publicationDetailYear = Key('publication_detail_year');
  static const publicationDetailSource = Key('publication_detail_source');
  static const publicationDetailAbstract = Key('publication_detail_abstract');
  static const emptySearchState = Key('empty_search_state');
  static const searchErrorState = Key('search_error_state');
  static const exportPdfButton = Key('export_pdf_button');
  static const uploadedPdfLinkCard = Key('uploaded_pdf_link_card');
  static const uploadedPdfOpenButton = Key('uploaded_pdf_open_button');
  static const uploadedPdfCopyButton = Key('uploaded_pdf_copy_button');
  static const uploadedPdfDismissButton = Key('uploaded_pdf_dismiss_button');
  static const uploadedReportsCard = Key('uploaded_reports_card');
  static const uploadedReportsRefreshButton = Key(
    'uploaded_reports_refresh_button',
  );
  static const logoutButton = Key('logout_button');
  static const googleSignInButton = Key('google_sign_in_button');
  static const publicationAiChatButton = Key('publication_ai_chat_button');
  static const publicationAiChatPanel = Key('publication_ai_chat_panel');
  static const publicationAiChatInput = Key('publication_ai_chat_input');
  static const publicationAiChatSendButton = Key(
    'publication_ai_chat_send_button',
  );
  static const publicationAiChatClearButton = Key(
    'publication_ai_chat_clear_button',
  );

  static Key publicationItem(String id) => Key('publication_item_$id');
  static Key publicationCard(String id) => Key('publication_card_$id');
  static Key publicationResultItem(String id) =>
      Key('publication_result_item_$id');
  static Key journalItem(String id) => Key('journal_item_$id');
  static Key keywordItem(String id) => Key('keyword_item_$id');
  static Key authorRankingItem(String id) => Key('author_ranking_item_$id');
  static Key uploadedReportItem(String id) => Key('uploaded_report_item_$id');
  static Key uploadedReportCopyButton(String id) =>
      Key('uploaded_report_copy_button_$id');
  static Key uploadedReportOpenButton(String id) =>
      Key('uploaded_report_open_button_$id');
  static Key publicationAiPromptChip(String id) =>
      Key('publication_ai_prompt_chip_$id');

  static const adminShellScreen = Key('admin_shell_screen');
  static const adminOverviewScreen = Key('admin_overview_screen');
  static const adminUsersScreen = Key('admin_users_screen');
  static const adminRemoteConfigScreen = Key('admin_remote_config_screen');
  static const adminNotificationsScreen = Key('admin_notifications_screen');
  static const adminReportsScreen = Key('admin_reports_screen');
  static const adminNavOverview = Key('admin_nav_overview');
  static const adminNavUsers = Key('admin_nav_users');
  static const adminNavRemoteConfig = Key('admin_nav_remote_config');
  static const adminNavNotifications = Key('admin_nav_notifications');
  static const adminNavReports = Key('admin_nav_reports');
  static const adminMaxJournalsField = Key('admin_max_journals_field');
  static const adminMaxKeywordsField = Key('admin_max_keywords_field');
  static const adminRemoteConfigSaveButton = Key(
    'admin_remote_config_save_button',
  );
  static const adminNotificationTitleField = Key(
    'admin_notification_title_field',
  );
  static const adminNotificationBodyField = Key(
    'admin_notification_body_field',
  );
  static const adminNotificationSendButton = Key(
    'admin_notification_send_button',
  );

  static Key adminUserItem(String uid) => Key('admin_user_item_$uid');
  static Key adminUserDisableToggle(String uid) =>
      Key('admin_user_disable_toggle_$uid');
  static Key adminUserRoleToggle(String uid) =>
      Key('admin_user_role_toggle_$uid');
  static Key adminReportItem(String id) => Key('admin_report_item_$id');
}
