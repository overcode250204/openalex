import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/journal/journal_source.dart';
import '../../routes/app_routes.dart';
import '../../routes/route_arguments.dart';
import '../../utils/app_keys.dart';
import '../../viewmodels/journal_view_model.dart';
import '../../widgets/analytics/analytics_chart_card.dart';
import '../../widgets/journal/journal_ranking_tile.dart';
import '../../widgets/state/app_error_widget.dart';
import '../../widgets/state/empty_state_widget.dart';
import '../../widgets/state/loading_widget.dart';
import '../../widgets/top_research_journals_donut_chart.dart';
import '../../widgets/top_selector_dropdown.dart';

class JournalsScreen extends StatefulWidget {
  const JournalsScreen({super.key});

  @override
  State<JournalsScreen> createState() => _JournalsScreenState();
}

class _JournalsScreenState extends State<JournalsScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<JournalViewModel>().init();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      final vm = context.read<JournalViewModel>();
      if (query.trim().isEmpty) {
        vm.loadTopJournals();
      } else {
        vm.search(query.trim());
      }
    });
  }

  void _openDetail(JournalSource journal) {
    Navigator.pushNamed(
      context,
      AppRoutes.journalDetail,
      arguments: JournalDetailRouteArgs(journal: journal),
    );
  }

  @override
  Widget build(BuildContext context) {
    final journalViewModel = context.watch<JournalViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(title: const Text('Journals')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              key: AppKeys.journalSearchInput,
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search journals by name...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: journalViewModel.query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          context.read<JournalViewModel>().loadTopJournals();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          Expanded(child: _body(journalViewModel)),
        ],
      ),
    );
  }

  Widget _body(JournalViewModel viewModel) {
    if (viewModel.isLoading) {
      return const LoadingWidget(message: 'Loading journals...');
    }

    if (viewModel.error != null) {
      return AppErrorWidget(
        message: viewModel.error!,
        onRetry: () => context.read<JournalViewModel>().loadTopJournals(),
      );
    }

    if (viewModel.journals.isEmpty) {
      return EmptyStateWidget(
        message: viewModel.query.isEmpty
            ? 'No journals available.'
            : 'No journals found for "${viewModel.query}".',
        icon: Icons.menu_book_outlined,
      );
    }

    return _JournalList(
      journals: viewModel.journals,
      query: viewModel.query,
      onJournalTap: _openDetail,
    );
  }
}

class _JournalList extends StatefulWidget {
  final List<JournalSource> journals;
  final String query;
  final ValueChanged<JournalSource> onJournalTap;

  const _JournalList({
    required this.journals,
    required this.query,
    required this.onJournalTap,
  });

  @override
  State<_JournalList> createState() => _JournalListState();
}

class _JournalListState extends State<_JournalList> {
  bool _byCitations = true;
  int _topN = 5;

  static const List<int?> _topNOptions = [3, 5, 7, 10];

  List<JournalSource> get _displayJournals {
    final sorted = [...widget.journals]..sort(
      (a, b) => _byCitations
          ? b.citedByCount.compareTo(a.citedByCount)
          : b.worksCount.compareTo(a.worksCount),
    );
    return sorted.take(_topN).toList();
  }

  Map<String, int> _buildChartData() {
    final sorted = [...widget.journals]..sort(
      (a, b) => _byCitations
          ? b.citedByCount.compareTo(a.citedByCount)
          : b.worksCount.compareTo(a.worksCount),
    );

    final top = sorted.take(_topN).toList();
    final rest = sorted.skip(_topN).toList();

    final data = <String, int>{};
    for (final j in top) {
      final value = _byCitations ? j.citedByCount : j.worksCount;
      if (value > 0) data[j.displayName] = value;
    }
    if (rest.isNotEmpty) {
      final othersValue = rest.fold<int>(
        0,
        (sum, j) => sum + (_byCitations ? j.citedByCount : j.worksCount),
      );
      if (othersValue > 0) data['Others'] = othersValue;
    }
    return data;
  }

  @override
  Widget build(BuildContext context) {
    final displayJournals = _displayJournals;

    return ListView(
      key: const PageStorageKey('journals-list-scroll'),
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          widget.query.isEmpty ? 'Top Journals' : 'Results for "${widget.query}"',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          widget.query.isEmpty
              ? 'Most cited academic journals'
              : '${widget.journals.length} journal${widget.journals.length == 1 ? '' : 's'} found',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
        ),
        if (widget.journals.length >= 2) ...[
          const SizedBox(height: 16),
          _JournalContributionChart(
            journalsData: _buildChartData(),
            byCitations: _byCitations,
            topN: _topN,
            topNOptions: _topNOptions,
            onMetricChanged: (v) => setState(() => _byCitations = v),
            onTopNChanged: (v) => setState(() => _topN = v),
          ),
        ],
        const SizedBox(height: 16),
        KeyedSubtree(
          key: AppKeys.journalList,
          child: Column(
            children: List.generate(displayJournals.length, (index) {
              final journal = displayJournals[index];
              return JournalRankingTile(
                rank: index + 1,
                journal: journal,
                onTap: () => widget.onJournalTap(journal),
              );
            }),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _JournalContributionChart extends StatelessWidget {
  final Map<String, int> journalsData;
  final bool byCitations;
  final int topN;
  final List<int?> topNOptions;
  final ValueChanged<bool> onMetricChanged;
  final ValueChanged<int> onTopNChanged;

  const _JournalContributionChart({
    required this.journalsData,
    required this.byCitations,
    required this.topN,
    required this.topNOptions,
    required this.onMetricChanged,
    required this.onTopNChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AnalyticsChartCard(
      title: 'Journal Contribution',
      subtitle: byCitations
          ? 'Share of citations across journals'
          : 'Share of publications across journals',
      customDropdown: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _MetricDropdown(byCitations: byCitations, onChanged: onMetricChanged),
          const SizedBox(width: 8),
          TopSelectorDropdown(
            value: topN,
            options: topNOptions,
            onChanged: (v) {
              if (v != null) onTopNChanged(v);
            },
          ),
        ],
      ),
      child: TopResearchJournalsDonutChart(
        journalsData: journalsData,
        valueLabel: byCitations ? 'citations' : 'publications',
      ),
    );
  }
}

class _MetricDropdown extends StatelessWidget {
  final bool byCitations;
  final ValueChanged<bool> onChanged;

  const _MetricDropdown({required this.byCitations, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<bool>(
          value: byCitations,
          icon: Icon(
            Icons.keyboard_arrow_down,
            size: 16,
            color: Colors.grey.shade600,
          ),
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
          items: const [
            DropdownMenuItem(value: true, child: Text('Citations')),
            DropdownMenuItem(value: false, child: Text('Publications')),
          ],
        ),
      ),
    );
  }
}
