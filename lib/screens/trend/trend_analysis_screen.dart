import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/home_view_model.dart';
import '../../widgets/analytics/analytics_chart_card.dart';
import '../../widgets/publication_trend_line_chart.dart';
import '../../widgets/top_influential_papers_horizontal_chart.dart';
import '../../widgets/top_research_journals_donut_chart.dart';
import '../../widgets/top_contributing_authors_column_chart.dart';

import '../../viewmodels/trend_analysis_view_model.dart';
import '../../widgets/top_selector_dropdown.dart';

class TrendAnalysisScreen extends StatefulWidget {
  const TrendAnalysisScreen({super.key});

  @override
  State<TrendAnalysisScreen> createState() => _TrendAnalysisScreenState();
}

class _TrendAnalysisScreenState extends State<TrendAnalysisScreen> {
  bool _isInitializationScheduled = false;

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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HomeViewModel>();
    final viewModel = context.watch<TrendAnalysisViewModel>();

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
