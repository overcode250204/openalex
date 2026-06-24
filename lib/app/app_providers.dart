import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../viewmodels/analytics_view_model.dart';
import '../viewmodels/journal_view_model.dart';
import '../viewmodels/keyword_dashboard_view_model.dart';
import '../viewmodels/home_view_model.dart';
import '../services/keyword_dashboard_service.dart';
import '../services/analytics/analytics_service.dart';
import '../services/analytics/app_analytics_service.dart';
import '../services/firebase/firebase_analytics_service.dart';
import '../services/analytics/no_op_analytics_service.dart';
import '../services/firebase/firebase_auth_service.dart';
import '../services/openalex_journal_service.dart';
import '../services/openalex_keyword_service.dart';
import '../services/openalex_service.dart';
import '../services/suggestion_service.dart';
import '../services/trend_report_export_service.dart';
import '../services/zotero_service.dart';
import '../viewmodels/dashboard_view_model.dart';
import '../viewmodels/auth_view_model.dart';
import '../viewmodels/keyword_analyzer_view_model.dart';
import '../viewmodels/selected_topic_view_model.dart';
import '../viewmodels/trend_analysis_view_model.dart';

/// The single dependency-registration boundary for the application.
abstract final class AppProviders {
  static List<SingleChildWidget> build({
    AuthService? authService,
    AppAnalyticsService? analyticsService,
  }) {
    return [
      Provider(create: (_) => OpenAlexService()),
      Provider(create: (_) => OpenAlexKeywordService()),
      Provider(create: (_) => OpenAlexJournalService()),
      Provider(create: (_) => AnalyticsService(apiKey: _openAlexApiKey())),
      Provider(create: (_) => KeywordDashboardService()),
      Provider(create: (_) => SuggestionService()),
      Provider(create: (_) => const TrendReportExportService()),
      Provider(create: (_) => ZoteroService()),
      Provider<AuthService>(
        create: (_) => authService ?? FirebaseAuthService(),
      ),
      Provider<AppAnalyticsService>(
        create: (_) =>
            analyticsService ??
            (authService == null
                ? FirebaseAnalyticsService()
                : const NoOpAnalyticsService()),
      ),
      ChangeNotifierProvider(
        create: (context) => AuthViewModel(
          authService: context.read<AuthService>(),
          analyticsService: context.read<AppAnalyticsService>(),
        ),
      ),
      ChangeNotifierProvider(create: (_) => SelectedTopicViewModel()),
      ChangeNotifierProvider(
        create: (context) =>
            TrendAnalysisViewModel(service: context.read<OpenAlexService>()),
      ),
      ChangeNotifierProvider(
        create: (context) => HomeViewModel(
          context.read<OpenAlexService>(),
          suggestionService: context.read<SuggestionService>(),
          selectedTopicViewModel: context.read<SelectedTopicViewModel>(),
        ),
      ),
      ChangeNotifierProvider(
        create: (context) => AnalyticsViewModel(
          analyticsService: context.read<AnalyticsService>(),
        ),
      ),
      ChangeNotifierProvider(
        create: (context) => DashboardViewModel(
          exportService: context.read<TrendReportExportService>(),
        ),
      ),
      ChangeNotifierProvider(
        create: (context) =>
            KeywordDashboardViewModel(context.read<KeywordDashboardService>()),
      ),
      ChangeNotifierProvider(
        create: (context) =>
            KeywordAnalyzerViewModel(context.read<OpenAlexKeywordService>()),
      ),
      ChangeNotifierProvider(
        create: (context) => JournalViewModel(
          context.read<OpenAlexJournalService>(),
          suggestionService: context.read<SuggestionService>(),
        ),
      ),
    ];
  }

  static String? _openAlexApiKey() {
    try {
      return dotenv.env['OPENALEX_API_KEY'];
    } catch (_) {
      return null;
    }
  }
}
