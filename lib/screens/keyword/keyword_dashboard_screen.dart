import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../utils/formatters.dart';

import '../../models/keyword/keyword_dashboard_result.dart';
import '../../models/keyword/openalex_keyword.dart';
import '../../viewmodels/keyword_dashboard_view_model.dart';
import '../../routes/app_routes.dart';
import '../../routes/route_arguments.dart';
import '../../services/suggestion_service.dart';
import '../../viewmodels/keyword_analyzer_view_model.dart';
import '../../widgets/keyword/charts/keyword_trend_comparison_chart.dart';
import '../../widgets/keyword/hot_keyword_hero_card.dart';
import '../../widgets/keyword/keyword_autocomplete_search.dart';
import '../../widgets/state/app_error_widget.dart';
import '../../widgets/state/empty_state_widget.dart';
import '../../widgets/state/loading_widget.dart';
import '../../widgets/keyword/keyword_stat_card.dart';
import '../../widgets/keyword/most_frequent_keywords_chart.dart';
import '../../widgets/keyword/trending_keywords_chart.dart';
import '../../widgets/ai/ai_research_assistant_button.dart';

class KeywordDashboardScreen extends StatefulWidget {
  const KeywordDashboardScreen({super.key});

  @override
  State<KeywordDashboardScreen> createState() => _KeywordDashboardScreenState();
}

class _KeywordDashboardScreenState extends State<KeywordDashboardScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _mostFrequentTopN = 5;
  int _trendingTopN = 5;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Tự động refresh khi bấm tới tab này
      context.read<KeywordDashboardViewModel>().refresh();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _analyze(String keywordStr) async {
    final keyword = keywordStr.trim();
    if (keyword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an academic keyword.')),
      );
      return;
    }

    try {
      final resolved = await context
          .read<KeywordAnalyzerViewModel>()
          .resolveKeyword(keyword);
      if (resolved == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No matching academic keywords found.')),
        );
        return;
      }
      _openDetailWithKeyword(resolved, originalText: keyword);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to resolve keyword. Please try again.'),
        ),
      );
    }
  }

  void _openDetailWithKeyword(OpenAlexKeyword keyword, {String? originalText}) {
    Navigator.pushNamed(
      context,
      AppRoutes.keywordDetail,
      arguments: KeywordDetailRouteArgs(
        keyword: keyword,
        originalSearchText: originalText,
      ),
    );
  }

  void _openDetail(String keywordName) async {
    // For tapping charts/dashboard cards, we just resolve by name
    _analyze(keywordName);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<KeywordDashboardViewModel>();
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text('Keyword Analyzer'),
        actions: [
          IconButton(
            tooltip: 'Refresh keyword dashboard',
            onPressed: provider.state == KeywordDashboardState.refreshing
                ? null
                : provider.refresh,
            icon: provider.state == KeywordDashboardState.refreshing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Stack(
        children: [
          _body(provider),
          // Floating AI assistant — sits above the bottom nav bar
          Positioned(
            right: 16,
            bottom: 20,
            child: const AiResearchAssistantButton(),
          ),
        ],
      ),
    );
  }

  Widget _body(KeywordDashboardViewModel provider) {
    if (provider.state == KeywordDashboardState.initial ||
        (provider.state == KeywordDashboardState.loading &&
            provider.result == null)) {
      return const LoadingWidget(message: 'Loading keyword activity...');
    }
    if (provider.state == KeywordDashboardState.error &&
        provider.result == null) {
      return AppErrorWidget(
        message: provider.errorMessage ?? 'Unable to load keyword activity.',
        onRetry: provider.load,
      );
    }
    if (provider.result == null || provider.result!.isEmpty) {
      return EmptyStateWidget(
        message: 'No recent keyword activity found.',
        icon: Icons.insights_outlined,
        action: OutlinedButton(
          onPressed: provider.refresh,
          child: const Text('Refresh'),
        ),
      );
    }
    return _dashboard(provider.result!, provider);
  }

  Widget _dashboard(
    KeywordDashboardResult result,
    KeywordDashboardViewModel provider,
  ) {
    final stats = result.statistics;
    final keywordAnalyzer = context.watch<KeywordAnalyzerViewModel>();
    return RefreshIndicator(
      onRefresh: provider.refresh,
      child: ListView(
        key: const PageStorageKey('keyword-dashboard-scroll'),
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Keyword Analyzer',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const Text('Discover active and emerging research keywords'),
          const SizedBox(height: 16),
          Card(
            clipBehavior: Clip.none,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  KeywordAutocompleteSearch(
                    controller: _searchController,
                    suggestionService: context.read<SuggestionService>(),
                    onKeywordSelected: (kw) => _openDetailWithKeyword(kw),
                    onAnalyzePressed: _analyze,
                  ),
                  if (keywordAnalyzer.isResolvingKeyword)
                    const Positioned(
                      right: 16,
                      top: 14,
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          HotKeywordHeroCard(
            keyword: result.hottestKeyword!,
            onViewDetail: () => _openDetail(result.hottestKeyword!.name),
            onShowCalculation: _showCalculation,
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              // Always 2 columns on mobile, 4 on wide screens
              final columns = constraints.maxWidth >= 900 ? 4 : 2;
              final spacing = 10.0;

              final card1 = KeywordStatCard(
                label: 'Total Keywords',
                value: stats.totalKeywordsAnalyzed.toString(),
                icon: Icons.key,
              );
              final card2 = KeywordStatCard(
                label: 'Total Publications',
                value: Formatters.formatCompactNumber(
                  stats.totalRecentPublications,
                ),
                icon: Icons.article_outlined,
              );
              final card3 = KeywordStatCard(
                label: 'Hottest Keyword',
                value: stats.hottestKeyword,
                icon: Icons.local_fire_department_outlined,
              );
              final card4 = KeywordStatCard(
                label: 'Fastest Growth',
                value: Formatters.formatGrowthRate(stats.fastestGrowthRate),
                icon: Icons.trending_up,
              );

              if (columns == 4) {
                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: card1),
                      SizedBox(width: spacing),
                      Expanded(child: card2),
                      SizedBox(width: spacing),
                      Expanded(child: card3),
                      SizedBox(width: spacing),
                      Expanded(child: card4),
                    ],
                  ),
                );
              }

              return Column(
                children: [
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: card1),
                        SizedBox(width: spacing),
                        Expanded(child: card2),
                      ],
                    ),
                  ),
                  SizedBox(height: spacing),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: card3),
                        SizedBox(width: spacing),
                        Expanded(child: card4),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          MostFrequentKeywordsChart(
            keywords: result.mostFrequentKeywords,
            selectedTopN: _mostFrequentTopN,
            onTopNChanged: (value) {
              setState(() => _mostFrequentTopN = value);
            },
            onSelected: (keyword) => _openDetail(keyword.name),
          ),
          const SizedBox(height: 16),
          TrendingKeywordsChart(
            keywords: result.trendingKeywords,
            selectedTopN: _trendingTopN,
            onTopNChanged: (value) {
              setState(() => _trendingTopN = value);
            },
            onSelected: (keyword) => _openDetail(keyword.name),
          ),
          const SizedBox(height: 16),
          KeywordTrendComparisonChart(
            series: result.trendSeries,
            fromYear: provider.selectedFromYear,
            toYear: provider.selectedToYear,
            onYearRangeChanged: provider.updateTrendYearRange,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _showCalculation() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('How Hot Score Is Calculated'),
        content: const Text(
          'Recent publication volume: 70%\n'
          'Publication growth rate: 30%\n\n'
          'The dashboard compares the latest rolling 12 months with the prior '
          '12 months. It identifies research activity trends, not research quality.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
