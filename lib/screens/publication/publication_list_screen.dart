import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/publication/journal_group.dart';
import '../../utils/formatters.dart';
import '../../viewmodels/publication_list_view_model.dart';
import '../../routes/app_routes.dart';
import '../../routes/route_arguments.dart';
import '../../widgets/publication_card.dart';
import '../../widgets/state/empty_state_widget.dart';
import '../../widgets/state/loading_widget.dart';

class PublicationListScreen extends StatefulWidget {
  final ListType type;
  final String workId;
  final List<String> ids;
  final String title;

  const PublicationListScreen({
    super.key,
    required this.type,
    required this.workId,
    required this.ids,
    required this.title,
  });

  @override
  State<PublicationListScreen> createState() => _PublicationListScreenState();
}

class _PublicationListScreenState extends State<PublicationListScreen> {
  bool _groupByJournal = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PublicationListViewModel>().load(
        type: widget.type,
        workId: widget.workId,
        ids: widget.ids,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            tooltip: _groupByJournal
                ? 'Show flat list'
                : 'Group by journal',
            icon: Icon(_groupByJournal ? Icons.view_list : Icons.bar_chart),
            onPressed: () => setState(() => _groupByJournal = !_groupByJournal),
          ),
        ],
      ),
      body: Consumer<PublicationListViewModel>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.items.isEmpty) {
            return const LoadingWidget(message: 'Loading publications...');
          }
          if (provider.items.isEmpty) {
            return const EmptyStateWidget(
              message: 'Không có dữ liệu.',
              icon: Icons.article_outlined,
            );
          }

          if (_groupByJournal) {
            return _JournalGroupedList(groups: provider.journalGroups);
          }

          return NotificationListener<ScrollNotification>(
            onNotification: (scroll) {
              if (scroll.metrics.pixels >=
                  scroll.metrics.maxScrollExtent - 200) {
                provider.load(
                  type: widget.type,
                  workId: widget.workId,
                  ids: widget.ids,
                  reset: false,
                );
              }
              return false;
            },
            child: ListView.builder(
              itemCount: provider.items.length + (provider.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == provider.items.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: LoadingWidget(),
                  );
                }
                final pub = provider.items[index];
                return PublicationCard(
                  publication: pub,
                  // Điều hướng đệ quy: nhấn vào bài bất kỳ → mở detail mới
                  onTap: () => Navigator.pushNamed(
                    context,
                    AppRoutes.publicationDetail,
                    arguments: PublicationDetailRouteArgs(
                      workId: pub.id,
                      initialTitle: pub.title,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _JournalGroupedList extends StatelessWidget {
  final List<JournalGroup> groups;

  const _JournalGroupedList({required this.groups});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 12),
      itemCount: groups.length,
      itemBuilder: (context, index) {
        final group = groups[index];
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _JournalGroupHeader(group: group),
              const SizedBox(height: 8),
              ...group.publications.map(
                (pub) => PublicationCard(
                  publication: pub,
                  onTap: () => Navigator.pushNamed(
                    context,
                    AppRoutes.publicationDetail,
                    arguments: PublicationDetailRouteArgs(
                      workId: pub.id,
                      initialTitle: pub.title,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _JournalGroupHeader extends StatelessWidget {
  final JournalGroup group;

  const _JournalGroupHeader({required this.group});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            group.journalName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            Formatters.formatCompactNumber(group.count),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
