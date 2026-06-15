import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/publication_provider.dart';
import '../services/trend_report_export_service.dart';
import '../widgets/summary_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PublicationProvider>();
    final mostInfluentialPaper = provider.mostInfluentialPaper;

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
                  'Dashboard: ${provider.currentTopic}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                SummaryCard(
                  title: 'Total Publications',
                  value: provider.totalPublications.toString(),
                  icon: Icons.article,
                ),
                SummaryCard(
                  title: 'Average Citation Count',
                  value: provider.averageCitationCount.toStringAsFixed(2),
                  icon: Icons.format_quote,
                ),
                SummaryCard(
                  title: 'Most Active Publication Year',
                  value: provider.mostActiveYear?.toString() ?? 'N/A',
                  icon: Icons.calendar_month,
                ),
                SummaryCard(
                  title: 'Top Journal',
                  value: provider.topJournal ?? 'N/A',
                  icon: Icons.menu_book,
                ),
                SummaryCard(
                  title: 'Top Author',
                  value: provider.topAuthor ?? 'N/A',
                  icon: Icons.person,
                ),
                SummaryCard(
                  title: 'Most Influential Paper',
                  value: mostInfluentialPaper?.title ?? 'N/A',
                  icon: Icons.workspace_premium,
                ),
                const SizedBox(height: 16),
                _ExportTrendReportButton(provider: provider),
              ],
            ),
    );
  }
}

class _ExportTrendReportButton extends StatefulWidget {
  final PublicationProvider provider;

  const _ExportTrendReportButton({
    required this.provider,
  });

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
