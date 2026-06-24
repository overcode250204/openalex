import 'dart:async';
import 'package:flutter/material.dart';
import 'package:openalex/models/search/search_filter.dart';
import 'package:openalex/models/topic/topic.dart';
import 'package:openalex/widgets/filter_bottom_sheet.dart';
import 'package:openalex/widgets/related_keywords_bar.dart';
import 'package:openalex/widgets/search_suggestion_overlay.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../viewmodels/home_view_model.dart';
import '../../routes/app_routes.dart';
import '../../routes/route_arguments.dart';
import '../../utils/app_keys.dart';
import '../../widgets/publication_card.dart';
import '../../widgets/state/app_error_widget.dart';
import '../../widgets/state/empty_state_widget.dart';
import '../../widgets/state/loading_widget.dart';

class TrendAnalyzerHomePage extends StatefulWidget {
  const TrendAnalyzerHomePage({super.key});

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
    context.read<HomeViewModel>().loadHistory();
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

    debugPrint('[Search UI] Analyze Topic clicked. keyword=$keyword');

    FocusScope.of(context).unfocus();

    final homeViewModel = context.read<HomeViewModel>();

    await homeViewModel.searchPublications(keyword: keyword, topic: topic);

    debugPrint('''
[Search UI] Search completed
  error: ${homeViewModel.errorMessage}
  totalResults: ${homeViewModel.totalResults}
''');

    if (!mounted || homeViewModel.errorMessage != null) {
      debugPrint('[Search UI] Analytics skipped because search failed.');
      return;
    }

  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      context.read<HomeViewModel>().onQueryChanged(value);
    });
  }

  void _showTopicRequiredMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Please select a valid research topic from the suggestions before opening analytics.',
        ),
      ),
    );
  }

  void _openTopicAnalytics({
    required String routeName,
    required HomeViewModel provider,
  }) {
    final topicId = provider.currentTopicId;
    final topicName = provider.currentTopic.trim();

    if (topicId == null || topicName.isEmpty) {
      _showTopicRequiredMessage();
      return;
    }

    Navigator.pushNamed(
      context,
      routeName,
      arguments: TopicAnalyticsRouteArgs(
        topicId: topicId,
        topicName: topicName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HomeViewModel>();

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text('Trend Analyzer', overflow: TextOverflow.ellipsis),
        actions: [
          Consumer<HomeViewModel>(
            builder: (context, provider, _) {
              final hasFilter =
                  provider.filter.yearFrom != null ||
                  provider.filter.isOpenAccess != null ||
                  provider.filter.documentType != DocumentType.all ||
                  provider.filter.sortOption != SortOption.relevance;

              return Stack(
                children: [
                  IconButton(
                    tooltip: 'Filters',
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
            onPressed: () => _openTopicAnalytics(
              routeName: AppRoutes.trendAnalysis,
              provider: provider,
            ),
            icon: const Icon(Icons.show_chart),
          ),

          IconButton(
            tooltip: 'My Zotero Library',
            onPressed: _openZoteroLibrary,
            icon: const Icon(Icons.library_books),
          ),

          IconButton(
            tooltip: 'Dashboard',
            onPressed: () => _openTopicAnalytics(
              routeName: AppRoutes.dashboard,
              provider: provider,
            ),
            icon: const Icon(Icons.dashboard),
          ),
        ],
      ),

      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final suggestionMaxHeight = (constraints.maxHeight - 240)
                .clamp(0.0, 220.0)
                .toDouble();

            return Column(
              children: [
                _SearchHeader(
                  topicController: _topicController,
                  suggestionMaxHeight: suggestionMaxHeight,
                  onSearch: provider.isLoading ? null : _search,
                  onQueryChanged: provider.isLoading ? null : _onQueryChanged,
                ),

                Consumer<HomeViewModel>(
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
            );
          },
        ),
      ),
    );
  }
}

class _SearchHeader extends StatelessWidget {
  final TextEditingController topicController;
  final double suggestionMaxHeight;
  final ValueChanged<TopicSuggestion?>? onSearch;
  final ValueChanged<String>? onQueryChanged;

  const _SearchHeader({
    required this.topicController,
    required this.suggestionMaxHeight,
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
              key: AppKeys.searchTopicField,
              controller: topicController,
              decoration: const InputDecoration(
                labelText: 'Research topic',
                hintText: 'Example: Artificial Intelligence',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onSubmitted: (_) => onSearch?.call(null),
              onChanged: onQueryChanged,
              onTap: () => context.read<HomeViewModel>().onQueryChanged(
                topicController.text,
              ),
            ),
            TapRegion(
              onTapOutside: (event) => {
                context.read<HomeViewModel>().hideSuggestions(),
              },
              child: SearchSuggestionOverlay(
                controller: topicController,
                maxHeight: suggestionMaxHeight,
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
              key: AppKeys.searchTopicButton,
              onPressed: onSearch == null ? null : () => onSearch!(null),
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
  final HomeViewModel provider;

  const _SearchResultView({required this.provider});

  @override
  Widget build(BuildContext context) {
    if (provider.isLoading) {
      return const LoadingWidget();
    }

    if (provider.errorMessage != null) {
      return AppErrorWidget(message: provider.errorMessage!);
    }

    if (provider.publications.isEmpty) {
      return LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: const EmptyStateWidget(
              message: 'Enter a research topic and tap Analyze Topic.',
              icon: Icons.manage_search,
            ),
          ),
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
        key: AppKeys.publicationList,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        itemCount:
            provider.publications.length + (provider.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == provider.publications.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: LoadingWidget(),
            );
          }
          final publication = provider.publications[index];
          return PublicationCard(
            key: AppKeys.publicationItem(publication.id),
            publication: publication,
            onTap: () {
              Navigator.pushNamed(
                context,
                AppRoutes.publicationDetail,
                arguments: PublicationDetailRouteArgs(workId: publication.id),
              );
            },
          );
        },
      ),
    );
  }
}
