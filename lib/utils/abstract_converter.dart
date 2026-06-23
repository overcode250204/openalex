class AbstractConverter {
  static String? fromInvertedIndex(Map<String, dynamic>? invertedIndex) {
    if (invertedIndex == null || invertedIndex.isEmpty) {
      return null;
    }

    final Map<int, String> positionToWord = {};

    invertedIndex.forEach((word, positions) {
      if (positions is List) {
        for (final position in positions) {
          if (position is int) {
            positionToWord[position] = word;
          }
        }
      }
    });

    final sortedPositions = positionToWord.keys.toList()..sort();

    return sortedPositions
        .map((position) => positionToWord[position])
        .whereType<String>()
        .join(' ');
  }
}
