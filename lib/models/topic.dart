class TopicSuggestion {
  final String id; // T123456
  final String displayName;
  final int workCount;

  TopicSuggestion({required this.id, required this.displayName, required this.workCount});

  factory TopicSuggestion.fromJson(Map<String,dynamic> json){
    return TopicSuggestion(id: json['id'] as String, displayName: json['display_name'] as String, workCount: json['works_count'] as int? ?? 0 );
  }
}