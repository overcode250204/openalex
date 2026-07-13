import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/report/report_upload_result.dart';
import '../../models/search/search_filter.dart';
import '../../routes/app_routes.dart';
import '../../routes/route_arguments.dart';
import '../../services/openalex_service.dart';
import '../../viewmodels/analytics_view_model.dart';
import '../../viewmodels/dashboard_view_model.dart';
import '../../viewmodels/home_view_model.dart';
import '../../utils/app_keys.dart';
import '../../widgets/analytics/analytics_chart_card.dart';
import '../../widgets/analytics/author_impact_chart.dart';
import '../../widgets/analytics/citation_trend_chart.dart';
import '../../widgets/analytics/country_output_chart.dart';
import '../../widgets/analytics/institution_ranking_chart.dart';
import '../../widgets/analytics/top_keywords_chart.dart';
import '../../widgets/analytics/topic_summary_grid.dart';
import '../../widgets/publication_trend_line_chart.dart';
import '../../widgets/top_contributing_authors_column_chart.dart';
import '../../widgets/top_influential_papers_horizontal_chart.dart';
import '../../widgets/top_research_journals_donut_chart.dart';
import '../../widgets/top_selector_dropdown.dart';

class DashboardScreen extends StatefulWidget {
  final TopicAnalyticsRouteArgs arguments;

  const DashboardScreen({super.key, required this.arguments});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String? _lastSignature;
  String? _lastTrendSignature;
  int? _yearFrom = 2010;
  int? _yearTo = DateTime.now().year;
  int? _selectedTopPapers = 5;
  int? _selectedTopJournals = 10;
  int? _selectedTopAuthors = 10;
  Map<int, int>? _fetchedTrendData;
  Map<String, int>? _fetchedJournalsData;
  Map<String, int>? _fetchedAuthorsData;
  bool _isLoadingTrend = false;
  bool _hasErrorTrend = false;
  bool _isLoadingJournals = false;
  bool _hasErrorJournals = false;
  bool _isLoadingAuthors = false;
  bool _hasErrorAuthors = false;
  bool _isFirstSyncScheduled = false;

  /// The base search filter with the dashboard's year range applied on top.
  SearchFilter _effectiveFilter() {
    return SearchFilter(yearFrom: _yearFrom, yearTo: _yearTo);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Chỉ schedule lần đầu — sau đó các callback onChange sẽ gọi trực tiếp.
    if (_isFirstSyncScheduled) return;
    _isFirstSyncScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncAnalytics();
      _syncTrendSections();
    });
  }

  /// Refetches full-dataset analytics whenever the topic or year range changes.
  /// KHÔNG gọi trong build() — chỉ gọi từ lifecycle hooks và onChange callbacks.
  void _syncAnalytics() {
    final filter = _effectiveFilter();
    final signature =
        '${widget.arguments.topicId}|${filter.yearFrom}|${filter.yearTo}';
    if (signature == _lastSignature) return;
    _lastSignature = signature;

    if (!mounted) return;
    context.read<AnalyticsViewModel>().fetchAnalytics(
      widget.arguments.topicName,
      filter,
      const [],
      topicId: widget.arguments.topicId,
    );
  }

  void _syncTrendSections() {
    final signature =
        '${widget.arguments.topicId}|${widget.arguments.topicName}|'
        '${_yearFrom ?? ''}|${_yearTo ?? ''}';
    if (signature == _lastTrendSignature) return;
    _lastTrendSignature = signature;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadTrendSections();
    });
  }

  Future<void> _loadTrendSections() async {
    await Future.wait([
      _loadPublicationTrend(),
      _loadTopResearchJournals(limit: _selectedTopJournals),
      _loadTopContributingAuthors(limit: _selectedTopAuthors),
    ]);
  }

  Future<void> _loadPublicationTrend() async {
    if (widget.arguments.topicName.trim().isEmpty) return;
    setState(() {
      _isLoadingTrend = true;
      _hasErrorTrend = false;
    });

    try {
      final data = await context.read<OpenAlexService>().fetchPublicationTrend(
        keyword: widget.arguments.topicName,
        topicId: widget.arguments.topicId,
        fromYear: _yearFrom ?? 2010,
        toYear: _yearTo,
      );
      if (!mounted) return;
      setState(() => _fetchedTrendData = data);
    } catch (_) {
      if (!mounted) return;
      setState(() => _hasErrorTrend = true);
    } finally {
      if (mounted) {
        setState(() => _isLoadingTrend = false);
      }
    }
  }

  Future<void> _loadTopResearchJournals({int? limit}) async {
    if (widget.arguments.topicName.trim().isEmpty) return;
    setState(() {
      _isLoadingJournals = true;
      _hasErrorJournals = false;
    });

    try {
      final data = await context
          .read<OpenAlexService>()
          .fetchTopResearchJournals(
            keyword: widget.arguments.topicName,
            limit: limit,
            topicId: widget.arguments.topicId,
            fromYear: _yearFrom ?? 2010,
            toYear: _yearTo,
          );
      if (!mounted) return;
      setState(() => _fetchedJournalsData = data);
    } catch (_) {
      if (!mounted) return;
      setState(() => _hasErrorJournals = true);
    } finally {
      if (mounted) {
        setState(() => _isLoadingJournals = false);
      }
    }
  }

  Future<void> _loadTopContributingAuthors({int? limit}) async {
    if (widget.arguments.topicName.trim().isEmpty) return;
    setState(() {
      _isLoadingAuthors = true;
      _hasErrorAuthors = false;
    });

    try {
      final data = await context
          .read<OpenAlexService>()
          .fetchTopContributingAuthors(
            keyword: widget.arguments.topicName,
            limit: limit,
            topicId: widget.arguments.topicId,
            fromYear: _yearFrom ?? 2010,
            toYear: _yearTo,
          );
      if (!mounted) return;
      setState(() => _fetchedAuthorsData = data);
    } catch (_) {
      if (!mounted) return;
      setState(() => _hasErrorAuthors = true);
    } finally {
      if (mounted) {
        setState(() => _isLoadingAuthors = false);
      }
    }
  }

  void _onYearFromChanged(int? value) {
    setState(() {
      _yearFrom = value;
      if (_yearFrom != null && _yearTo != null && _yearFrom! > _yearTo!) {
        _yearTo = _yearFrom;
      }
      _lastTrendSignature = null;
    });
    _syncAnalytics();
    _syncTrendSections();
  }

  void _onYearToChanged(int? value) {
    setState(() {
      _yearTo = value;
      if (_yearFrom != null && _yearTo != null && _yearTo! < _yearFrom!) {
        _yearFrom = _yearTo;
      }
      _lastTrendSignature = null;
    });
    _syncAnalytics();
    _syncTrendSections();
  }

  void _clearYears() {
    setState(() {
      _yearFrom = 2010;
      _yearTo = DateTime.now().year;
      _lastTrendSignature = null;
    });
    _syncAnalytics();
    _syncTrendSections();
  }

  void _updateTopPapers(int? limit) {
    setState(() => _selectedTopPapers = limit);
  }

  Future<void> _updateTopJournals(int? limit) async {
    setState(() => _selectedTopJournals = limit);
    await _loadTopResearchJournals(limit: limit);
  }

  Future<void> _updateTopAuthors(int? limit) async {
    setState(() => _selectedTopAuthors = limit);
    await _loadTopContributingAuthors(limit: limit);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HomeViewModel>();
    final analytics = context.watch<AnalyticsViewModel>();

    final loading = analytics.isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Research Dashboard')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Dashboard: ${widget.arguments.topicName}',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (analytics.error != null) ...[
            _AnalyticsErrorBanner(
              onRetry: () {
                _lastSignature = null;
                _syncAnalytics();
              },
            ),
            const SizedBox(height: 12),
          ],
          TopicSummaryGrid(
            isLoading: loading,
            totalPublications: analytics.hasLoaded
                ? _compactNumber(analytics.totalWorks)
                : 'N/A',
            averageCitations:
                analytics.averageCitations?.toStringAsFixed(1) ?? 'N/A',
            averageCitationsLabel: analytics.averageCitationsLabel,
            mostActiveYear: analytics.mostActiveYear?.toString() ?? 'N/A',
            topAuthor: analytics.topAuthorName ?? 'N/A',
            topJournal: analytics.topJournalName ?? 'N/A',
            mostInfluentialPaper: analytics.mostCitedTitle ?? 'N/A',
            influentialPaperDetails: _influentialPaperDetails(analytics),
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
          Text(
            'Trend Sections',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Detailed trend views use the same year range as the dashboard '
            'summary.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 12),
          AnalyticsChartCard(
            title: 'Publication Trend: ${widget.arguments.topicName}',
            child: _isLoadingTrend
                ? const SizedBox(
                    height: 300,
                    child: Center(child: CircularProgressIndicator()),
                  )
                : _hasErrorTrend
                ? SizedBox(
                    height: 300,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Failed to load publication trend.'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadPublicationTrend,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                : (_fetchedTrendData == null || _fetchedTrendData!.isEmpty)
                ? const SizedBox(
                    height: 300,
                    child: Center(
                      child: Text('No publication trend data available.'),
                    ),
                  )
                : PublicationTrendLineChart(data: _fetchedTrendData!),
          ),
          const SizedBox(height: 16),
          AnalyticsChartCard(
            title: 'Top Influential Papers',
            showInfoIcon: true,
            customDropdown: TopSelectorDropdown(
              value: _selectedTopPapers,
              onChanged: _updateTopPapers,
            ),
            child: loading || (!analytics.hasLoaded && analytics.error == null)
                ? const SizedBox(
                    height: 260,
                    child: Center(child: CircularProgressIndicator()),
                  )
                : analytics.topInfluentialPapers.isEmpty
                ? const SizedBox(
                    height: 260,
                    child: Center(
                      child: Text('No influential papers available.'),
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8.0, left: 4.0),
                        child: Text(
                          'Influential',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      TopInfluentialPapersHorizontalChart(
                        papers: analytics.topInfluentialPapers
                            .take(_selectedTopPapers ?? 5)
                            .toList(),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 16),
          AnalyticsChartCard(
            title: 'Top Research Journals',
            showInfoIcon: true,
            customDropdown: TopSelectorDropdown(
              value: _selectedTopJournals,
              onChanged: _updateTopJournals,
            ),
            child: _isLoadingJournals || _fetchedJournalsData == null
                ? const SizedBox(
                    height: 260,
                    child: Center(child: CircularProgressIndicator()),
                  )
                : _hasErrorJournals
                ? SizedBox(
                    height: 260,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Failed to load research journals.'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => _loadTopResearchJournals(
                              limit: _selectedTopJournals,
                            ),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                : _fetchedJournalsData!.isEmpty
                ? const SizedBox(
                    height: 260,
                    child: Center(
                      child: Text('No research journals available.'),
                    ),
                  )
                : TopResearchJournalsDonutChart(
                    journalsData: _fetchedJournalsData!,
                  ),
          ),
          const SizedBox(height: 16),
          AnalyticsChartCard(
            title: 'Top Contributing Authors',
            showInfoIcon: true,
            customDropdown: TopSelectorDropdown(
              value: _selectedTopAuthors,
              onChanged: _updateTopAuthors,
            ),
            child: _isLoadingAuthors || _fetchedAuthorsData == null
                ? const SizedBox(
                    height: 260,
                    child: Center(child: CircularProgressIndicator()),
                  )
                : _hasErrorAuthors
                ? SizedBox(
                    height: 260,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Failed to load contributing authors.'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => _loadTopContributingAuthors(
                              limit: _selectedTopAuthors,
                            ),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                : _fetchedAuthorsData!.isEmpty
                ? const SizedBox(
                    height: 260,
                    child: Center(
                      child: Text('No contributing authors available.'),
                    ),
                  )
                : TopContributingAuthorsColumnChart(
                    authorsData: _cleanAuthorData(_fetchedAuthorsData!),
                  ),
          ),
          const SizedBox(height: 24),
          _ExportTrendReportButton(provider: provider),
          const SizedBox(height: 12),
          const _UploadedPdfLinkCard(),
        ],
      ),
    );
  }
}

class _ExportTrendReportButton extends StatefulWidget {
  final HomeViewModel provider;

  const _ExportTrendReportButton({required this.provider});

  @override
  State<_ExportTrendReportButton> createState() =>
      _ExportTrendReportButtonState();
}

class _ExportTrendReportButtonState extends State<_ExportTrendReportButton> {
  Future<void> _exportReport() async {
    try {
      final result = await context
          .read<DashboardViewModel>()
          .exportAndUploadDashboardPdfReport(
            widget.provider.trendReportSnapshot,
          );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Dashboard PDF uploaded: ${result.uploadResult.downloadUrl}',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot upload dashboard PDF: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isExporting = context.watch<DashboardViewModel>().isExporting;
    return FilledButton.icon(
      key: AppKeys.exportPdfButton,
      onPressed: isExporting ? null : _exportReport,
      icon: isExporting
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.cloud_upload_outlined),
      label: Text(isExporting ? 'Uploading PDF' : 'Upload PDF Report'),
    );
  }
}

class _UploadedPdfLinkCard extends StatelessWidget {
  const _UploadedPdfLinkCard();

  Future<void> _copyLink(BuildContext context, String url) async {
    await Clipboard.setData(ClipboardData(text: url));
    if (!context.mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('PDF link copied')));
  }

  Future<void> _openLink(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid PDF link')));
      return;
    }

    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!context.mounted || opened) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Cannot open PDF link')));
  }

  @override
  Widget build(BuildContext context) {
    final report = context.select<DashboardViewModel, ReportUploadResult?>(
      (viewModel) => viewModel.lastUploadedPdfReport,
    );
    if (report == null) return const SizedBox.shrink();

    final uploadedAt = report.uploadedAt.toLocal();
    final uploadedAtText =
        '${uploadedAt.year}-'
        '${_twoDigits(uploadedAt.month)}-'
        '${_twoDigits(uploadedAt.day)} '
        '${_twoDigits(uploadedAt.hour)}:'
        '${_twoDigits(uploadedAt.minute)}';

    return Card(
      key: AppKeys.uploadedPdfLinkCard,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.picture_as_pdf_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Uploaded PDF report',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${report.fileName} - ${_formatBytes(report.sizeBytes)} - $uploadedAtText',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  key: AppKeys.uploadedPdfDismissButton,
                  tooltip: 'Hide PDF link',
                  onPressed: () => context
                      .read<DashboardViewModel>()
                      .clearUploadedPdfReport(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SelectableText(
              report.downloadUrl,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  key: AppKeys.uploadedPdfCopyButton,
                  onPressed: () => _copyLink(context, report.downloadUrl),
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('Copy link'),
                ),
                FilledButton.icon(
                  key: AppKeys.uploadedPdfOpenButton,
                  onPressed: () => _openLink(context, report.downloadUrl),
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: const Text('Open PDF'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _compactNumber(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
  return n.toString();
}

String _formatBytes(int bytes) {
  if (bytes >= 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  if (bytes >= 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }

  return '$bytes B';
}

String _twoDigits(int number) => number.toString().padLeft(2, '0');

String? _influentialPaperDetails(AnalyticsViewModel analytics) {
  final paper = analytics.mostInfluentialPaper;
  if (paper == null) return null;
  final year = paper.publicationYear?.toString() ?? 'Unknown year';
  return '${_compactNumber(paper.citedByCount)} citations - $year';
}

Map<String, int> _cleanAuthorData(Map<String, int> authors) {
  final cleanedEntries = authors.entries.where((entry) {
    final name = entry.key.trim().toLowerCase();
    final isUrl =
        name.startsWith('http') ||
        name.startsWith('www.') ||
        name.contains('://') ||
        RegExp(r'\.(com|org|net|io|edu|gov)\b').hasMatch(name);
    return name.isNotEmpty &&
        !isUrl &&
        name != 'unknown' &&
        name != 'unknown author';
  }).toList()..sort((a, b) => b.value.compareTo(a.value));
  return Map<String, int>.fromEntries(cleanedEntries);
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
            const Expanded(child: Text('Unable to load topic analytics.')),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
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
