import 'package:flutter/material.dart';

class KeywordChartErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const KeywordChartErrorState({
    super.key,
    this.message = 'Unable to load trend data',
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 250,
      width: double.infinity,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 32, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
