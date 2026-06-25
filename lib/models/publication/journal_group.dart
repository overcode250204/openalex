import 'publication.dart';

class JournalGroup {
  const JournalGroup({required this.journalName, required this.publications});

  final String journalName;
  final List<Publication> publications;

  int get count => publications.length;

  static List<JournalGroup> groupByJournal(List<Publication> publications) {
    final grouped = <String, List<Publication>>{};
    for (final pub in publications) {
      final name = pub.journalName?.trim();
      final journal = (name == null || name.isEmpty)
          ? 'Unknown journal'
          : name;
      grouped.putIfAbsent(journal, () => []).add(pub);
    }

    final groups = grouped.entries
        .map((e) => JournalGroup(journalName: e.key, publications: e.value))
        .toList();

    groups.sort((a, b) {
      final byCount = b.count.compareTo(a.count);
      return byCount != 0 ? byCount : a.journalName.compareTo(b.journalName);
    });

    return groups;
  }
}
