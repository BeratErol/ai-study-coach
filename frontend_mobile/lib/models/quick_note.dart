class QuickNote {
  final String id;
  final String? title;
  final String content;
  final DateTime createdAt;

  const QuickNote({
    required this.id,
    this.title,
    required this.content,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
      };

  factory QuickNote.fromJson(Map<String, dynamic> json) => QuickNote(
        id: json['id'] as String,
        title: json['title'] as String?,
        content: json['content'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
