import 'package:flutter/material.dart';
import 'package:openalex/models/topic.dart';
import 'package:openalex/providers/publication_provider.dart';
import 'package:provider/provider.dart';

class SearchSuggestionOverlay extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<TopicSuggestion?>? onSearch;

  const SearchSuggestionOverlay({
    super.key,
    required this.controller,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Focus(
      child: Consumer<PublicationProvider>(
        builder: (context, provider, _) {
          if (!provider.showSuggestions) {
            return const SizedBox.shrink();
          }

          final query = controller.text.trim();
          final hasHistory = provider.searchHistory.isNotEmpty;
          final hasSuggestions = provider.conceptSuggestions.isNotEmpty;

          if (!hasHistory && !hasSuggestions) {
            return const SizedBox.shrink();
          }

          return Container(
            key: const Key('search_suggestion_overlay_content'),
            margin: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // History
                if (query.isEmpty && hasHistory) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Search history',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                        TextButton(
                          onPressed: () => provider.clearHistory(),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                          ),
                          child: const Text(
                            'Clear all',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...provider.searchHistory.map(
                    (h) => _HistoryItem(
                      keyword: h,
                      onTap: () {
                        controller.text = h;
                        provider.hideSuggestions();
                        onSearch?.call(null);
                        onSearch!(null);
                      },
                      onDelete: () => provider.removeHistory(h),
                    ),
                  ),
                ],

                // suggestion from openalex
                if (query.isNotEmpty && hasSuggestions) ...[
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Text(
                      'Suggestion',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  ...provider.conceptSuggestions.map(
                    (s) => _SuggestionItem(
                      name: s.displayName,
                      subtitle: s.workCount.toString(),
                      onTap: () {
                        controller.text = s.displayName;
                        provider.hideSuggestions();
                        onSearch?.call(s);
                      },
                    ),
                  ),
                ],

                const SizedBox(height: 8),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  final String keyword;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _HistoryItem({
    required this.keyword,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: const Icon(Icons.history, size: 18, color: Colors.grey),
      title: Text(keyword, style: const TextStyle(fontSize: 14)),
      trailing: IconButton(
        icon: const Icon(Icons.close, size: 16, color: Colors.grey),
        onPressed: onDelete,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      ),
      onTap: onTap,
    );
  }
}

class _SuggestionItem extends StatelessWidget {
  final String name;
  final String subtitle;
  final VoidCallback onTap;

  const _SuggestionItem({
    required this.name,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: const Icon(Icons.search, size: 18, color: Colors.grey),
      title: Text(name, style: const TextStyle(fontSize: 14)),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 11, color: Colors.grey),
      ),
      onTap: onTap,
    );
  }
}
