import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/journal/journal_publication.dart';
import '../screens/auth/auth_gate_screen.dart';
import '../screens/app/app_shell_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/journal/journal_publication_detail_screen.dart';
import '../screens/keyword/keyword_detail_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/publication/publication_detail_screen.dart';
import '../screens/publication/publication_list_screen.dart';
import '../screens/trend/trend_analysis_screen.dart';
import '../viewmodels/publication_detail_view_model.dart';
import '../viewmodels/publication_list_view_model.dart';
import '../viewmodels/journal_publication_detail_view_model.dart';
import '../services/analytics/app_analytics_service.dart';
import '../services/openalex_journal_service.dart';
import '../services/openalex_service.dart';
import '../services/zotero_service.dart';
import 'app_routes.dart';
import 'route_arguments.dart';

abstract final class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.home:
        return _page(const AuthGateScreen(child: AppShell()), settings);
      case AppRoutes.profile:
        return _page(const ProfileScreen(), settings);
      case AppRoutes.trendAnalysis:
        final args = settings.arguments! as TopicAnalyticsRouteArgs;
        return _page(TrendAnalysisScreen(arguments: args), settings);
      case AppRoutes.dashboard:
        final args = settings.arguments! as TopicAnalyticsRouteArgs;
        return _page(DashboardScreen(arguments: args), settings);
      case AppRoutes.publicationDetail:
        final args = settings.arguments! as PublicationDetailRouteArgs;
        return _page(
          ChangeNotifierProvider(
            create: (context) => PublicationDetailViewModel(
              service: context.read<OpenAlexService>(),
              zoteroService: context.read<ZoteroService>(),
              analyticsService: context.read<AppAnalyticsService>(),
            ),
            child: PublicationDetailScreen(
              workId: args.workId,
              initialTitle: args.initialTitle,
            ),
          ),
          settings,
        );
      case AppRoutes.publicationList:
        final args = settings.arguments! as PublicationListRouteArgs;
        return _page(
          ChangeNotifierProvider(
            create: (context) => PublicationListViewModel(
              service: context.read<OpenAlexService>(),
            ),
            child: PublicationListScreen(
              type: args.type,
              workId: args.workId,
              ids: args.ids,
              title: args.title,
            ),
          ),
          settings,
        );
      case AppRoutes.journalDetail:
        return _page(
          ChangeNotifierProvider(
            create: (context) => JournalPublicationDetailViewModel(
              context.read<OpenAlexJournalService>(),
            ),
            child: JournalPublicationDetailScreen(
              publication: settings.arguments! as JournalPublication,
            ),
          ),
          settings,
        );
      case AppRoutes.keywordDetail:
        final args = settings.arguments! as KeywordDetailRouteArgs;
        return _page(
          KeywordDetailScreen(
            selectedKeyword: args.keyword,
            originalSearchText: args.originalSearchText,
          ),
          settings,
        );
      default:
        return _page(const AppShell(), settings);
    }
  }

  static MaterialPageRoute<dynamic> _page(
    Widget child,
    RouteSettings settings,
  ) {
    return MaterialPageRoute(builder: (_) => child, settings: settings);
  }
}
