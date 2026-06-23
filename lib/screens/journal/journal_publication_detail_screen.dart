import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/journal/journal_publication.dart';
import '../../viewmodels/journal_publication_detail_view_model.dart';

class JournalPublicationDetailScreen extends StatefulWidget {
  final JournalPublication publication;

  const JournalPublicationDetailScreen({super.key, required this.publication});

  @override
  State<JournalPublicationDetailScreen> createState() =>
      _JournalPublicationDetailScreenState();
}

class _JournalPublicationDetailScreenState
    extends State<JournalPublicationDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<JournalPublicationDetailViewModel>().load(
          widget.publication,
        );
      }
    });
  }

  Future<void> _openUrl(String? value) async {
    if (value == null || value.trim().isEmpty) return;

    final uri = Uri.parse(value);
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!opened && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Cannot open this link.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<JournalPublicationDetailViewModel>();
    final publication = viewModel.publication ?? widget.publication;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: Text(
          publication.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        publication.title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Chip(
                            avatar: const Icon(Icons.calendar_today, size: 16),
                            label: Text(publication.displayDate),
                          ),
                          Chip(
                            avatar: const Icon(Icons.format_quote, size: 16),
                            label: Text(
                              '${publication.citedByCount} citations',
                            ),
                          ),
                          Chip(
                            avatar: Icon(
                              publication.isOpenAccess
                                  ? Icons.lock_open
                                  : Icons.lock_outline,
                              size: 16,
                            ),
                            label: Text(
                              publication.isOpenAccess
                                  ? 'Open Access'
                                  : 'Closed Access',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _InfoCard(publication: publication),
              const SizedBox(height: 16),
              _AbstractCard(abstractText: publication.abstractText),
              const SizedBox(height: 16),
              _ActionCard(
                doi: publication.doi,
                pdfUrl: publication.pdfUrl,
                landingPageUrl: publication.landingPageUrl,
                onOpenUrl: _openUrl,
              ),
            ],
          ),
          if (viewModel.isLoading)
            const Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: LinearProgressIndicator(),
            ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final JournalPublication publication;

  const _InfoCard({required this.publication});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _InfoTile(
              icon: Icons.people_outline,
              title: 'Authors',
              value: publication.displayAuthors,
            ),
            _InfoTile(
              icon: Icons.calendar_month_outlined,
              title: 'Publication year',
              value: publication.displayYear,
            ),
            _InfoTile(
              icon: Icons.event_outlined,
              title: 'Publication date',
              value: publication.publicationDate ?? 'Unknown date',
            ),
            _InfoTile(
              icon: Icons.menu_book_outlined,
              title: 'Journal',
              value: publication.displayJournal,
            ),
            _InfoTile(
              icon: Icons.link,
              title: 'DOI',
              value: publication.displayDoi,
            ),
            _InfoTile(
              icon: Icons.tag,
              title: 'OpenAlex ID',
              value: publication.id,
            ),
          ],
        ),
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
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(value),
    );
  }
}

class _AbstractCard extends StatelessWidget {
  final String? abstractText;

  const _AbstractCard({required this.abstractText});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Abstract',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              abstractText?.trim().isNotEmpty == true
                  ? abstractText!
                  : 'No abstract available',
              textAlign: TextAlign.justify,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String? doi;
  final String? pdfUrl;
  final String? landingPageUrl;
  final ValueChanged<String?> onOpenUrl;

  const _ActionCard({
    required this.doi,
    required this.pdfUrl,
    required this.landingPageUrl,
    required this.onOpenUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: doi?.trim().isNotEmpty == true
                  ? () => onOpenUrl(doi)
                  : null,
              icon: const Icon(Icons.open_in_browser),
              label: const Text('Open DOI'),
            ),
            OutlinedButton.icon(
              onPressed: pdfUrl?.trim().isNotEmpty == true
                  ? () => onOpenUrl(pdfUrl)
                  : null,
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Open PDF'),
            ),
            OutlinedButton.icon(
              onPressed: landingPageUrl?.trim().isNotEmpty == true
                  ? () => onOpenUrl(landingPageUrl)
                  : null,
              icon: const Icon(Icons.public),
              label: const Text('Open Landing Page'),
            ),
          ],
        ),
      ),
    );
  }
}
