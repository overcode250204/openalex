class JournalTopicRank {
  const JournalTopicRank({
    required this.sourceId,
    required this.displayName,
    required this.count,
  });

  /// Normalized OpenAlex source id (e.g. "S137773608"). Empty when the
  /// API response didn't include a resolvable source id for this journal.
  final String sourceId;
  final String displayName;
  final int count;
}
