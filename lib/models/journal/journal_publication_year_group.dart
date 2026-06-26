import 'journal_publication.dart';

class JournalPublicationYearGroup {
  const JournalPublicationYearGroup({
    required this.year,
    required this.publications,
  });

  final int? year;
  final List<JournalPublication> publications;

  int get count => publications.length;

  String get displayYear => year?.toString() ?? 'Unknown year';

  static List<JournalPublicationYearGroup> groupByYear(
    List<JournalPublication> publications,
  ) {
    final grouped = <int?, List<JournalPublication>>{};
    for (final pub in publications) {
      grouped.putIfAbsent(pub.publicationYear, () => []).add(pub);
    }

    final groups = grouped.entries
        .map(
          (e) =>
              JournalPublicationYearGroup(year: e.key, publications: e.value),
        )
        .toList();

    groups.sort((a, b) {
      final byCount = b.count.compareTo(a.count);
      if (byCount != 0) return byCount;
      if (a.year == null) return 1;
      if (b.year == null) return -1;
      return b.year!.compareTo(a.year!);
    });

    return groups;
  }
}
