import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../viewmodels/analytics_view_model.dart';
import '../viewmodels/journal_view_model.dart';
import '../viewmodels/keyword_dashboard_view_model.dart';
import '../viewmodels/home_view_model.dart';
import '../services/keyword_dashboard_service.dart';
import '../services/analytics_service.dart';
import '../services/openalex_journal_service.dart';
import '../services/openalex_keyword_service.dart';
import '../services/openalex_service.dart';
import '../services/suggestion_service.dart';
import '../services/trend_report_export_service.dart';
import '../services/zotero_serivce.dart';
import '../viewmodels/dashboard_view_model.dart';
import '../viewmodels/keyword_analyzer_view_model.dart';
import '../viewmodels/selected_topic_view_model.dart';
import '../viewmodels/trend_analysis_view_model.dart';

/// The single dependency-registration boundary for the application.
abstract final class AppProviders {
  static List<SingleChildWidget> build() {
    return [
      Provider(create: (_) => OpenAlexService()),
      Provider(create: (_) => OpenAlexKeywordService()),
      Provider(create: (_) => OpenAlexJournalService()),
      Provider(create: (_) => AnalyticsService()),
      Provider(create: (_) => KeywordDashboardService()),
      Provider(create: (_) => SuggestionService()),
      Provider(create: (_) => const TrendReportExportService()),
      Provider(create: (_) => ZoteroService()),
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
}
