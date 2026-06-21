import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/search_filter.dart';
import '../providers/analytics_provider.dart';
import '../providers/publication_provider.dart';
import '../services/trend_report_export_service.dart';
import '../widgets/analytics/author_impact_chart.dart';
import '../widgets/analytics/citation_trend_chart.dart';
import '../widgets/analytics/country_output_chart.dart';
import '../widgets/analytics/institution_ranking_chart.dart';
import '../widgets/analytics/top_keywords_chart.dart';
import '../widgets/summary_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String? _lastSignature;
  int? _yearFrom = 2010;
  int? _yearTo = DateTime.now().year;

  /// The base search filter with the dashboard's year range applied on top.
  SearchFilter _effectiveFilter(PublicationProvider provider) {
    final base = provider.filter;
    return SearchFilter(
      yearFrom: _yearFrom,
      yearTo: _yearTo,
      isOpenAccess: base.isOpenAccess,
      language: base.language,
      documentType: base.documentType,
      sortOption: base.sortOption,
    );
  }

  /// Refetches full-dataset analytics whenever the topic or year range changes.
  void _syncAnalytics(PublicationProvider provider) {
    if (provider.publications.isEmpty) return;

    final filter = _effectiveFilter(provider);
    final signature =
        '${provider.currentTopic}|${filter.yearFrom}|${filter.yearTo}';
    if (signature == _lastSignature) return;
    _lastSignature = signature;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AnalyticsProvider>().fetchAnalytics(
        provider.currentTopic,
        filter,
        provider.publications,
      );
    });
  }

  void _onYearFromChanged(int? value) {
    setState(() {
      _yearFrom = value;
      if (_yearFrom != null && _yearTo != null && _yearFrom! > _yearTo!) {
        _yearTo = _yearFrom;
      }
    });
  }

  void _onYearToChanged(int? value) {
    setState(() {
      _yearTo = value;
      if (_yearFrom != null && _yearTo != null && _yearTo! < _yearFrom!) {
        _yearFrom = _yearTo;
      }
    });
  }

  void _clearYears() {
    setState(() {
      _yearFrom = null;
      _yearTo = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PublicationProvider>();
    final analytics = context.watch<AnalyticsProvider>();

    _syncAnalytics(provider);

    final loading = analytics.isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Research Dashboard')),
      body: provider.publications.isEmpty
          ? const Center(child: Text('Search a topic first to view dashboard.'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Dashboard: ${provider.currentTopic}',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                IntrinsicHeight(
                  child: Row(
                    children: [
                      Expanded(
                        child: _MetricTile(
                          label: 'Total Publications',
                          value: loading
                              ? '…'
                              : _compactNumber(
                                  analytics.totalWorks > 0
                                      ? analytics.totalWorks
                                      : provider.totalResults,
                                ),
                          icon: Icons.public,
                          color: Colors.teal,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _MetricTile(
                          label: 'Most Active Year',
                          value: loading
                              ? '…'
                              : (analytics.mostActiveYear?.toString() ?? 'N/A'),
                          icon: Icons.calendar_month,
                          color: Colors.purple,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                IntrinsicHeight(
                  child: Row(
                    children: [
                      Expanded(
                        child: _MetricTile(
                          label: 'Highest Citations',
                          value: loading
                              ? '…'
                              : (analytics.mostCitedCount > 0
                                    ? _compactNumber(analytics.mostCitedCount)
                                    : 'N/A'),
                          icon: Icons.local_fire_department_outlined,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _MetricTile(
                          label: 'Top Keyword',
                          value: loading
                              ? '…'
                              : (analytics.topKeywordName ?? 'N/A'),
                          icon: Icons.tag,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SummaryCard(
                  title: 'Top Journal',
                  value: loading ? '…' : (analytics.topJournalName ?? 'N/A'),
                  icon: Icons.menu_book,
                ),
                SummaryCard(
                  title: 'Top Author',
                  value: loading ? '…' : (analytics.topAuthorName ?? 'N/A'),
                  icon: Icons.person,
                ),
                SummaryCard(
                  title: 'Most Influential Paper',
                  value: loading ? '…' : (analytics.mostCitedTitle ?? 'N/A'),
                  icon: Icons.workspace_premium,
                ),
                const SizedBox(height: 24),
                Text(
                  'Analytics',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Aggregated across the full matching dataset on OpenAlex, '
                  'not just the loaded sample.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 12),
                _YearRangeFilterCard(
                  yearFrom: _yearFrom,
                  yearTo: _yearTo,
                  onFromChanged: _onYearFromChanged,
                  onToChanged: _onYearToChanged,
                  onClear: _clearYears,
                ),
                const SizedBox(height: 16),
                const CitationTrendChart(),
                const SizedBox(height: 16),
                const AuthorImpactChart(),
                const SizedBox(height: 16),
                const TopKeywordsChart(),
                const SizedBox(height: 16),
                const InstitutionRankingChart(),
                const SizedBox(height: 16),
                const CountryOutputChart(),
                const SizedBox(height: 24),
                _ExportTrendReportButton(provider: provider),
              ],
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
        SnackBar(content: Text('Trend report exported: ${result.file.path}')),
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

String _compactNumber(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
  return n.toString();
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final MaterialColor color;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: color.shade700),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

class _YearRangeFilterCard extends StatelessWidget {
  final int? yearFrom;
  final int? yearTo;
  final ValueChanged<int?> onFromChanged;
  final ValueChanged<int?> onToChanged;
  final VoidCallback onClear;

  const _YearRangeFilterCard({
    required this.yearFrom,
    required this.yearTo,
    required this.onFromChanged,
    required this.onToChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final currentYear = DateTime.now().year;
    final years = [for (var y = currentYear; y >= 1970; y--) y];
    final hasFilter = yearFrom != null || yearTo != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.filter_alt_outlined,
                  size: 18,
                  color: Colors.grey.shade700,
                ),
                const SizedBox(width: 6),
                Text(
                  'Filter by year',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (hasFilter)
                  TextButton(onPressed: onClear, child: const Text('Clear')),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _YearDropdown(
                    label: 'From',
                    value: yearFrom,
                    years: years,
                    onChanged: onFromChanged,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _YearDropdown(
                    label: 'To',
                    value: yearTo,
                    years: years,
                    onChanged: onToChanged,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _YearDropdown extends StatelessWidget {
  final String label;
  final int? value;
  final List<int> years;
  final ValueChanged<int?> onChanged;

  const _YearDropdown({
    required this.label,
    required this.value,
    required this.years,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          value: value,
          isExpanded: true,
          isDense: true,
          items: [
            const DropdownMenuItem<int?>(value: null, child: Text('Any')),
            for (final year in years)
              DropdownMenuItem<int?>(value: year, child: Text(year.toString())),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}
