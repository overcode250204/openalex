import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/search/search_filter.dart';
import '../../routes/app_routes.dart';
import '../../routes/route_arguments.dart';
import '../../viewmodels/analytics_view_model.dart';
import '../../viewmodels/home_view_model.dart';
import '../../viewmodels/selected_topic_view_model.dart';
import '../../viewmodels/trend_analysis_view_model.dart';
import '../../widgets/analytics/analytics_chart_card.dart';
import '../../widgets/analytics/topic_summary_grid.dart';
import '../../widgets/publication_trend_line_chart.dart';
import '../../widgets/top_selector_dropdown.dart';
import '../../widgets/top_influential_papers_horizontal_chart.dart';
import '../../widgets/top_research_journals_donut_chart.dart';
import '../../widgets/top_contributing_authors_column_chart.dart';

class TrendAnalysisScreen extends StatefulWidget {
  const TrendAnalysisScreen({super.key});

  @override
  State<TrendAnalysisScreen> createState() => _TrendAnalysisScreenState();
}

class _TrendAnalysisScreenState extends State<TrendAnalysisScreen> {
  bool _isInitializationScheduled = false;
  String? _lastAnalyticsSignature;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInitializationScheduled) return;
    _isInitializationScheduled = true;

    final publication = context.read<HomeViewModel>();
    final viewModel = context.read<TrendAnalysisViewModel>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      viewModel.initialize(
        topic: publication.currentTopic,
        initialTrend: publication.publicationCountByYear,
        initialPapers: publication.topInfluentialPapers,
        initialJournals: publication.topJournals,
        initialAuthors: publication.topAuthors,
      );
    });
  }

  void _syncAnalytics(
    HomeViewModel provider,
    TrendAnalysisViewModel trendViewModel,
  ) {
    final selectedTopic = context.read<SelectedTopicViewModel>();
    final topicId =
        provider.currentTopicId ?? selectedTopic.selectedSuggestion?.id;
    final filter = SearchFilter(
      yearFrom: trendViewModel.selectedFromYear,
      yearTo: trendViewModel.selectedToYear,
      isOpenAccess: provider.filter.isOpenAccess,
      language: provider.filter.language,
      documentType: provider.filter.documentType,
      sortOption: provider.filter.sortOption,
    );
    final signature =
        '$topicId|${provider.currentTopic}|'
        '${filter.yearFrom}|${filter.yearTo}';
    if (signature == _lastAnalyticsSignature) return;
    _lastAnalyticsSignature = signature;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AnalyticsViewModel>().fetchAnalytics(
        provider.currentTopic,
        filter,
        provider.publications,
        topicId: topicId,
        fallbackTrend: trendViewModel.fetchedTrendData ?? const {},
        includeCharts: false,
      );
    });
  }

  void _retryAnalytics(
    HomeViewModel provider,
    TrendAnalysisViewModel trendViewModel,
  ) {
    final selectedTopic = context.read<SelectedTopicViewModel>();
    final topicId =
        provider.currentTopicId ?? selectedTopic.selectedSuggestion?.id;
    final filter = SearchFilter(
      yearFrom: trendViewModel.selectedFromYear,
      yearTo: trendViewModel.selectedToYear,
      isOpenAccess: provider.filter.isOpenAccess,
      language: provider.filter.language,
      documentType: provider.filter.documentType,
      sortOption: provider.filter.sortOption,
    );
    context.read<AnalyticsViewModel>().fetchAnalytics(
      provider.currentTopic,
      filter,
      provider.publications,
      topicId: topicId,
      fallbackTrend: trendViewModel.fetchedTrendData ?? const {},
      includeCharts: false,
      forceRefresh: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HomeViewModel>();
    final viewModel = context.watch<TrendAnalysisViewModel>();
    final analytics = context.watch<AnalyticsViewModel>();

    if (provider.publications.isNotEmpty) {
      _syncAnalytics(provider, viewModel);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text(
          'Trend Analysis',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              // Share action
            },
          ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.publications.isEmpty && provider.errorMessage == null
          ? const Center(
              child: Text('Search a topic first to view trend analysis.'),
            )
          : provider.errorMessage != null
          ? Center(
              child: Text(
                provider.errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            )
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: 100, // Padding bottom for the fixed bottom navigation
                ),
                child: Column(
                  children: [
                    if (analytics.error != null) ...[
                      _AnalyticsErrorBanner(
                        onRetry: () => _retryAnalytics(provider, viewModel),
                      ),
                      const SizedBox(height: 12),
                    ],
                    TopicSummaryGrid(
                      isLoading:
                          analytics.isLoading ||
                          (!analytics.hasLoaded && analytics.error == null),
                      totalPublications:
                          analytics.hasLoaded ||
                              analytics.publicationTrend.isNotEmpty
                          ? _compactNumber(analytics.totalWorks)
                          : 'N/A',
                      averageCitations:
                          analytics.averageCitations?.toStringAsFixed(1) ??
                          'N/A',
                      mostActiveYear:
                          analytics.mostActiveYear?.toString() ?? 'N/A',
                      topAuthor: analytics.topAuthorName ?? 'N/A',
                      topJournal: analytics.topJournalName ?? 'N/A',
                      mostInfluentialPaper:
                          analytics.mostCitedTitle ?? 'N/A',
                      influentialPaperDetails:
                          _influentialPaperDetails(analytics),
                      onInfluentialPaperTap:
                          analytics.mostInfluentialPaper?.id.isNotEmpty == true
                          ? () {
                              final paper = analytics.mostInfluentialPaper!;
                              Navigator.pushNamed(
                                context,
                                AppRoutes.publicationDetail,
                                arguments: PublicationDetailRouteArgs(
                                  workId: paper.id,
                                  initialTitle: paper.title,
                                ),
                              );
                            }
                          : null,
                    ),
                    const SizedBox(height: 16),
                    AnalyticsChartCard(
                      title:
                          'Publication Trend: ${provider.currentTopic.isNotEmpty ? provider.currentTopic : "Topic"}',
                      customDropdown: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          DropdownButton<int>(
                            value: viewModel.selectedFromYear,
                            underline: const SizedBox.shrink(),
                            items: List.generate(
                              DateTime.now().year - 1990 + 1,
                              (index) {
                                final year = 1990 + index;
                                return DropdownMenuItem(
                                  value: year,
                                  child: Text('$year'),
                                );
                              },
                            ),
                            onChanged: (value) =>
                                viewModel.updateYearRange(fromYear: value),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6),
                            child: Text('to'),
                          ),
                          DropdownButton<int>(
                            value: viewModel.selectedToYear,
                            underline: const SizedBox.shrink(),
                            items: List.generate(
                              DateTime.now().year - 1990 + 1,
                              (index) {
                                final year = 1990 + index;
                                return DropdownMenuItem(
                                  value: year,
                                  child: Text('$year'),
                                );
                              },
                            ),
                            onChanged: (value) =>
                                viewModel.updateYearRange(toYear: value),
                          ),
                        ],
                      ),
                      child: viewModel.isLoadingTrend
                          ? const SizedBox(
                              height: 300,
                              child: Center(child: CircularProgressIndicator()),
                            )
                          : viewModel.hasErrorTrend
                          ? SizedBox(
                              height: 300,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      'Failed to load publication trend.',
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: viewModel.loadPublicationTrend,
                                      child: const Text('Retry'),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : (viewModel.fetchedTrendData == null ||
                                viewModel.fetchedTrendData!.isEmpty)
                          ? const SizedBox(
                              height: 300,
                              child: Center(
                                child: Text(
                                  'No publication trend data available.',
                                ),
                              ),
                            )
                          : PublicationTrendLineChart(
                              data: viewModel.fetchedTrendData!,
                            ),
                    ),
                    const SizedBox(height: 16),
                    AnalyticsChartCard(
                      title: 'Top Influential Papers',
                      showInfoIcon: true,
                      customDropdown: TopSelectorDropdown(
                        value: viewModel.selectedTopPapers,
                        onChanged: viewModel.updateTopPapers,
                      ),
                      child:
                          viewModel.isLoadingPapers ||
                              viewModel.fetchedPapers == null
                          ? const SizedBox(
                              height: 260,
                              child: Center(child: CircularProgressIndicator()),
                            )
                          : viewModel.hasErrorPapers
                          ? SizedBox(
                              height: 260,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      'Failed to load influential papers.',
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: () =>
                                          viewModel.loadInfluentialPapers(
                                            limit: viewModel.selectedTopPapers,
                                          ),
                                      child: const Text('Retry'),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : viewModel.fetchedPapers!.isEmpty
                          ? const SizedBox(
                              height: 260,
                              child: Center(
                                child: Text('No influential papers available.'),
                              ),
                            )
                          : TopInfluentialPapersHorizontalChart(
                              papers: viewModel.fetchedPapers!,
                            ),
                    ),
                    const SizedBox(height: 16),
                    AnalyticsChartCard(
                      title: 'Top Research Journals',
                      showInfoIcon: true,
                      customDropdown: TopSelectorDropdown(
                        value: viewModel.selectedTopJournals,
                        onChanged: viewModel.updateTopJournals,
                      ),
                      child:
                          viewModel.isLoadingJournals ||
                              viewModel.fetchedJournalsData == null
                          ? const SizedBox(
                              height: 260,
                              child: Center(child: CircularProgressIndicator()),
                            )
                          : viewModel.hasErrorJournals
                          ? SizedBox(
                              height: 260,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      'Failed to load research journals.',
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: () =>
                                          viewModel.loadTopResearchJournals(
                                            limit:
                                                viewModel.selectedTopJournals,
                                          ),
                                      child: const Text('Retry'),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : viewModel.fetchedJournalsData!.isEmpty
                          ? const SizedBox(
                              height: 260,
                              child: Center(
                                child: Text('No research journals available.'),
                              ),
                            )
                          : TopResearchJournalsDonutChart(
                              journalsData: viewModel.fetchedJournalsData!,
                            ),
                    ),
                    const SizedBox(height: 16),
                    AnalyticsChartCard(
                      title: 'Top Contributing Authors',
                      showInfoIcon: true,
                      customDropdown: TopSelectorDropdown(
                        value: viewModel.selectedTopAuthors,
                        onChanged: viewModel.updateTopAuthors,
                      ),
                      child:
                          viewModel.isLoadingAuthors ||
                              viewModel.fetchedAuthorsData == null
                          ? const SizedBox(
                              height: 260,
                              child: Center(child: CircularProgressIndicator()),
                            )
                          : viewModel.hasErrorAuthors
                          ? SizedBox(
                              height: 260,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      'Failed to load contributing authors.',
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: () =>
                                          viewModel.loadTopContributingAuthors(
                                            limit: viewModel.selectedTopAuthors,
                                          ),
                                      child: const Text('Retry'),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : viewModel.fetchedAuthorsData!.isEmpty
                          ? const SizedBox(
                              height: 260,
                              child: Center(
                                child: Text(
                                  'No contributing authors available.',
                                ),
                              ),
                            )
                          : TopContributingAuthorsColumnChart(
                              authorsData: viewModel.fetchedAuthorsData!,
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

String _compactNumber(int value) {
  if (value >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(1)}M';
  }
  if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(1)}k';
  }
  return value.toString();
}

String? _influentialPaperDetails(AnalyticsViewModel analytics) {
  final paper = analytics.mostInfluentialPaper;
  if (paper == null) return null;
  final year = paper.publicationYear?.toString() ?? 'Unknown year';
  return '${_compactNumber(paper.citedByCount)} citations • $year';
}

class _AnalyticsErrorBanner extends StatelessWidget {
  final VoidCallback onRetry;

  const _AnalyticsErrorBanner({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.errorContainer,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.error_outline),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Unable to load all topic summary metrics. '
                'Check the OpenAlex API key or try again.',
              ),
            ),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
