import 'package:flutter/material.dart';

class KeywordStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const KeywordStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          CircleAvatar(child: Icon(icon, size: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(label, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}
