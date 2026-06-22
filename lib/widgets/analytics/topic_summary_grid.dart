import 'package:flutter/material.dart';

class TopicSummaryGrid extends StatelessWidget {
  final bool isLoading;
  final String totalPublications;
  final String averageCitations;
  final String averageCitationsLabel;
  final String mostActiveYear;
  final String topAuthor;
  final String topJournal;
  final String mostInfluentialPaper;
  final String? influentialPaperDetails;
  final VoidCallback? onInfluentialPaperTap;

  const TopicSummaryGrid({
    super.key,
    required this.isLoading,
    required this.totalPublications,
    required this.averageCitations,
    this.averageCitationsLabel = 'Average Citations',
    required this.mostActiveYear,
    required this.topAuthor,
    required this.topJournal,
    required this.mostInfluentialPaper,
    this.influentialPaperDetails,
    this.onInfluentialPaperTap,
  });

  @override
  Widget build(BuildContext context) {
    final metrics = [
      _Metric('Total Publications', totalPublications, Icons.public, Colors.teal),
      _Metric(
        averageCitationsLabel,
        averageCitations,
        Icons.format_quote,
        Colors.blue,
      ),
      _Metric(
        'Most Active Year',
        mostActiveYear,
        Icons.calendar_month,
        Colors.purple,
      ),
      _Metric('Top Author', topAuthor, Icons.person, Colors.green),
      _Metric('Top Journal', topJournal, Icons.menu_book, Colors.indigo),
      _Metric(
        'Most Influential Paper',
        mostInfluentialPaper,
        Icons.workspace_premium,
        Colors.orange,
        details: influentialPaperDetails,
        onTap: onInfluentialPaperTap,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900
            ? 3
            : constraints.maxWidth >= 360
            ? 2
            : 1;
        return GridView.builder(
          key: const Key('topic_summary_grid'),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: metrics.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: 164,
          ),
          itemBuilder: (context, index) =>
              _MetricCard(metric: metrics[index], isLoading: isLoading),
        );
      },
    );
  }
}

class _Metric {
  final String label;
  final String value;
  final IconData icon;
  final MaterialColor color;
  final String? details;
  final VoidCallback? onTap;

  const _Metric(
    this.label,
    this.value,
    this.icon,
    this.color, {
    this.details,
    this.onTap,
  });
}

class _MetricCard extends StatelessWidget {
  final _Metric metric;
  final bool isLoading;

  const _MetricCard({required this.metric, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${metric.label}: ${isLoading ? "Loading" : metric.value}',
      button: metric.onTap != null,
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: isLoading ? null : metric.onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: metric.color.shade50,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Icon(
                        metric.icon,
                        size: 19,
                        color: metric.color.shade700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        metric.label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                if (isLoading)
                  const SizedBox(
                    key: Key('summary_card_loading'),
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Tooltip(
                    message: metric.value,
                    child: Text(
                      metric.value,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if (!isLoading && metric.details != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    metric.details!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
