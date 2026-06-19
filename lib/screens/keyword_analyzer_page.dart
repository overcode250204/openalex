import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/keyword/keyword_analysis_paper.dart';
import '../models/keyword/keyword_analysis_result.dart';
import '../models/keyword/openalex_keyword.dart';
import '../viewmodels/keyword_analyzer_view_model.dart';
import '../widgets/analytics_chart_card.dart';
import '../widgets/keyword/keyword_analysis_summary.dart';
import '../widgets/keyword/keyword_paper_list_card.dart';
import '../widgets/keyword/keyword_trend_chart.dart';
import '../widgets/keyword/latest_papers_card.dart';
import '../widgets/keyword/most_cited_papers_card.dart';
import '../widgets/keyword/open_access_papers_card.dart';
import '../widgets/search/keyword_suggestion_dropdown.dart';
import '../widgets/top_contributing_authors_column_chart.dart';
import '../widgets/top_research_journals_donut_chart.dart';
import '../widgets/top_selector_dropdown.dart';
import 'publication_detail_screen.dart';

class KeywordAnalyzerPage extends StatefulWidget {
  final VoidCallback? onOpenDrawer;

  const KeywordAnalyzerPage({super.key, this.onOpenDrawer});

  @override
  State<KeywordAnalyzerPage> createState() => _KeywordAnalyzerPageState();
}

class _KeywordAnalyzerPageState extends State<KeywordAnalyzerPage> {
  final TextEditingController _keywordController = TextEditingController();

  @override
  void dispose() {
    _keywordController.dispose();
    super.dispose();
  }

  Future<void> _analyze() async {
    FocusScope.of(context).unfocus();
    context.read<KeywordAnalyzerViewModel>().hideKeywordSuggestions();
    await context.read<KeywordAnalyzerViewModel>().analyze(
      _keywordController.text,
    );
  }

  Future<void> _analyzeKeyword(String keyword) async {
    FocusScope.of(context).unfocus();
    final viewModel = context.read<KeywordAnalyzerViewModel>();
    viewModel.hideKeywordSuggestions();
    await viewModel.analyze(keyword);
  }

  void _openPaper(KeywordAnalysisPaper paper) {
    if (paper.id.trim().isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PublicationDetailScreen(
          workId: paper.id,
          initialTitle: paper.title,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<KeywordAnalyzerViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text('Keyword Analyzer', overflow: TextOverflow.ellipsis),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: widget.onOpenDrawer,
        ),
      ),
      body: Column(
        children: [
          _KeywordSearchCard(
            controller: _keywordController,
            isLoading: viewModel.isLoading,
            onAnalyze: _analyze,
            onAnalyzeKeyword: _analyzeKeyword,
          ),
          Expanded(
            child: _KeywordAnalyzerBody(
              viewModel: viewModel,
              onRetry: viewModel.retry,
              onPaperTap: _openPaper,
            ),
          ),
        ],
      ),
    );
  }
}

class _KeywordSearchCard extends StatelessWidget {
  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onAnalyze;
  final ValueChanged<String> onAnalyzeKeyword;

  const _KeywordSearchCard({
    required this.controller,
    required this.isLoading,
    required this.onAnalyze,
    required this.onAnalyzeKeyword,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: controller,
              enabled: !isLoading,
              decoration: const InputDecoration(
                labelText: 'Academic keyword',
                hintText: 'Enter a keyword, e.g. machine learning',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => context
                  .read<KeywordAnalyzerViewModel>()
                  .onQueryChanged(value),
              onSubmitted: (_) {
                if (!isLoading) {
                  final keyword = controller.text.trim();
                  context
                      .read<KeywordAnalyzerViewModel>()
                      .hideKeywordSuggestions();
                  if (keyword.isNotEmpty) {
                    onAnalyzeKeyword(keyword);
                  }
                }
              },
            ),
            Consumer<KeywordAnalyzerViewModel>(
              builder: (context, viewModel, _) {
                if (!viewModel.showKeywordSuggestions ||
                    viewModel.keywordSuggestions.isEmpty) {
                  return const SizedBox.shrink();
                }

                return KeywordSuggestionDropdown(
                  suggestions: viewModel.keywordSuggestions,
                  onSelected: (keyword) {
                    controller.text = keyword;
                    viewModel.hideKeywordSuggestions();
                    onAnalyzeKeyword(keyword);
                  },
                );
              },
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: isLoading ? null : onAnalyze,
              icon: const Icon(Icons.analytics),
              label: const Text('Analyze Keyword'),
            ),
          ],
        ),
      ),
    );
  }
}

class _KeywordAnalyzerBody extends StatelessWidget {
  final KeywordAnalyzerViewModel viewModel;
  final Future<void> Function() onRetry;
  final ValueChanged<KeywordAnalysisPaper> onPaperTap;

  const _KeywordAnalyzerBody({
    required this.viewModel,
    required this.onRetry,
    required this.onPaperTap,
  });

  @override
  Widget build(BuildContext context) {
    if (viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (viewModel.errorMessage != null) {
      return _KeywordErrorCard(
        message: viewModel.errorMessage!,
        canRetry: viewModel.keyword.isNotEmpty,
        onRetry: onRetry,
      );
    }

    final result = viewModel.result;
    if (result == null) {
      return const Center(
        child: Text(
          'Enter an academic keyword and tap Analyze Keyword.',
          textAlign: TextAlign.center,
        ),
      );
    }

    if (result.isEmpty) {
      return const Center(
        child: Text(
          'No keyword analysis data found.',
          textAlign: TextAlign.center,
        ),
      );
    }

    return _KeywordDashboard(result: result, onPaperTap: onPaperTap);
  }
}

class _KeywordErrorCard extends StatelessWidget {
  final String message;
  final bool canRetry;
  final Future<void> Function() onRetry;

  const _KeywordErrorCard({
    required this.message,
    required this.canRetry,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        margin: const EdgeInsets.all(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: Colors.red.shade600, size: 36),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              if (canRetry) ...[
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _KeywordDashboard extends StatefulWidget {
  final KeywordAnalysisResult result;
  final ValueChanged<KeywordAnalysisPaper> onPaperTap;

  const _KeywordDashboard({required this.result, required this.onPaperTap});

  @override
  State<_KeywordDashboard> createState() => _KeywordDashboardState();
}

class _KeywordDashboardState extends State<_KeywordDashboard> {
  static const _topOptions = [5, 10, 15, 20];

  int? _topAuthors = 5;
  int? _topJournals = 5;

  Map<String, int> _take(Map<String, int> data, int? limit) =>
      limit == null ? data : Map.fromEntries(data.entries.take(limit));

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Column(
          children: [
            if (result.resolvedKeyword != null) ...[
              _KeywordMatchedCard(
                keyword: result.keyword,
                resolvedKeyword: result.resolvedKeyword!,
              ),
              const SizedBox(height: 16),
            ],
            KeywordAnalysisSummary(result: result),
            const SizedBox(height: 16),
            KeywordTrendChart(keyword: result.keyword, trend: result.trend),
            if (result.topAuthors.isNotEmpty) ...[
              const SizedBox(height: 16),
              AnalyticsChartCard(
                title: 'Top Contributing Authors',
                subtitle: 'Authors with the most publications on this keyword.',
                customDropdown: TopSelectorDropdown(
                  value: _topAuthors,
                  options: _topOptions,
                  onChanged: (v) => setState(() => _topAuthors = v),
                ),
                child: TopContributingAuthorsColumnChart(
                  authorsData: _take(result.topAuthors, _topAuthors),
                ),
              ),
            ],
            if (result.topSources.isNotEmpty) ...[
              const SizedBox(height: 16),
              AnalyticsChartCard(
                title: 'Top Research Journals',
                subtitle: 'Journals publishing the most on this keyword.',
                customDropdown: TopSelectorDropdown(
                  value: _topJournals,
                  options: _topOptions,
                  onChanged: (v) => setState(() => _topJournals = v),
                ),
                child: TopResearchJournalsDonutChart(
                  journalsData: _take(result.topSources, _topJournals),
                ),
              ),
            ],
            const SizedBox(height: 16),
            KeywordPaperListCard(
              title: 'Papers Using This Keyword',
              subtitle:
                  'Papers ranked by how strongly OpenAlex associates them with this keyword.',
              emptyMessage: 'No relevant papers found.',
              papers: result.relevantPapers,
              showKeywordScore: true,
              onPaperTap: widget.onPaperTap,
            ),
            const SizedBox(height: 16),
            MostCitedPapersCard(
              papers: result.mostCitedPapers,
              onPaperTap: widget.onPaperTap,
            ),
            const SizedBox(height: 16),
            LatestPapersCard(
              papers: result.latestPapers,
              onPaperTap: widget.onPaperTap,
            ),
            const SizedBox(height: 16),
            OpenAccessPapersCard(
              papers: result.openAccessPapers,
              onPaperTap: widget.onPaperTap,
            ),
          ],
        ),
      ),
    );
  }
}

class _KeywordMatchedCard extends StatelessWidget {
  final String keyword;
  final OpenAlexKeyword resolvedKeyword;

  const _KeywordMatchedCard({
    required this.keyword,
    required this.resolvedKeyword,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.blue.shade200, width: 1.5),
      ),
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                const Text(
                  'Keyword Matched',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildRow('User input', keyword),
            const SizedBox(height: 4),
            _buildRow('OpenAlex keyword', resolvedKeyword.displayName),
            const SizedBox(height: 4),
            _buildRow('Works count', _formatNumber(resolvedKeyword.worksCount)),
            const SizedBox(height: 4),
            _buildRow(
              'Total citations of works',
              _formatNumber(resolvedKeyword.citedByCount),
              tooltip:
                  'Total citations of all works associated with this keyword according to OpenAlex.',
            ),
          ],
        ),
      ),
    );
  }

  String _formatNumber(int value) {
    return value.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );
  }

  Widget _buildRow(String label, String value, {String? tooltip}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 160,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '$label:',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (tooltip != null) ...[
                const SizedBox(width: 4),
                Tooltip(
                  message: tooltip,
                  child: Icon(
                    Icons.info_outline,
                    size: 14,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
