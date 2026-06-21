import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/publication_detail_provider.dart';
import '../providers/publication_list_provider.dart';
import '../widgets/publication_card.dart';
import 'publication_detail_screen.dart';

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
      context.read<PublicationListProvider>().load(
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
      body: Consumer<PublicationListProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.items.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.items.isEmpty) {
            return const Center(child: Text('Không có dữ liệu.'));
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
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                final pub = provider.items[index];
                return PublicationCard(
                  publication: pub,
                  // Điều hướng đệ quy: nhấn vào bài bất kỳ → mở detail mới
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChangeNotifierProvider(
                        create: (_) => PublicationDetailProvider(),
                        child: PublicationDetailScreen(
                          workId: pub.id,
                          initialTitle: pub.title,
                        ),
                      ),
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
