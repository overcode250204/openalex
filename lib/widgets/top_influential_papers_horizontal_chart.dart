import 'package:flutter/material.dart';

import '../models/analytics/topic_analytics.dart';
import '../utils/formatters.dart';

class TopInfluentialPapersHorizontalChart extends StatelessWidget {
  final List<InfluentialPaperSummary> papers;

  const TopInfluentialPapersHorizontalChart({super.key, required this.papers});

  @override
  Widget build(BuildContext context) {
    if (papers.isEmpty) {
      return const SizedBox(
        height: 390,
        child: Center(child: Text('No influential papers data available.')),
      );
    }

    final displayedPapers = papers;

    // Find max citations for calculating width percentages
    int maxCitations = 0;
    for (var paper in displayedPapers) {
      if (paper.citedByCount > maxCitations) {
        maxCitations = paper.citedByCount;
      }
    }

    // Create an axis range that's a nice round number above maxCitations
    // e.g., if max is 8946, make axis max 10000
    final double axisMax = maxCitations > 0
        ? ((maxCitations / 2000).ceil() * 2000).toDouble()
        : 10000.toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: displayedPapers.asMap().entries.map((entry) {
            final index = entry.key;
            final paper = entry.value;
            final percentage = maxCitations > 0
                ? paper.citedByCount / axisMax
                : 0.0;

            return Padding(
              padding: EdgeInsets.only(
                bottom: index == displayedPapers.length - 1 ? 0 : 16,
              ),
              child: Tooltip(
                message:
                    '${paper.title}\n${_displayYear(paper)}\nCitations: ${Formatters.formatCitation(paper.citedByCount)}',
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(8),
                ),
                textStyle: const TextStyle(color: Colors.white, fontSize: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      paper.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _displayYear(paper),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              return Stack(
                                children: [
                                  Container(
                                    height: 20,
                                    width: double.infinity,
                                    color: Colors.transparent,
                                  ),
                                  Container(
                                    height: 20,
                                    width: constraints.maxWidth * percentage,
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade500,
                                      borderRadius: const BorderRadius.only(
                                        topRight: Radius.circular(4),
                                        bottomRight: Radius.circular(4),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 90,
                          child: Text(
                            Formatters.formatCitation(paper.citedByCount),
                            maxLines: 1,
                            overflow: TextOverflow.visible,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade600,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        // X Axis labels
        Row(
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    child: Container(height: 1, color: Colors.grey.shade300),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(6, (index) {
                      final val = (axisMax / 5) * index;
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          val == 0
                              ? '0'
                              : Formatters.formatCompactAxis(val.toInt()),
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(
              width: 90,
            ), // Match the width of the citation count text to align properly
          ],
        ),
        const SizedBox(height: 4),
        Center(
          child: Text(
            'Citations',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
        ),
      ],
    );
  }
}

String _displayYear(InfluentialPaperSummary paper) {
  return paper.publicationYear?.toString() ?? 'Unknown year';
}
