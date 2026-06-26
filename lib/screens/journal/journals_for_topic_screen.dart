import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/journal/journal_source.dart';
import '../../viewmodels/journal_view_model.dart';
import '../../viewmodels/journals_for_topic_view_model.dart';
import '../../viewmodels/selected_topic_view_model.dart';
import '../../widgets/journal/journal_source_card.dart';
import '../../widgets/state/empty_state_widget.dart';
import '../../widgets/state/loading_widget.dart';
import 'journal_search_screen.dart';

class JournalsForTopicScreen extends StatefulWidget {
  const JournalsForTopicScreen({super.key});

  @override
  State<JournalsForTopicScreen> createState() =>
      _JournalsForTopicScreenState();
}

class _JournalsForTopicScreenState extends State<JournalsForTopicScreen> {
  late final SelectedTopicViewModel _selectedTopicViewModel;

  @override
  void initState() {
    super.initState();
    _selectedTopicViewModel = context.read<SelectedTopicViewModel>();
    _selectedTopicViewModel.addListener(_load);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _selectedTopicViewModel.removeListener(_load);
    super.dispose();
  }

  void _load() {
    if (!mounted) return;
    context.read<JournalsForTopicViewModel>().loadForTopic(
      _selectedTopicViewModel,
    );
  }

  void _openJournalSearch() {
    // Explicit "search by name" should start from the search view, not
    // wherever JournalViewModel's selection was last left.
    context.read<JournalViewModel>().clearSelection();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const JournalSearchScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedTopic = context.watch<SelectedTopicViewModel>();
    final viewModel = context.watch<JournalsForTopicViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text('Journals'),
        actions: [
          IconButton(
            tooltip: 'Search journal by name',
            icon: const Icon(Icons.search),
            onPressed: _openJournalSearch,
          ),
        ],
      ),
      body: _JournalsForTopicBody(
        selectedTopic: selectedTopic,
        viewModel: viewModel,
      ),
    );
  }
}

class _JournalsForTopicBody extends StatelessWidget {
  final SelectedTopicViewModel selectedTopic;
  final JournalsForTopicViewModel viewModel;

  const _JournalsForTopicBody({
    required this.selectedTopic,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    switch (viewModel.status) {
      case JournalsForTopicStatus.notSearched:
        return const EmptyStateWidget(
          message:
              'Search a topic on the Home tab to see its top journals here.',
          icon: Icons.travel_explore_outlined,
        );
      case JournalsForTopicStatus.loading:
        return const LoadingWidget(message: 'Loading journals...');
      case JournalsForTopicStatus.error:
        return EmptyStateWidget(
          message: viewModel.errorMessage ?? 'Something went wrong.',
          icon: Icons.error_outline,
          action: FilledButton(
            onPressed: () => viewModel.retry(selectedTopic),
            child: const Text('Retry'),
          ),
        );
      case JournalsForTopicStatus.empty:
        return const EmptyStateWidget(
          message: 'No journals found for this topic.',
          icon: Icons.menu_book_outlined,
        );
      case JournalsForTopicStatus.success:
        return _JournalsList(
          topicName: selectedTopic.selectedTopic ?? '',
          journals: viewModel.journals,
        );
    }
  }
}

class _JournalsList extends StatelessWidget {
  final String topicName;
  final List<JournalSource> journals;

  const _JournalsList({required this.topicName, required this.journals});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: journals.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Results (${journals.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Top journals for "$topicName"',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }
        final journal = journals[index - 1];
        return JournalSourceCard(
          journal: journal,
          isSelected: false,
          onSelect: () => _openJournalDetail(context, journal),
        );
      },
    );
  }

  void _openJournalDetail(BuildContext context, JournalSource journal) {
    context.read<JournalViewModel>().selectJournal(journal);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const JournalSearchScreen()),
    );
  }
}
