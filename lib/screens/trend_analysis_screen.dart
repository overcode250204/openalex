import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/publication_provider.dart';
import '../widgets/analytics_chart_card.dart';
import '../widgets/publication_trend_line_chart.dart';
import '../widgets/top_influential_papers_horizontal_chart.dart';
import '../widgets/top_research_journals_donut_chart.dart';
import '../widgets/top_contributing_authors_column_chart.dart';

import '../models/publication.dart';
import '../services/openalex_service.dart';
import '../widgets/top_selector_dropdown.dart';

class TrendAnalysisScreen extends StatefulWidget {
  const TrendAnalysisScreen({super.key});

  @override
  State<TrendAnalysisScreen> createState() => _TrendAnalysisScreenState();
}

class _TrendAnalysisScreenState extends State<TrendAnalysisScreen> {
  int? selectedTopPapers = 5;
  bool isLoadingPapers = false;
  bool hasErrorPapers = false;
  List<Publication>? fetchedPapers;

  int? selectedTopJournals = 10;
  bool isLoadingJournals = false;
  bool hasErrorJournals = false;
  Map<String, int>? fetchedJournalsData;

  int? selectedTopAuthors = 10;
  bool isLoadingAuthors = false;
  bool hasErrorAuthors = false;
  Map<String, int>? fetchedAuthorsData;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.wait([
        _loadInfluentialPapers(limit: selectedTopPapers),
        _loadTopResearchJournals(limit: selectedTopJournals),
        _loadTopContributingAuthors(limit: selectedTopAuthors),
      ]);
    });
  }

  Future<void> _loadInfluentialPapers({int? limit}) async {
    final provider = context.read<PublicationProvider>();
    final keyword = provider.currentTopic;
    if (keyword.trim().isEmpty) return;

    setState(() {
      isLoadingPapers = true;
      hasErrorPapers = false;
    });

    try {
      final service = OpenAlexService();
      final result = await service.fetchInfluentialPapers(
        keyword: keyword,
        limit: limit,
      );

      if (mounted) {
        setState(() {
          fetchedPapers = result;
          isLoadingPapers = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          hasErrorPapers = true;
          isLoadingPapers = false;
        });
      }
    }
  }

  Future<void> _loadTopResearchJournals({int? limit}) async {
    final provider = context.read<PublicationProvider>();
    final keyword = provider.currentTopic;
    if (keyword.trim().isEmpty) return;

    setState(() {
      isLoadingJournals = true;
      hasErrorJournals = false;
    });

    try {
      final service = OpenAlexService();
      final result = await service.fetchTopResearchJournals(
        keyword: keyword,
        limit: limit,
      );

      if (mounted) {
        setState(() {
          fetchedJournalsData = result;
          isLoadingJournals = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          hasErrorJournals = true;
          isLoadingJournals = false;
        });
      }
    }
  }

  Future<void> _loadTopContributingAuthors({int? limit}) async {
    final provider = context.read<PublicationProvider>();
    final keyword = provider.currentTopic;
    if (keyword.trim().isEmpty) return;

    setState(() {
      isLoadingAuthors = true;
      hasErrorAuthors = false;
    });

    try {
      final service = OpenAlexService();
      final result = await service.fetchTopContributingAuthors(
        keyword: keyword,
        limit: limit,
      );

      if (mounted) {
        setState(() {
          fetchedAuthorsData = result;
          isLoadingAuthors = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          hasErrorAuthors = true;
          isLoadingAuthors = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PublicationProvider>();

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
                      title: 'Publication Trend: ${provider.currentTopic.isNotEmpty ? provider.currentTopic : "Topic"}',
                      dropdownText: 'Yearly',
                      child: PublicationTrendLineChart(
                        data: provider.publicationCountByYear,
                      ),
                    ),
                    const SizedBox(height: 16),
                    AnalyticsChartCard(
                      title: 'Top Influential Papers',
                      showInfoIcon: true,
                      customDropdown: TopSelectorDropdown(
                        value: selectedTopPapers,
                        onChanged: (value) async {
                          setState(() {
                            selectedTopPapers = value;
                          });
                          await _loadInfluentialPapers(limit: value);
                        },
                      ),
                      child: isLoadingPapers || fetchedPapers == null
                          ? const SizedBox(
                              height: 260,
                              child: Center(child: CircularProgressIndicator()),
                            )
                          : hasErrorPapers
                              ? SizedBox(
                                  height: 260,
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Text('Failed to load influential papers.'),
                                        const SizedBox(height: 16),
                                        ElevatedButton(
                                          onPressed: () => _loadInfluentialPapers(limit: selectedTopPapers),
                                          child: const Text('Retry'),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : fetchedPapers!.isEmpty
                                  ? const SizedBox(
                                      height: 260,
                                      child: Center(
                                        child: Text('No influential papers available.'),
                                      ),
                                    )
                                  : TopInfluentialPapersHorizontalChart(
                                      papers: fetchedPapers!,
                                    ),
                    ),
                    const SizedBox(height: 16),
                    AnalyticsChartCard(
                      title: 'Top Research Journals',
                      showInfoIcon: true,
                      customDropdown: TopSelectorDropdown(
                        value: selectedTopJournals,
                        onChanged: (value) async {
                          setState(() {
                            selectedTopJournals = value;
                          });
                          await _loadTopResearchJournals(limit: value);
                        },
                      ),
                      child: isLoadingJournals || fetchedJournalsData == null
                          ? const SizedBox(
                              height: 260,
                              child: Center(child: CircularProgressIndicator()),
                            )
                          : hasErrorJournals
                              ? SizedBox(
                                  height: 260,
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Text('Failed to load research journals.'),
                                        const SizedBox(height: 16),
                                        ElevatedButton(
                                          onPressed: () => _loadTopResearchJournals(limit: selectedTopJournals),
                                          child: const Text('Retry'),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : fetchedJournalsData!.isEmpty
                                  ? const SizedBox(
                                      height: 260,
                                      child: Center(
                                        child: Text('No research journals available.'),
                                      ),
                                    )
                                  : TopResearchJournalsDonutChart(
                                      journalsData: fetchedJournalsData!,
                                    ),
                    ),
                    const SizedBox(height: 16),
                    AnalyticsChartCard(
                      title: 'Top Contributing Authors',
                      showInfoIcon: true,
                      customDropdown: TopSelectorDropdown(
                        value: selectedTopAuthors,
                        onChanged: (value) async {
                          setState(() {
                            selectedTopAuthors = value;
                          });
                          await _loadTopContributingAuthors(limit: value);
                        },
                      ),
                      child: isLoadingAuthors || fetchedAuthorsData == null
                          ? const SizedBox(
                              height: 260,
                              child: Center(child: CircularProgressIndicator()),
                            )
                          : hasErrorAuthors
                              ? SizedBox(
                                  height: 260,
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Text('Failed to load contributing authors.'),
                                        const SizedBox(height: 16),
                                        ElevatedButton(
                                          onPressed: () => _loadTopContributingAuthors(limit: selectedTopAuthors),
                                          child: const Text('Retry'),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : fetchedAuthorsData!.isEmpty
                                  ? const SizedBox(
                                      height: 260,
                                      child: Center(
                                        child: Text('No contributing authors available.'),
                                      ),
                                    )
                                  : TopContributingAuthorsColumnChart(
                                      authorsData: fetchedAuthorsData!,
                                    ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
