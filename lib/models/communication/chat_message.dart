class ChatMessage {
  final int id;
  final int sessionId;
  final int senderId;
  final String message;
  final String messageType;
  final DateTime createdAt;
  final Map<String, dynamic>? sender;

  ChatMessage({
    required this.id,
    required this.sessionId,
    required this.senderId,
    required this.message,
    required this.messageType,
    required this.createdAt,
    this.sender,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      sessionId: json['session_id'],
      senderId: json['sender_id'],
      message: json['message'],
      messageType: json['message_type'] ?? 'TEXT',
      createdAt: DateTime.parse(json['created_at']),
      sender: json['sender'],
    );
  }
}
