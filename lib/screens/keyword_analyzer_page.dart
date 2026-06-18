import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/keyword/keyword_analysis_paper.dart';
import '../models/keyword/keyword_analysis_result.dart';
import '../viewmodels/keyword_analyzer_view_model.dart';
import '../widgets/keyword/keyword_analysis_summary.dart';
import '../widgets/keyword/keyword_trend_chart.dart';
import '../widgets/keyword/latest_papers_card.dart';
import '../widgets/keyword/most_cited_papers_card.dart';
import '../widgets/keyword/open_access_papers_card.dart';
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
    await context.read<KeywordAnalyzerViewModel>().analyze(
      _keywordController.text,
    );
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

  const _KeywordSearchCard({
    required this.controller,
    required this.isLoading,
    required this.onAnalyze,
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
              onSubmitted: (_) {
                if (!isLoading) {
                  onAnalyze();
                }
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

class _KeywordDashboard extends StatelessWidget {
  final KeywordAnalysisResult result;
  final ValueChanged<KeywordAnalysisPaper> onPaperTap;

  const _KeywordDashboard({required this.result, required this.onPaperTap});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Column(
          children: [
            KeywordAnalysisSummary(result: result),
            const SizedBox(height: 16),
            KeywordTrendChart(keyword: result.keyword, trend: result.trend),
            const SizedBox(height: 16),
            MostCitedPapersCard(
              papers: result.mostCitedPapers,
              onPaperTap: onPaperTap,
            ),
            const SizedBox(height: 16),
            LatestPapersCard(
              papers: result.latestPapers,
              onPaperTap: onPaperTap,
            ),
            const SizedBox(height: 16),
            OpenAccessPapersCard(
              papers: result.openAccessPapers,
              onPaperTap: onPaperTap,
            ),
          ],
        ),
      ),
    );
  }
}
