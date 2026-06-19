import 'package:flutter/material.dart';

import '../../models/journal_suggestion.dart';

class JournalSuggestionDropdown extends StatelessWidget {
  final List<JournalSuggestion> suggestions;
  final ValueChanged<JournalSuggestion> onSelected;
  final bool isLoading;

  const JournalSuggestionDropdown({
    super.key,
    required this.suggestions,
    required this.onSelected,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(16),
        decoration: _boxDecoration(),
        child: const Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('Searching journals...'),
          ],
        ),
      );
    }

    if (suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: _boxDecoration(),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: suggestions.length,
        separatorBuilder: (_, i) => Divider(
          height: 1,
          color: Colors.grey.shade100,
        ),
        itemBuilder: (context, index) {
          final journal = suggestions[index];

          return InkWell(
            onTap: () => onSelected(journal),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.menu_book_outlined,
                    size: 20,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          journal.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          [
                            if (journal.worksCount > 0)
                              '${journal.worksCount} works',
                            if (journal.publisher != null &&
                                journal.publisher!.trim().isNotEmpty)
                              journal.publisher!,
                            if (journal.issnL != null &&
                                journal.issnL!.trim().isNotEmpty)
                              'ISSN-L: ${journal.issnL}',
                          ].join(' • '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  BoxDecoration _boxDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey.shade200),
      boxShadow: [
        BoxShadow(
          // ignore: deprecated_member_use
          color: Colors.black.withOpacity(0.06),
          blurRadius: 12,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }
}
