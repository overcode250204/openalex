import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/publication_provider.dart';
import '../widgets/summary_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PublicationProvider>();
    final mostInfluentialPaper = provider.mostInfluentialPaper;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Research Dashboard'),
      ),
      body: provider.publications.isEmpty
          ? const Center(
              child: Text('Search a topic first to view dashboard.'),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Dashboard: ${provider.currentTopic}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                SummaryCard(
                  title: 'Total Publications',
                  value: provider.totalPublications.toString(),
                  icon: Icons.article,
                ),
                SummaryCard(
                  title: 'Average Citation Count',
                  value: provider.averageCitationCount.toStringAsFixed(2),
                  icon: Icons.format_quote,
                ),
                SummaryCard(
                  title: 'Most Active Publication Year',
                  value: provider.mostActiveYear?.toString() ?? 'N/A',
                  icon: Icons.calendar_month,
                ),
                SummaryCard(
                  title: 'Top Journal',
                  value: provider.topJournal ?? 'N/A',
                  icon: Icons.menu_book,
                ),
                SummaryCard(
                  title: 'Top Author',
                  value: provider.topAuthor ?? 'N/A',
                  icon: Icons.person,
                ),
                SummaryCard(
                  title: 'Most Influential Paper',
                  value: mostInfluentialPaper?.title ?? 'N/A',
                  icon: Icons.workspace_premium,
                ),
              ],
            ),
    );
  }
}
