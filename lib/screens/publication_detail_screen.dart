import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:openalex/providers/publication_detail_provider.dart';
import 'package:openalex/providers/publication_list_provider.dart';
import 'package:openalex/screens/publication_list_screen.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:openalex/services/zotero_serivce.dart';
import '../models/publication.dart';

class PublicationDetailScreen extends StatefulWidget {
  const PublicationDetailScreen({
    super.key,
    required this.workId,
    this.initialTitle,
  });
  final String workId;
  final String? initialTitle;

  @override
  State<PublicationDetailScreen> createState() =>
      _PublicationDetailScreenState();
}

class _PublicationDetailScreenState extends State<PublicationDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PublicationDetailProvider>().loadDetail(widget.workId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<PublicationDetailProvider>(
        builder: (context, provider, _) {
          final abstractText =
              provider.publication?.abstractText ??
              'No abstract available for this publication.';

          if (provider.state == DetailState.loading) {
            return CustomScrollView(
              slivers: [
                SliverAppBar(
                  pinned: true,
                  title: Text(
                    widget.initialTitle ?? "",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // expandedHeight: 120,
                  // flexibleSpace: FlexibleSpaceBar(
                  //   title: Text(widget.initialTitle ?? '',
                  //       style: const TextStyle(fontSize: 14),
                  //       maxLines: 2),
                  // ),
                ),
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                ),
              ],
            );
          }
          if (provider.state == DetailState.error) {
            return Scaffold(
              appBar: AppBar(),
              body: Center(child: Text(provider.error ?? 'Unknown error')),
            );
          }
          if (provider.publication == null) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final pub = provider.publication!;
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                // expandedHeight: 160,
                pinned: true,
                title: Text(
                  pub.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                // flexibleSpace: FlexibleSpaceBar(
                //   background: Padding(
                //     padding: const EdgeInsets.fromLTRB(16, 80, 16, 16),
                //     child: Text(
                //       pub.title,
                //       style: Theme.of(context).textTheme.headlineSmall,
                //       maxLines: 3,
                //     ),
                //   ),
                // ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ActionButtons(pub: pub),
                      const SizedBox(height: 20),
                      _InfoSection(pub: pub),
                      const SizedBox(height: 20),
                      if (pub.abstractText != null) ...[
                        _AbstractSection(abstract: pub.abstractText!),
                        const SizedBox(height: 20),
                      ] else
                        Text(abstractText, textAlign: TextAlign.justify),

                      // Navigate buttons
                      _NavigateSection(pub: pub),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final Publication pub;
  const _ActionButtons({required this.pub});
  Future<void> _openDoi(BuildContext context) async {
    final doi = context.read<PublicationDetailProvider>().publication?.doi;

    if (doi == null || doi.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('DOI is not available.')));
      return;
    }

    final uri = Uri.parse(doi);

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Cannot open DOI link.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // Mở PDF / trang gốc
        if (pub.oaUrl != null)
          FilledButton.icon(
            onPressed: () => _launch(pub.oaUrl!),
            icon: const Icon(Icons.picture_as_pdf, size: 16),
            label: const Text('View PDF'),
            style: FilledButton.styleFrom(backgroundColor: Colors.green),
          ),
        if (pub.doi != null)
          OutlinedButton.icon(
            onPressed: () => _launch(pub.doi!),
            icon: const Icon(Icons.open_in_new, size: 16),
            label: const Text('Origin Page'),
          ),

        // Copy DOI
        if (pub.doi != null)
          OutlinedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: pub.doi!));
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Already copy DOI')));
            },
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Copy DOI'),
          ),
        FilledButton.icon(
          onPressed: () async {
            try {
              final key = await ZoteroService().savePublicationToZotero(pub);

              if (!context.mounted) return;

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Saved to Zotero successfully. Key: $key'),
                ),
              );
            } catch (e) {
              if (!context.mounted) return;

              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
            }
          },
          icon: const Icon(Icons.bookmark_add),
          label: const Text('Save to Zotero'),
        ),
        if (pub.doi != null)
          FilledButton.icon(
            onPressed: () => {_openDoi(context)},
            icon: const Icon(Icons.open_in_browser),
            label: const Text('Open DOI'),
          ),
      ],
    );
  }

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _InfoSection extends StatelessWidget {
  final Publication pub;
  const _InfoSection({required this.pub});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _InfoTile(
              icon: Icons.people,
              title: 'Authors',
              value: pub.authors.isNotEmpty
                  ? pub.authors.join(', ')
                  : "Unknown authors",
            ),
            _InfoTile(
              icon: Icons.calendar_today,
              title: 'Publication year',
              value: pub.publicationYear != null
                  ? pub.publicationYear!.toString()
                  : 'Unknown year',
            ),
            _InfoTile(
              icon: Icons.menu_book,
              title: 'Journal',
              value: pub.journalName != null
                  ? pub.journalName!
                  : "Unknown journal",
            ),
            _InfoTile(
              icon: Icons.format_quote,
              title: 'Cited',
              value: '${pub.citedByCount}',
            ),
            _InfoTile(
              icon: Icons.link,
              title: 'DOI',
              value: pub.doi != null ? pub.doi! : "No DOI available",
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
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(value),
      ),
    );
  }
}

class _AbstractSection extends StatefulWidget {
  final String abstract;
  const _AbstractSection({required this.abstract});

  @override
  State<_AbstractSection> createState() => _AbstractSectionState();
}

class _AbstractSectionState extends State<_AbstractSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Abstract',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          widget.abstract,
          maxLines: _expanded ? null : 4,
          overflow: _expanded ? null : TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13, height: 1.6),
        ),
        TextButton(
          onPressed: () => setState(() => _expanded = !_expanded),
          child: Text(_expanded ? 'Collapse' : 'View more'),
        ),
      ],
    );
  }
}

class _NavigateSection extends StatelessWidget {
  final Publication pub;
  const _NavigateSection({required this.pub});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Discovery More',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _NavCard(
          icon: Icons.auto_stories,
          title: 'Related Articles',
          subtitle: '${pub.relatedWorkIds.length} papers',
          color: Colors.blue,
          onTap: pub.relatedWorkIds.isEmpty
              ? null
              : () => _navigate(context, type: ListType.related, pub: pub),
        ),
        const SizedBox(height: 8),
        _NavCard(
          icon: Icons.call_received,
          title: 'Cited By',
          subtitle: 'Citation Counts ${pub.citedByCount}',
          color: Colors.orange,
          onTap: pub.citedByCount == 0
              ? null
              : () => _navigate(context, type: ListType.citedBy, pub: pub),
        ),
        const SizedBox(height: 8),
        _NavCard(
          icon: Icons.call_made,
          title: 'References',
          subtitle: '${pub.referencedWorkIds.length} references',
          color: Colors.purple,
          onTap: pub.referencedWorkIds.isEmpty
              ? null
              : () => _navigate(context, type: ListType.references, pub: pub),
        ),
      ],
    );
  }

  void _navigate(
    BuildContext context, {
    required ListType type,
    required Publication pub,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => PublicationListProvider(),
          child: PublicationListScreen(
            type: type,
            workId: pub.id,
            ids: type == ListType.related
                ? pub.relatedWorkIds
                : type == ListType.references
                ? pub.referencedWorkIds
                : [],
            title: type == ListType.related
                ? 'Related Articles'
                : type == ListType.citedBy
                ? 'Cited By'
                : 'References',
          ),
        ),
      ),
    );
  }
}

class _NavCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;

  const _NavCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        trailing: onTap != null
            ? const Icon(Icons.arrow_forward_ios, size: 14)
            : const Icon(Icons.block, size: 14, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
