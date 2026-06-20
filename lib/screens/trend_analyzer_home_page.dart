import 'dart:async';

import 'package:flutter/material.dart';
import 'package:openalex/models/search_filter.dart';
import 'package:openalex/models/topic.dart';
import 'package:openalex/widgets/filter_bottom_sheet.dart';
import 'package:openalex/widgets/related_keyworks_bar.dart';
import 'package:openalex/widgets/search_suggestion_overlay.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/publication_provider.dart';
import '../widgets/publication_card.dart';
import 'dashboard_screen.dart';
import 'publication_detail_screen.dart';
import 'trend_analysis_screen.dart';

class TrendAnalyzerHomePage extends StatefulWidget {
  final VoidCallback? onOpenDrawer;

  const TrendAnalyzerHomePage({super.key, this.onOpenDrawer});

  @override
  State<TrendAnalyzerHomePage> createState() => _TrendAnalyzerHomePageState();
}

class _TrendAnalyzerHomePageState extends State<TrendAnalyzerHomePage> {
  final TextEditingController _topicController = TextEditingController();
  Timer? _debounce;

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
    context.read<PublicationProvider>().loadHistory();
  }

  @override
  void dispose() {
    _topicController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _search(TopicSuggestion? topic) async {
    final keyword = _topicController.text.trim();
    if (keyword.isEmpty) return;
    FocusScope.of(context).unfocus();
    context.read<PublicationProvider>().searchPublications(
      keyword: keyword,
      topic: topic,
    );
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      context.read<PublicationProvider>().onQueryChanged(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PublicationProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text('Trend Analyzer', overflow: TextOverflow.ellipsis),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            widget.onOpenDrawer?.call();
          },
        ),
        actions: [
          Consumer<PublicationProvider>(
            builder: (context, provider, _) {
              final hasFilter =
                  provider.filter.yearFrom != null ||
                  provider.filter.isOpenAccess != null ||
                  provider.filter.documentType != DocumentType.all ||
                  provider.filter.sortOption != SortOption.relevance;
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.tune),
                    onPressed: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      builder: (_) => const FilterBottomSheet(),
                    ),
                  ),
                  if (hasFilter)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
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

      body: Column(
        children: [
          _SearchHeader(
            topicController: _topicController,
            onSearch: provider.isLoading ? null : _search,
            onQueryChanged: provider.isLoading ? null : _onQueryChanged,
          ),

          Consumer<PublicationProvider>(
            builder: (context, provider, _) => provider.totalResults > 0
                ? Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: Text(
                      '${provider.totalResults} results',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  )
                : const SizedBox(),
          ),
          Expanded(child: _SearchResultView(provider: provider)),
        ],
      ),
    );
  }
}

class _SearchHeader extends StatelessWidget {
  final TextEditingController topicController;
  final ValueChanged<TopicSuggestion?>? onSearch;
  final ValueChanged<String>? onQueryChanged;

  const _SearchHeader({
    required this.topicController,
    required this.onSearch,
    required this.onQueryChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
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
              onSubmitted: (_) => onSearch?.call(null),
              onChanged: onQueryChanged,
              onTap: () => context.read<PublicationProvider>().onQueryChanged(
                topicController.text,
              ),
            ),
            TapRegion(
              onTapOutside: (event) => {
                context.read<PublicationProvider>().hideSuggestions(),
              },
              child: SearchSuggestionOverlay(
                controller: topicController,
                onSearch: (topic) => onSearch?.call(topic),
              ),
            ),
            RelatedKeywordsBar(
              onKeywordTap: (keyword) {
                topicController.text = keyword;
                onSearch?.call(null);
              },
            ),

            const SizedBox(height: 12),

            FilledButton.icon(
              onPressed: () => {onSearch?.call(null)},
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

    return NotificationListener<ScrollNotification>(
      onNotification: (scroll) {
        if (scroll.metrics.pixels >= scroll.metrics.maxScrollExtent - 200) {
          provider.loadMore();
        }
        return false;
      },
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        itemCount:
            provider.publications.length + (provider.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == provider.publications.length) {
            return const Center(child: CircularProgressIndicator());
          }
          final publication = provider.publications[index];
          return PublicationCard(
            publication: publication,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      PublicationDetailScreen(workId: publication.id),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
