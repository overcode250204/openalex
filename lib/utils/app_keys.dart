import 'package:flutter/widgets.dart';

/// Stable widget keys used by interaction tests and accessibility tooling.
abstract final class AppKeys {
  static const homeTab = Key('bottom_nav_home');
  static const journalsTab = Key('bottom_nav_journals');
  static const keywordsTab = Key('bottom_nav_keywords');
  static const profileTab = Key('bottom_nav_profile');

  static const searchTopicField = Key('search_topic_field');
  static const searchTopicButton = Key('search_topic_button');
  static const publicationList = Key('publication_list');
  static const journalList = Key('journal_list');
  static const keywordList = Key('keyword_list');
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
  static Key journalItem(String id) => Key('journal_item_$id');
  static Key keywordItem(String id) => Key('keyword_item_$id');
  static Key uploadedReportItem(String id) => Key('uploaded_report_item_$id');
  static Key uploadedReportCopyButton(String id) =>
      Key('uploaded_report_copy_button_$id');
  static Key uploadedReportOpenButton(String id) =>
      Key('uploaded_report_open_button_$id');
  static Key publicationAiPromptChip(String id) =>
      Key('publication_ai_prompt_chip_$id');
}
