import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/publication_provider.dart';
import '../widgets/publication_card.dart';
import 'dashboard_screen.dart';
import 'publication_detail_screen.dart';
import 'trend_analysis_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _topicController = TextEditingController();
  final TextEditingController _fromYearController = TextEditingController();
  final TextEditingController _toYearController = TextEditingController();

  Future<void> _openZoteroLibrary() async {
    final uri = Uri.parse('https://www.zotero.org/baonoob101/library');

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot open Zotero library.')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _topicController.text = 'Artificial Intelligence';
  }

  @override
  void dispose() {
    _topicController.dispose();
    _fromYearController.dispose();
    _toYearController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final provider = context.read<PublicationProvider>();

    final fromYear = int.tryParse(_fromYearController.text.trim());
    final toYear = int.tryParse(_toYearController.text.trim());

    await provider.searchPublications(
      keyword: _topicController.text,
      fromYear: fromYear,
      toYear: toYear,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PublicationProvider>();

    return Scaffold(
      appBar: AppBar(
        // FIX: rút gọn title để đủ chỗ cho 3 icon
        title: const Text('Trend Analyzer', overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: 'Trend Analysis',
            onPressed: provider.publications.isEmpty
                ? null
                : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TrendAnalysisScreen(),
                      ),
                    );
                  },
            icon: const Icon(Icons.show_chart),
          ),
          // FIX: Zotero icon — luôn enabled, không phụ thuộc publications
          IconButton(
            tooltip: 'My Zotero Library',
            onPressed: _openZoteroLibrary,
            icon: const Icon(Icons.library_books),
          ),
          IconButton(
            tooltip: 'Dashboard',
            onPressed: provider.publications.isEmpty
                ? null
                : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DashboardScreen(),
                      ),
                    );
                  },
            icon: const Icon(Icons.dashboard),
          ),
        ],
      ),
      // FIX: bọc body trong SafeArea để tránh bị che bởi status bar / notch
      body: SafeArea(
        child: Column(
          children: [
            _SearchHeader(
              topicController: _topicController,
              fromYearController: _fromYearController,
              toYearController: _toYearController,
              onSearch: provider.isLoading ? null : _search,
            ),
            Expanded(child: _SearchResultView(provider: provider)),
          ],
        ),
      ),
    );
  }
}

class _SearchHeader extends StatelessWidget {
  final TextEditingController topicController;
  final TextEditingController fromYearController;
  final TextEditingController toYearController;
  final VoidCallback? onSearch;

  const _SearchHeader({
    required this.topicController,
    required this.fromYearController,
    required this.toYearController,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      // FIX: thêm clipBehavior để card không tràn ra ngoài
      clipBehavior: Clip.hardEdge,
      child: Padding(
        padding: const EdgeInsets.all(16),
        // FIX: bọc Column trong IntrinsicWidth để constrain đúng chiều ngang
        child: Column(
          // FIX: stretch để các widget con full width theo card
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: topicController,
              decoration: const InputDecoration(
                labelText: 'Research topic',
                hintText: 'Example: Artificial Intelligence',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onSubmitted: (_) => onSearch?.call(),
            ),
            const SizedBox(height: 12),
            // FIX: dùng LayoutBuilder để Row biết chính xác width có sẵn
            LayoutBuilder(
              builder: (context, constraints) {
                return Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: fromYearController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'From year',
                          hintText: '2020',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: toYearController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'To year',
                          hintText: '2026',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            // FIX: bỏ SizedBox width double.infinity, dùng crossAxisAlignment.stretch thay thế
            FilledButton.icon(
              onPressed: onSearch,
              icon: const Icon(Icons.analytics),
              label: const Text('Analyze Topic'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchResultView extends StatelessWidget {
  final PublicationProvider provider;

  const _SearchResultView({required this.provider});

  @override
  Widget build(BuildContext context) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(provider.errorMessage!, textAlign: TextAlign.center),
        ),
      );
    }

    if (provider.publications.isEmpty) {
      return const Center(
        child: Text(
          'Enter a research topic and tap Analyze Topic.',
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: provider.publications.length,
      itemBuilder: (context, index) {
        final publication = provider.publications[index];

        return PublicationCard(
          publication: publication,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    PublicationDetailScreen(publication: publication),
              ),
            );
          },
        );
      },
    );
  }
}
