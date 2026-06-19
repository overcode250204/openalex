import 'package:flutter/material.dart';

class KeywordSuggestionDropdown extends StatelessWidget {
  final List<String> suggestions;
  final ValueChanged<String> onSelected;

  const KeywordSuggestionDropdown({
    super.key,
    required this.suggestions,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: suggestions.length,
        separatorBuilder: (context, index) =>
            Divider(height: 1, color: Colors.grey.shade100),
        itemBuilder: (context, index) {
          final keyword = suggestions[index];

          return InkWell(
            onTap: () => onSelected(keyword),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.label_outline,
                    size: 18,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      keyword,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
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
}
