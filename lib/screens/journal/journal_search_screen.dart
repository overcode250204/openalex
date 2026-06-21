import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/journal/journal_publication.dart';
import '../../models/journal/journal_source.dart';
import '../../providers/journal_search_provider.dart';
import '../../widgets/journal/highest_cited_paper_card.dart';
import '../../widgets/journal/journal_publication_card.dart';
import '../../widgets/journal/journal_source_card.dart';
import '../../widgets/search/journal_suggestion_dropdown.dart';
import 'journal_publication_detail_screen.dart';

String _formatCount(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(0)}k';
  return n.toString();
}

class JournalSearchScreen extends StatefulWidget {
  const JournalSearchScreen({super.key});

  @override
  State<JournalSearchScreen> createState() => _JournalSearchScreenState();
}

class _JournalSearchScreenState extends State<JournalSearchScreen> {
  final TextEditingController _queryController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _queryController.text = 'IEEE Access';
  }

  @override
  void dispose() {
    _queryController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    FocusScope.of(context).unfocus();
    final provider = context.read<JournalSearchProvider>();
    provider.hideJournalSuggestions();
    await provider.searchJournals(_queryController.text);
  }

  void _openPublication(JournalPublication publication) {
    context.read<JournalSearchProvider>().selectPublication(publication);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            JournalPublicationDetailScreen(publication: publication),
      ),
    );
  }

  Future<void> _selectJournal(JournalSource journal) async {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
    await context.read<JournalSearchProvider>().selectJournal(journal);
  }

  void _clearSelection() {
    context.read<JournalSearchProvider>().clearSelection();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<JournalSearchProvider>();
    final hasSelection = provider.selectedJournal != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text('Journal Search', overflow: TextOverflow.ellipsis),
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: (scroll) {
          if (hasSelection &&
              scroll.metrics.pixels >= scroll.metrics.maxScrollExtent - 180) {
            provider.loadMorePublications();
          }
          return false;
        },
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: hasSelection
              ? _JournalDetailView(
                  key: const ValueKey('detail'),
                  scrollController: _scrollController,
                  provider: provider,
                  onBack: _clearSelection,
                  onOpenPublication: _openPublication,
                )
              : _JournalSearchView(
                  key: const ValueKey('search'),
                  scrollController: _scrollController,
                  provider: provider,
                  queryController: _queryController,
                  onSearch: _search,
                  onSelect: _selectJournal,
                ),
        ),
      ),
    );
  }
}

class _JournalSearchView extends StatelessWidget {
  final ScrollController scrollController;
  final JournalSearchProvider provider;
  final TextEditingController queryController;
  final VoidCallback onSearch;
  final ValueChanged<JournalSource> onSelect;

  const _JournalSearchView({
    super.key,
    required this.scrollController,
    required this.provider,
    required this.queryController,
    required this.onSearch,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      children: [
        _SearchBar(
          controller: queryController,
          isLoading: provider.isSearchingJournals,
          onSearch: onSearch,
          onChanged: provider.onJournalQueryChanged,
          onSubmitted: (_) {
            provider.hideJournalSuggestions();
            if (!provider.isSearchingJournals) onSearch();
          },
        ),
        // Journal suggestion dropdown
        if (provider.showJournalSuggestions)
          JournalSuggestionDropdown(
            isLoading: provider.isLoadingJournalSuggestions,
            suggestions: provider.journalSuggestions,
            onSelected: (journal) {
              queryController.text = journal.displayName;
              provider.hideJournalSuggestions();
              FocusScope.of(context).unfocus();
              // Search by display name so provider resolves the full source
              provider.searchJournals(journal.displayName);
            },
          ),
        const SizedBox(height: 16),
        if (provider.errorMessage != null) ...[
          _InfoBanner(message: provider.errorMessage!, isError: true),
          const SizedBox(height: 16),
        ],
        if (provider.isSearchingJournals)
          const SizedBox(
            height: 160,
            child: Center(child: CircularProgressIndicator()),
          )
        else if (provider.journals.isNotEmpty) ...[
          _SectionHeader(
            title: 'Results (${provider.journals.length})',
            subtitle: 'Tap a journal to explore its publications',
          ),
          const SizedBox(height: 12),
          ...provider.journals.map(
            (journal) => JournalSourceCard(
              journal: journal,
              isSelected: false,
              onSelect: () => onSelect(journal),
            ),
          ),
        ] else if (provider.searchQuery.isNotEmpty)
          const SizedBox(
            height: 200,
            child: Center(
              child: Text(
                'No journals found.\nTry a different name.',
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          const SizedBox(
            height: 200,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.search, size: 52, color: Colors.black26),
                  SizedBox(height: 12),
                  Text(
                    'Search for a journal to get started',
                    style: TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _JournalDetailView extends StatelessWidget {
  final ScrollController scrollController;
  final JournalSearchProvider provider;
  final VoidCallback onBack;
  final ValueChanged<JournalPublication> onOpenPublication;

  const _JournalDetailView({
    super.key,
    required this.scrollController,
    required this.provider,
    required this.onBack,
    required this.onOpenPublication,
  });

  @override
  Widget build(BuildContext context) {
    final journal = provider.selectedJournal!;

    return CustomScrollView(
      controller: scrollController,
      slivers: [
        SliverAppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          surfaceTintColor: Colors.transparent,
          pinned: true,
          expandedHeight: 112,
          collapsedHeight: 64,
          flexibleSpace: FlexibleSpaceBar(
            collapseMode: CollapseMode.pin,
            background: _JournalHeaderBanner(journal: journal, onBack: onBack),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _StatsRow(journal: journal),
              const SizedBox(height: 16),
              HighestCitedPaperCard(
                publication: provider.highestCitedPaper,
                isLoading: provider.isLoadingHighestCited,
                onViewDetail: provider.highestCitedPaper == null
                    ? null
                    : () => onOpenPublication(provider.highestCitedPaper!),
              ),
              const SizedBox(height: 20),
              _SectionHeader(
                title: 'Publications',
                subtitle:
                    '${_formatCount(journal.worksCount)} works in OpenAlex',
              ),
              const SizedBox(height: 12),
            ]),
          ),
        ),
        if (provider.isLoadingPublications)
          const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          )
        else if (provider.publications.isEmpty)
          const SliverFillRemaining(
            child: Center(
              child: Text('No publications found for this journal.'),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                if (index == provider.publications.length) {
                  return provider.isLoadingMorePublications
                      ? const Padding(
                          padding: EdgeInsets.all(20),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : const SizedBox(height: 24);
                }
                return JournalPublicationCard(
                  publication: provider.publications[index],
                  onViewDetail: () =>
                      onOpenPublication(provider.publications[index]),
                );
              }, childCount: provider.publications.length + 1),
            ),
          ),
      ],
    );
  }
}

class _JournalHeaderBanner extends StatelessWidget {
  final JournalSource journal;
  final VoidCallback onBack;

  const _JournalHeaderBanner({required this.journal, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      color: scheme.primaryContainer,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: onBack,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(Icons.arrow_back, color: scheme.onPrimaryContainer),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    journal.displayName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    journal.type,
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onPrimaryContainer.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final JournalSource journal;

  const _StatsRow({required this.journal});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _StatChip(
          icon: Icons.article_outlined,
          label: '${_formatCount(journal.worksCount)} works',
          color: Colors.blue,
        ),
        _StatChip(
          icon: Icons.format_quote,
          label: '${_formatCount(journal.citedByCount)} citations',
          color: Colors.orange,
        ),
        if (journal.hIndex != null)
          _StatChip(
            icon: Icons.leaderboard_outlined,
            label: 'H-index ${journal.hIndex}',
            color: Colors.purple,
          ),
        if (journal.issnL != null)
          _StatChip(
            icon: Icons.confirmation_number_outlined,
            label: journal.displayIssnL,
            color: Colors.teal,
          ),
        _StatChip(
          icon: Icons.business_outlined,
          label: journal.displayPublisher,
          color: Colors.brown,
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final MaterialColor color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color.shade700),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color.shade800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onSearch;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  const _SearchBar({
    required this.controller,
    required this.isLoading,
    required this.onSearch,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: controller,
              enabled: !isLoading,
              decoration: const InputDecoration(
                labelText: 'Journal name',
                hintText: 'e.g. IEEE Access, Nature, PLOS ONE',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: onChanged,
              onSubmitted:
                  onSubmitted ??
                  (_) {
                    if (!isLoading) onSearch();
                  },
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: isLoading ? null : onSearch,
              icon: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.manage_search),
              label: Text(isLoading ? 'Searching…' : 'Search'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;

  const _SectionHeader({required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle!,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
          ),
        ],
      ],
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final String message;
  final bool isError;

  const _InfoBanner({required this.message, this.isError = false});

  @override
  Widget build(BuildContext context) {
    final color = isError ? Colors.red : Colors.blue;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.shade100),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.info_outline,
            color: color.shade700,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, style: TextStyle(color: color.shade800)),
          ),
        ],
      ),
    );
  }
}
