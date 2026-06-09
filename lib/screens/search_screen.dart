import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/publication_provider.dart';
import '../widgets/publication_card.dart';
import 'dashboard_screen.dart';
import 'publication_detail_screen.dart';
import 'trend_analysis_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _topicController = TextEditingController();
  final TextEditingController _fromYearController = TextEditingController();
  final TextEditingController _toYearController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _topicController.text = 'Artificial Intelligence';
  }

  @override
  void dispose() {
    _topicController.dispose();
    _fromYearController.dispose();
    _toYearController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final provider = context.read<PublicationProvider>();

    final fromYear = int.tryParse(_fromYearController.text.trim());
    final toYear = int.tryParse(_toYearController.text.trim());

    await provider.searchPublications(
      keyword: _topicController.text,
      fromYear: fromYear,
      toYear: toYear,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PublicationProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Journal Trend Analyzer'),
        actions: [
          IconButton(
            tooltip: 'Trend Analysis',
            onPressed: provider.publications.isEmpty
                ? null
                : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TrendAnalysisScreen(),
                      ),
                    );
                  },
            icon: const Icon(Icons.show_chart),
          ),
          IconButton(
            tooltip: 'Dashboard',
            onPressed: provider.publications.isEmpty
                ? null
                : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DashboardScreen(),
                      ),
                    );
                  },
            icon: const Icon(Icons.dashboard),
          ),
        ],
      ),
      body: Column(
        children: [
          _SearchHeader(
            topicController: _topicController,
            fromYearController: _fromYearController,
            toYearController: _toYearController,
            onSearch: provider.isLoading ? null : _search,
          ),
          Expanded(
            child: _SearchResultView(provider: provider),
          ),
        ],
      ),
    );
  }
}

class _SearchHeader extends StatelessWidget {
  final TextEditingController topicController;
  final TextEditingController fromYearController;
  final TextEditingController toYearController;
  final VoidCallback? onSearch;

  const _SearchHeader({
    required this.topicController,
    required this.fromYearController,
    required this.toYearController,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: topicController,
              decoration: const InputDecoration(
                labelText: 'Research topic',
                hintText: 'Example: Artificial Intelligence',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onSubmitted: (_) => onSearch?.call(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: fromYearController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'From year',
                      hintText: '2020',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: toYearController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'To year',
                      hintText: '2026',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onSearch,
                icon: const Icon(Icons.analytics),
                label: const Text('Analyze Topic'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchResultView extends StatelessWidget {
  final PublicationProvider provider;

  const _SearchResultView({
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    if (provider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (provider.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            provider.errorMessage!,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (provider.publications.isEmpty) {
      return const Center(
        child: Text(
          'Enter a research topic and tap Analyze Topic.',
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: provider.publications.length,
      itemBuilder: (context, index) {
        final publication = provider.publications[index];

        return PublicationCard(
          publication: publication,
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
        );
      },
    );
  }
}