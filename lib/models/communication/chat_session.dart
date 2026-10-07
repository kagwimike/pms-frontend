class ChatSession {
  final int id;
  final String status;
  final String? subject;
  final int tenantId;
  final int? propertyId;
  final int? unitId;
  final int? maintenanceId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? tenant; // Nested user details

  ChatSession({
    required this.id,
    required this.status,
    this.subject,
    required this.tenantId,
    this.propertyId,
    this.unitId,
    this.maintenanceId,
    required this.createdAt,
    required this.updatedAt,
    this.tenant,
  });

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      id: json['id'],
      status: json['status'] ?? 'OPEN',
      subject: json['subject'],
      tenantId: json['tenant_id'],
      propertyId: json['property_id'],
      unitId: json['unit_id'],
      maintenanceId: json['maintenance_id'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      tenant: json['tenant'],
    );
  }
}
