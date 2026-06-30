import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/journal/journal_source.dart';
import '../../models/publication/publication.dart';
import '../../routes/app_routes.dart';
import '../../routes/route_arguments.dart';
import '../../services/analytics/app_analytics_service.dart';
import '../../services/openalex_journal_service.dart';
import '../../utils/app_keys.dart';
import '../../utils/formatters.dart';
import '../../viewmodels/home_view_model.dart';
import '../../widgets/publication_card.dart';
import '../../widgets/state/app_error_widget.dart';
import '../../widgets/state/empty_state_widget.dart';
import '../../widgets/state/loading_widget.dart';

class JournalDetailScreen extends StatefulWidget {
  final JournalSource journal;

  const JournalDetailScreen({super.key, required this.journal});

  @override
  State<JournalDetailScreen> createState() => _JournalDetailScreenState();
}

class _JournalDetailScreenState extends State<JournalDetailScreen> {
  bool _hasLoggedViewJournal = false;
  List<Publication> _publications = [];
  bool _isLoadingPubs = false;
  String? _pubsError;
  bool _isFromTopic = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _logViewJournal();
      _initPublications();
    });
  }

  Future<void> _logViewJournal() async {
    if (_hasLoggedViewJournal) return;
    final journalName = widget.journal.displayName.trim();
    if (journalName.isEmpty) return;
    _hasLoggedViewJournal = true;

    AppAnalyticsService? analytics;
    try {
      analytics = context.read<AppAnalyticsService>();
    } on ProviderNotFoundException {
      // Analytics is optional in widget tests.
    }

    await analytics?.logViewJournal(journalName: journalName);
  }

  void _initPublications() {
    final topicPubs = _topicPublications();
    if (topicPubs.isNotEmpty) {
      setState(() {
        _publications = topicPubs;
        _isFromTopic = true;
      });
    } else {
      _fetchFromApi();
    }
  }

  List<Publication> _topicPublications() {
    try {
      final homeViewModel = context.read<HomeViewModel>();
      final name = widget.journal.displayName.trim().toLowerCase();
      return homeViewModel.publications
          .where((p) => (p.journalName?.trim().toLowerCase() ?? '') == name)
          .toList();
    } on ProviderNotFoundException {
      return [];
    }
  }

  Future<void> _fetchFromApi() async {
    if (!mounted) return;
    setState(() {
      _isLoadingPubs = true;
      _pubsError = null;
    });
    try {
      final service = context.read<OpenAlexJournalService>();
      final pubs = await service.fetchPublicationsForJournal(
        widget.journal.id,
      );
      if (mounted) setState(() => _publications = pubs);
    } on ProviderNotFoundException {
      // Service not in tree (some test environments).
    } catch (_) {
      if (mounted) _pubsError = 'Could not load publications.';
    } finally {
      if (mounted) setState(() => _isLoadingPubs = false);
    }
  }

  void _openPublication(Publication publication) {
    if (publication.id.trim().isEmpty) return;
    Navigator.pushNamed(
      context,
      AppRoutes.publicationDetail,
      arguments: PublicationDetailRouteArgs(
        workId: publication.id,
        initialTitle: publication.title,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final journal = widget.journal;

    return Scaffold(
      key: AppKeys.journalDetailScreen,
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: Text(journal.displayName, overflow: TextOverflow.ellipsis),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            KeyedSubtree(
              key: AppKeys.journalStatsSection,
              child: _StatsSection(journal: journal),
            ),
            const SizedBox(height: 20),
            _publicationsSectionHeader(),
            const SizedBox(height: 12),
            KeyedSubtree(
              key: AppKeys.journalPublicationsSection,
              child: _publicationsBody(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _publicationsSectionHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Publications',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        if (!_isLoadingPubs && _publications.isNotEmpty)
          Text(
            _isFromTopic
                ? 'From your current topic search'
                : 'Top cited in this journal',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
          ),
      ],
    );
  }

  Widget _publicationsBody() {
    if (_isLoadingPubs) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: LoadingWidget(message: 'Loading publications...'),
      );
    }

    if (_pubsError != null) {
      return AppErrorWidget(
        message: _pubsError!,
        onRetry: _fetchFromApi,
      );
    }

    if (_publications.isEmpty) {
      return const EmptyStateWidget(
        message: 'No publications found for this journal.',
        icon: Icons.article_outlined,
      );
    }

    return Column(
      children: _publications
          .map(
            (pub) => PublicationCard(
              publication: pub,
              onTap: () => _openPublication(pub),
            ),
          )
          .toList(),
    );
  }
}

class _StatsSection extends StatelessWidget {
  final JournalSource journal;

  const _StatsSection({required this.journal});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _StatChip(
          icon: Icons.article_outlined,
          label:
              '${Formatters.formatCompactNumber(journal.worksCount)} publications',
          color: Colors.blue,
        ),
        _StatChip(
          icon: Icons.format_quote,
          label:
              '${Formatters.formatCompactNumber(journal.citedByCount)} citations',
          color: Colors.orange,
        ),
        _StatChip(
          icon: Icons.equalizer,
          label:
              '${journal.averageCitations.toStringAsFixed(1)} avg citations',
          color: Colors.purple,
        ),
        if (journal.publisher != null)
          _StatChip(
            icon: Icons.business_outlined,
            label: journal.publisher!,
            color: Colors.teal,
          ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final MaterialColor color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color.shade700),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color.shade800,
            ),
          ),
        ],
      ),
    );
  }
}
