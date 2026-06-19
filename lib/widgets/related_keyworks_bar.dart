import 'package:flutter/material.dart';
import 'package:openalex/providers/publication_provider.dart';
import 'package:provider/provider.dart';

class RelatedKeywordsBar extends StatelessWidget {
  final Function(String) onKeywordTap;

  const RelatedKeywordsBar({super.key, required this.onKeywordTap});

  @override
  Widget build(BuildContext context) {
    return Consumer<PublicationProvider>(
      builder: (context, provider, _) {
        if (provider.relatedKeywords.isEmpty) return const SizedBox();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(
                'Related Topic',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: provider.relatedKeywords.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final keyword = provider.relatedKeywords[index];
                  return ActionChip(
                    label: Text(keyword, style: const TextStyle(fontSize: 12)),
                    onPressed: () => onKeywordTap(keyword),
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primaryContainer,
                    labelStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}
