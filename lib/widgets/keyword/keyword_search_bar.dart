import 'package:flutter/material.dart';

class KeywordSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onAnalyze;
  final String? errorText;

  const KeywordSearchBar({
    super.key,
    required this.controller,
    required this.onAnalyze,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 620;
        final field = TextField(
          controller: controller,
          onSubmitted: (_) => onAnalyze(),
          decoration: InputDecoration(
            hintText: 'Search academic keyword',
            errorText: errorText,
            prefixIcon: const Icon(Icons.search),
            border: const OutlineInputBorder(),
          ),
        );
        final button = FilledButton.icon(
          onPressed: onAnalyze,
          icon: const Icon(Icons.analytics_outlined),
          label: const Text('Analyze Keyword'),
        );
        return compact
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [field, const SizedBox(height: 10), button],
              )
            : Row(
                children: [
                  Expanded(child: field),
                  const SizedBox(width: 12),
                  button,
                ],
              );
      },
    );
  }
}
