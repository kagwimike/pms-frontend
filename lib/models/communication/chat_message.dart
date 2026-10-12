class ChatMessage {
  final int id;
  final int sessionId;
  final int senderId;
  final String message;
  final String messageType;
  final String? mediaUrl;
  final String? reaction;
  final int? replyToMessageId;
  final DateTime createdAt;
  final Map<String, dynamic>? sender;

  ChatMessage({
    required this.id,
    required this.sessionId,
    required this.senderId,
    required this.message,
    required this.messageType,
    this.mediaUrl,
    this.reaction,
    this.replyToMessageId,
    required this.createdAt,
    this.sender,
  });

  String get senderName {
    if (sender != null) {
      final first = sender!['first_name']?.toString() ?? '';
      final last = sender!['last_name']?.toString() ?? '';
      final name = '$first $last'.trim();
      if (name.isNotEmpty) return name;
      final uname = sender!['username']?.toString() ?? '';
      if (uname.trim().isNotEmpty) return uname.trim();
    }
    return 'User';
  }

  static Map<String, dynamic>? _safeMap(dynamic val) {
    if (val is Map) {
      return Map<String, dynamic>.from(val);
    }
    return null;
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    DateTime parsedCreatedAt = DateTime.now();
    try {
      if (json['created_at'] != null) {
        parsedCreatedAt = DateTime.parse(json['created_at'].toString());
      }
    } catch (_) {}

    return ChatMessage(
      id: json['id'] is int ? json['id'] : (int.tryParse(json['id']?.toString() ?? '0') ?? 0),
      sessionId: json['session_id'] is int ? json['session_id'] : (int.tryParse(json['session_id']?.toString() ?? '0') ?? 0),
      senderId: json['sender_id'] is int ? json['sender_id'] : (int.tryParse(json['sender_id']?.toString() ?? '0') ?? 0),
      message: json['message']?.toString() ?? '',
      messageType: json['message_type']?.toString() ?? 'TEXT',
      mediaUrl: json['media_url']?.toString(),
      reaction: json['reaction']?.toString(),
      replyToMessageId: json['reply_to_message_id'] != null 
          ? (json['reply_to_message_id'] is int ? json['reply_to_message_id'] : int.tryParse(json['reply_to_message_id'].toString())) 
          : null,
      createdAt: parsedCreatedAt,
      sender: _safeMap(json['sender']),
    );
  }

  ChatMessage copyWith({String? reaction}) {
    return ChatMessage(
      id: id,
      sessionId: sessionId,
      senderId: senderId,
      message: message,
      messageType: messageType,
      mediaUrl: mediaUrl,
      reaction: reaction ?? this.reaction,
      replyToMessageId: replyToMessageId,
      createdAt: createdAt,
      sender: sender,
    );
  }
}
