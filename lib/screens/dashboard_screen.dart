import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/publication_provider.dart';
import '../services/trend_report_export_service.dart';
import '../widgets/summary_card.dart';
import '../widgets/top_journals_bar_chart.dart';
import 'publication_detail_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PublicationProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Research Dashboard'),
      ),
      body: provider.publications.isEmpty
          ? const Center(
              child: Text('Search a topic first to view dashboard.'),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  provider.currentTopic,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${provider.totalPublications} publications analysed',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.grey),
                ),
                const SizedBox(height: 20),

                // --- Section A: 2x3 stat grid ---
                GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.5,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    SummaryCard(
                      title: 'Total Publications',
                      value: provider.totalPublications.toString(),
                      icon: Icons.article,
                      color: Colors.blue,
                      subtitle: 'papers found',
                    ),
                    SummaryCard(
                      title: 'Total Citations',
                      value: provider.totalCitations.toString(),
                      icon: Icons.format_quote,
                      color: Colors.orange,
                      subtitle: 'across all papers',
                    ),
                    SummaryCard(
                      title: 'Avg Citations',
                      value: provider.averageCitationCount.toStringAsFixed(1),
                      icon: Icons.analytics,
                      color: Colors.green,
                      subtitle: 'per paper',
                    ),
                    SummaryCard(
                      title: 'Citation Median',
                      value: provider.citationMedian.toString(),
                      icon: Icons.assessment,
                      color: Colors.teal,
                      subtitle: '50th percentile',
                    ),
                    SummaryCard(
                      title: 'Peak Year',
                      value: provider.mostActiveYear?.toString() ?? 'N/A',
                      icon: Icons.calendar_month,
                      color: Colors.purple,
                      subtitle: 'most publications',
                    ),
                    SummaryCard(
                      title: 'Growth Rate',
                      value:
                          '${provider.publicationGrowthRate >= 0 ? '+' : ''}${provider.publicationGrowthRate.toStringAsFixed(1)}%',
                      icon: Icons.trending_up,
                      color: Colors.red,
                      subtitle: 'first → last year',
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // --- Section B: Most Influential Paper ---
                _MostInfluentialPaperCard(provider: provider),

                const SizedBox(height: 16),

                // --- Section C: Top Journals Bar Chart ---
                TopJournalsBarChart(topJournals: provider.topJournals),

                const SizedBox(height: 16),

                // --- Section D: Top Journal & Author summary ---
                Row(
                  children: [
                    Expanded(
                      child: SummaryCard(
                        title: 'Top Journal',
                        value: provider.topJournal ?? 'N/A',
                        icon: Icons.menu_book,
                        color: Colors.indigo,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SummaryCard(
                        title: 'Top Author',
                        value: provider.topAuthor ?? 'N/A',
                        icon: Icons.person,
                        color: Colors.brown,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // --- Export Button ---
                _ExportTrendReportButton(provider: provider),
              ],
            ),
    );
  }
}

class _MostInfluentialPaperCard extends StatelessWidget {
  final PublicationProvider provider;

  const _MostInfluentialPaperCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    final paper = provider.mostInfluentialPaper;
    if (paper == null) return const SizedBox.shrink();

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PublicationDetailScreen(publication: paper),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.workspace_premium,
                    color: Colors.amber[700],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Most Influential Paper',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.amber[700],
                        ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${paper.citedByCount} citations',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber[800],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                paper.title,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                paper.displayAuthors,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey[600]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '${paper.displayYear} · ${paper.displayJournal}',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExportTrendReportButton extends StatefulWidget {
  final PublicationProvider provider;

  const _ExportTrendReportButton({required this.provider});

  @override
  State<_ExportTrendReportButton> createState() =>
      _ExportTrendReportButtonState();
}

class _ExportTrendReportButtonState extends State<_ExportTrendReportButton> {
  static const TrendReportExportService _exportService =
      TrendReportExportService();

  bool _isExporting = false;

  Future<void> _exportReport() async {
    setState(() {
      _isExporting = true;
    });

    try {
      final result = await _exportService.exportMarkdownReport(
        widget.provider.trendReportSnapshot,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Trend report exported: ${result.file.path}'),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot export trend report: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: _isExporting ? null : _exportReport,
      icon: _isExporting
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.description),
      label: Text(_isExporting ? 'Exporting Report' : 'Export Trend Report'),
    );
  }
}
