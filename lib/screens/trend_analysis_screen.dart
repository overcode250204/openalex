import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/publication_provider.dart';
import '../widgets/trend_chart.dart';
import 'publication_detail_screen.dart';

class TrendAnalysisScreen extends StatelessWidget {
  const TrendAnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PublicationProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trend Analysis'),
      ),
      body: provider.publications.isEmpty
          ? const Center(
              child: Text('Search a topic first to view trend analysis.'),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Publication Trend: ${provider.currentTopic}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: TrendChart(
                      data: provider.publicationCountByYear,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _SectionTitle(title: 'Top Influential Papers'),
                const SizedBox(height: 8),
                ...provider.topInfluentialPapers.map(
                  (publication) => Card(
                    child: ListTile(
                      title: Text(
                        publication.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${publication.displayYear} • ${publication.displayJournal}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Text(
                        '${publication.citedByCount} citations',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PublicationDetailScreen(
                              publication: publication,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _SectionTitle(title: 'Top Research Journals'),
                const SizedBox(height: 8),
                ...provider.topJournals.entries.map(
                  (entry) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.menu_book),
                      title: Text(entry.key),
                      trailing: Text(
                        '${entry.value} papers',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _SectionTitle(title: 'Top Contributing Authors'),
                const SizedBox(height: 8),
                ...provider.topAuthors.entries.map(
                  (entry) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.person),
                      title: Text(entry.key),
                      trailing: Text(
                        '${entry.value} papers',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }
}