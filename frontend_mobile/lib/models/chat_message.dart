class ChatMessage {
  final String role; // 'user' | 'model'
  final String content;
  final DateTime time;

  const ChatMessage({
    required this.role,
    required this.content,
    required this.time,
  });

  Map<String, dynamic> toJson() => {
        'role': role,
        'content': content,
        'time': time.toIso8601String(),
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        role: json['role'] as String,
        content: json['content'] as String,
        time: DateTime.parse(json['time'] as String),
      );
}
