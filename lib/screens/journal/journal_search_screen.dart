import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/journal/journal_publication.dart';
import '../../models/journal/journal_source.dart';
import '../../providers/journal_search_provider.dart';
import '../../widgets/journal/highest_cited_paper_card.dart';
import '../../widgets/journal/journal_publication_card.dart';
import '../../widgets/journal/journal_source_card.dart';
import 'journal_publication_detail_screen.dart';

class JournalSearchScreen extends StatefulWidget {
  final VoidCallback? onOpenDrawer;

  const JournalSearchScreen({super.key, this.onOpenDrawer});

  @override
  State<JournalSearchScreen> createState() => _JournalSearchScreenState();
}

class _JournalSearchScreenState extends State<JournalSearchScreen> {
  final TextEditingController _queryController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _selectedJournalSectionKey = GlobalKey();

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
    await context.read<JournalSearchProvider>().searchJournals(
      _queryController.text,
    );
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
    await context.read<JournalSearchProvider>().selectJournal(journal);

    if (!mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final selectedContext = _selectedJournalSectionKey.currentContext;
      if (selectedContext == null) return;

      Scrollable.ensureVisible(
        selectedContext,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
        alignment: 0.05,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<JournalSearchProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text('Journal Search', overflow: TextOverflow.ellipsis),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: widget.onOpenDrawer,
        ),
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: (scroll) {
          if (scroll.metrics.pixels >= scroll.metrics.maxScrollExtent - 180) {
            provider.loadMorePublications();
          }
          return false;
        },
        child: ListView(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          children: [
            _SearchCard(
              controller: _queryController,
              isLoading: provider.isSearchingJournals,
              onSearch: _search,
            ),
            const SizedBox(height: 16),
            if (provider.errorMessage != null) ...[
              _MessageCard(message: provider.errorMessage!),
              const SizedBox(height: 16),
            ],
            _JournalResultsSection(
              provider: provider,
              onSelect: _selectJournal,
            ),
            if (provider.selectedJournal != null) ...[
              const SizedBox(height: 16),
              KeyedSubtree(
                key: _selectedJournalSectionKey,
                child: Column(
                  children: [
                    _SelectedJournalCard(journal: provider.selectedJournal!),
                    const SizedBox(height: 16),
                    HighestCitedPaperCard(
                      publication: provider.highestCitedPaper,
                      isLoading: provider.isLoadingHighestCited,
                      onViewDetail: provider.highestCitedPaper == null
                          ? null
                          : () => _openPublication(provider.highestCitedPaper!),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _PublicationSection(
                provider: provider,
                onViewDetail: _openPublication,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SearchCard extends StatelessWidget {
  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onSearch;

  const _SearchCard({
    required this.controller,
    required this.isLoading,
    required this.onSearch,
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
                hintText: 'Example: IEEE Access, Nature, PLOS ONE',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onSubmitted: (_) {
                if (!isLoading) {
                  onSearch();
                }
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
              label: Text(isLoading ? 'Searching' : 'Search'),
            ),
          ],
        ),
      ),
    );
  }
}

class _JournalResultsSection extends StatelessWidget {
  final JournalSearchProvider provider;
  final ValueChanged<JournalSource> onSelect;

  const _JournalResultsSection({
    required this.provider,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (provider.isSearchingJournals) {
      return const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (provider.journals.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Journal Results',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...provider.journals.map(
          (journal) => JournalSourceCard(
            journal: journal,
            isSelected: provider.selectedJournal?.id == journal.id,
            onSelect: () => onSelect(journal),
          ),
        ),
      ],
    );
  }
}

class _SelectedJournalCard extends StatelessWidget {
  final JournalSource journal;

  const _SelectedJournalCard({required this.journal});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: Colors.blue.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.blue.shade100),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selected Journal',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        journal.displayName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _SelectedRow(label: 'Type', value: journal.type),
            _SelectedRow(label: 'ISSN-L', value: journal.displayIssnL),
            _SelectedRow(label: 'Works', value: journal.worksCount.toString()),
            _SelectedRow(
              label: 'Citations',
              value: journal.citedByCount.toString(),
            ),
            _SelectedRow(label: 'Publisher', value: journal.displayPublisher),
            _SelectedRow(
              label: 'H-index',
              value: journal.hIndex?.toString() ?? 'N/A',
            ),
            _SelectedRow(label: 'OpenAlex ID', value: journal.id),
          ],
        ),
      ),
    );
  }
}

class _SelectedRow extends StatelessWidget {
  final String label;
  final String value;

  const _SelectedRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              '$label:',
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _PublicationSection extends StatelessWidget {
  final JournalSearchProvider provider;
  final ValueChanged<JournalPublication> onViewDetail;

  const _PublicationSection({
    required this.provider,
    required this.onViewDetail,
  });

  @override
  Widget build(BuildContext context) {
    if (provider.isLoadingPublications) {
      return const SizedBox(
        height: 180,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (provider.publications.isEmpty) {
      return const _MessageCard(
        message: 'This journal has no publications in OpenAlex.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Journal Publications',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...provider.publications.map(
          (publication) => JournalPublicationCard(
            publication: publication,
            onViewDetail: () => onViewDetail(publication),
          ),
        ),
        if (provider.isLoadingMorePublications)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
}

class _MessageCard extends StatelessWidget {
  final String message;

  const _MessageCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue.shade700),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}
