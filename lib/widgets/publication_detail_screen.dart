import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/publication.dart';

class PublicationDetailScreen extends StatelessWidget {
  final Publication publication;

  const PublicationDetailScreen({
    super.key,
    required this.publication,
  });

  Future<void> _openDoi(BuildContext context) async {
    final doi = publication.doi;

    if (doi == null || doi.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('DOI is not available.')),
      );
      return;
    }

    final uri = Uri.parse(doi);

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot open DOI link.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final abstractText =
        publication.abstractText ?? 'No abstract available for this publication.';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Publication Detail'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            publication.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          _InfoTile(
            icon: Icons.person,
            title: 'Authors',
            value: publication.displayAuthors,
          ),
          _InfoTile(
            icon: Icons.calendar_month,
            title: 'Publication Year',
            value: publication.displayYear,
          ),
          _InfoTile(
            icon: Icons.menu_book,
            title: 'Journal',
            value: publication.displayJournal,
          ),
          _InfoTile(
            icon: Icons.format_quote,
            title: 'Citation Count',
            value: publication.citedByCount.toString(),
          ),
          _InfoTile(
            icon: Icons.link,
            title: 'DOI',
            value: publication.doi ?? 'No DOI available',
          ),
          const SizedBox(height: 12),
          if (publication.doi != null)
            FilledButton.icon(
              onPressed: () => _openDoi(context),
              icon: const Icon(Icons.open_in_browser),
              label: const Text('Open DOI'),
            ),
          const SizedBox(height: 24),
          Text(
            'Abstract',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            abstractText,
            textAlign: TextAlign.justify,
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(value),
      ),
    );
  }
}
