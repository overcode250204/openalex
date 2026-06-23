import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
      appBar: AppBar(title: Text(widget.title)),
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

          return NotificationListener<ScrollNotification>(
            onNotification: (scroll) {
              if (scroll.metrics.pixels >=
                  scroll.metrics.maxScrollExtent - 200) {
                if (provider.hasMore && !provider.isLoading) {
                  provider.load(
                    type: widget.type,
                    workId: widget.workId,
                    ids: widget.ids,
                    reset: false,
                  );
                }
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
