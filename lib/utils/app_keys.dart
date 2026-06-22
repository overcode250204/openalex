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
  static const logoutButton = Key('logout_button');
  static const googleSignInButton = Key('google_sign_in_button');

  static Key publicationItem(String id) => Key('publication_item_$id');
  static Key journalItem(String id) => Key('journal_item_$id');
  static Key keywordItem(String id) => Key('keyword_item_$id');
}
