import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/publication_provider.dart';
import '../widgets/analytics_chart_card.dart';
import '../widgets/publication_trend_line_chart.dart';
import '../widgets/top_influential_papers_horizontal_chart.dart';
import '../widgets/top_research_journals_donut_chart.dart';
import '../widgets/top_contributing_authors_column_chart.dart';

class TrendAnalysisScreen extends StatelessWidget {
  const TrendAnalysisScreen({super.key});

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
                      dropdownText: 'Top 5',
                      child: TopInfluentialPapersHorizontalChart(
                        papers: provider.topInfluentialPapers,
                      ),
                    ),
                    const SizedBox(height: 16),
                    AnalyticsChartCard(
                      title: 'Top Research Journals',
                      showInfoIcon: true,
                      dropdownText: 'Top 6',
                      child: TopResearchJournalsDonutChart(
                        journalsData: provider.topJournals,
                      ),
                    ),
                    const SizedBox(height: 16),
                    AnalyticsChartCard(
                      title: 'Top Contributing Authors',
                      showInfoIcon: true,
                      dropdownText: 'Top 10',
                      child: TopContributingAuthorsColumnChart(
                        authorsData: provider.topAuthors,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
