class ChatSession {
  final int id;
  final String status;
  final String? subject;
  final int? tenantId;
  final int? createdBy;
  final int? propertyId;
  final int? unitId;
  final int? maintenanceId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? tenant;
  final Map<String, dynamic>? otherParticipant;
  final Map<String, dynamic>? lastMessage;
  final bool isUnread;
  final Map<String, dynamic>? property;
  final Map<String, dynamic>? unit;
  final Map<String, dynamic>? maintenance;

  ChatSession({
    required this.id,
    required this.status,
    this.subject,
    this.tenantId,
    this.createdBy,
    this.propertyId,
    this.unitId,
    this.maintenanceId,
    required this.createdAt,
    required this.updatedAt,
    this.tenant,
    this.otherParticipant,
    this.lastMessage,
    this.isUnread = false,
    this.property,
    this.unit,
    this.maintenance,
  });

  String get recipientName {
    if (otherParticipant != null) {
      final rawName = otherParticipant!['name']?.toString() ?? '';
      final trimmed = rawName.trim();
      if (trimmed.isNotEmpty) return trimmed;
    }
    if (subject != null && subject!.toString().trim().isNotEmpty) {
      final s = subject!.toString().trim();
      // If subject starts with "Chat with", clean it for a direct recipient name if possible
      return s;
    }
    if (tenant != null) {
      final first = tenant!['first_name']?.toString() ?? '';
      final last = tenant!['last_name']?.toString() ?? '';
      final name = '$first $last'.trim();
      if (name.isNotEmpty) return name;
      final uname = tenant!['username']?.toString() ?? '';
      if (uname.trim().isNotEmpty) return uname.trim();
    }
    return 'Chat #$id';
  }

  String get recipientSubtitle {
    if (otherParticipant != null) {
      final sub = otherParticipant!['subtitle']?.toString() ?? '';
      if (sub.trim().isNotEmpty) return sub.trim();
      final role = otherParticipant!['role']?.toString() ?? '';
      if (role.trim().isNotEmpty) return role.trim();
    }
    if (maintenance != null && maintenance!['title'] != null) {
      final title = maintenance!['title']?.toString() ?? '';
      if (title.trim().isNotEmpty) return 'Ticket: ${title.trim()}';
    }
    return 'Direct Message';
  }

  String get recipientRole {
    if (otherParticipant != null && otherParticipant!['role'] != null) {
      final role = otherParticipant!['role']?.toString() ?? '';
      if (role.trim().isNotEmpty) return role.trim().toUpperCase();
    }
    return 'USER';
  }

  String? get recipientAvatar {
    if (otherParticipant != null && otherParticipant!['avatar'] != null) {
      final avatar = otherParticipant!['avatar']?.toString() ?? '';
      if (avatar.trim().isNotEmpty) return avatar.trim();
    }
    return null;
  }

  String get previewMessage {
    if (lastMessage != null && lastMessage!['text'] != null) {
      final text = lastMessage!['text']?.toString() ?? '';
      if (text.trim().isNotEmpty) return text.trim();
    }
    if (subject != null && subject!.toString().trim().isNotEmpty) {
      return subject!.toString().trim();
    }
    return 'Start conversation...';
  }

  static Map<String, dynamic>? _safeMap(dynamic val) {
    if (val is Map) {
      return Map<String, dynamic>.from(val);
    }
    return null;
  }

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    DateTime parsedCreatedAt = DateTime.now();
    DateTime parsedUpdatedAt = DateTime.now();
    try {
      if (json['created_at'] != null) {
        parsedCreatedAt = DateTime.parse(json['created_at'].toString());
      }
    } catch (_) {}
    try {
      if (json['updated_at'] != null) {
        parsedUpdatedAt = DateTime.parse(json['updated_at'].toString());
      } else {
        parsedUpdatedAt = parsedCreatedAt;
      }
    } catch (_) {}

    return ChatSession(
      id: json['id'] is int ? json['id'] : (int.tryParse(json['id']?.toString() ?? '0') ?? 0),
      status: json['status']?.toString() ?? 'OPEN',
      subject: json['subject']?.toString(),
      tenantId: json['tenant_id'] != null ? (json['tenant_id'] is int ? json['tenant_id'] : int.tryParse(json['tenant_id'].toString())) : null,
      createdBy: json['created_by'] != null ? (json['created_by'] is int ? json['created_by'] : int.tryParse(json['created_by'].toString())) : null,
      propertyId: json['property_id'] != null ? (json['property_id'] is int ? json['property_id'] : int.tryParse(json['property_id'].toString())) : null,
      unitId: json['unit_id'] != null ? (json['unit_id'] is int ? json['unit_id'] : int.tryParse(json['unit_id'].toString())) : null,
      maintenanceId: json['maintenance_id'] != null ? (json['maintenance_id'] is int ? json['maintenance_id'] : int.tryParse(json['maintenance_id'].toString())) : null,
      createdAt: parsedCreatedAt,
      updatedAt: parsedUpdatedAt,
      tenant: _safeMap(json['tenant']),
      otherParticipant: _safeMap(json['other_participant']),
      lastMessage: _safeMap(json['last_message']),
      isUnread: json['is_unread'] == true,
      property: _safeMap(json['property']),
      unit: _safeMap(json['unit']),
      maintenance: _safeMap(json['maintenance']),
    );
  }
}
