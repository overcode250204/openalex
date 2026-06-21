import 'package:flutter/material.dart';

class KeywordEmptyState extends StatelessWidget {
  final VoidCallback onRefresh;

  const KeywordEmptyState({super.key, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.insights_outlined, size: 44),
          const SizedBox(height: 12),
          const Text('No recent keyword activity found.'),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRefresh, child: const Text('Refresh')),
        ],
      ),
    );
  }
}
