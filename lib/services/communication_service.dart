import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../models/communication/chat_session.dart';
import '../models/communication/chat_message.dart';
import '../config.dart';
import 'auth_service.dart';
import 'sound_service.dart';

class CommunicationService {
  final AuthService _authService = AuthService();
  IO.Socket? _socket;
  
  // Streams for real-time events
  final _messageStreamController = StreamController<ChatMessage>.broadcast();
  final _reactionStreamController = StreamController<Map<String, dynamic>>.broadcast();
  final _typingStreamController = StreamController<Map<String, dynamic>>.broadcast();
  final _stopTypingStreamController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<ChatMessage> get onMessageReceived => _messageStreamController.stream;
  Stream<Map<String, dynamic>> get onReactionReceived => _reactionStreamController.stream;
  Stream<Map<String, dynamic>> get onUserTyping => _typingStreamController.stream;
  Stream<Map<String, dynamic>> get onUserStopTyping => _stopTypingStreamController.stream;

  String get _socketUrl {
    return AppConfig.apiBaseUrl.replaceAll('/api', '');
  }

  /// Initialize Socket.IO connection
  Future<void> initSocket() async {
    if (_socket != null && _socket!.connected) return;

    final token = _authService.accessToken;
    if (token == null) return;

    _socket = IO.io(_socketUrl, IO.OptionBuilder()
        .setTransports(['websocket'])
        .setAuth({'token': token})
        .enableAutoConnect()
        .build());

    _socket?.onConnect((_) {
      print('Connected to Chat Socket');
    });

    _socket?.on('receive_message', (data) {
      if (data != null) {
        final message = ChatMessage.fromJson(Map<String, dynamic>.from(data));
        _messageStreamController.add(message);
        // Play sound for incoming message
        if (message.senderId != _authService.user?.id) {
          SoundService().playNotificationSound();
        }
      }
    });

    _socket?.on('message_reaction', (data) {
      if (data != null) {
        _reactionStreamController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket?.on('new_notification', (data) {
      SoundService().playNotificationSound();
    });

    _socket?.on('user_typing', (data) {
      if (data != null) {
        _typingStreamController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket?.on('user_stop_typing', (data) {
      if (data != null) {
        _stopTypingStreamController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket?.onDisconnect((_) => print('Disconnected from Chat Socket'));
  }

  /// Join a specific chat room
  void joinSession(int sessionId) {
    _socket?.emit('join_session', sessionId);
  }

  /// Leave a specific chat room
  void leaveSession(int sessionId) {
    _socket?.emit('leave_session', sessionId);
  }

  /// Emit typing indicator
  void sendTyping(int sessionId) {
    _socket?.emit('typing', {'sessionId': sessionId});
  }

  /// Emit stop typing
  void sendStopTyping(int sessionId) {
    _socket?.emit('stop_typing', {'sessionId': sessionId});
  }

  /// Send message directly via Socket.IO
  void sendMessageViaSocket(
    int sessionId,
    String text, {
    String messageType = 'TEXT',
    String? mediaUrl,
    int? replyToMessageId,
  }) {
    _socket?.emit('send_message', {
      'sessionId': sessionId,
      'message': text,
      'message_type': messageType,
      'media_url': mediaUrl,
      'reply_to_message_id': replyToMessageId,
    });
  }

  /// React to a message via Socket.IO
  void reactToMessage(int messageId, int sessionId, String reaction) {
    _socket?.emit('react_message', {
      'messageId': messageId,
      'sessionId': sessionId,
      'reaction': reaction,
    });
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_authService.accessToken != null) 'Authorization': 'Bearer ${_authService.accessToken}',
      };

  /// REST API: Get all contacts (Vendors, Tenants, Owners, Caretakers)
  Future<List<Map<String, dynamic>>> getContacts({String? query, String? role}) async {
    try {
      final queryParams = <String, String>{};
      if (query != null && query.isNotEmpty) queryParams['query'] = query;
      if (role != null && role.isNotEmpty) queryParams['role'] = role;

      final uri = Uri.parse('${AppConfig.apiBaseUrl}/communication/contacts').replace(queryParameters: queryParams.isEmpty ? null : queryParams);
      final response = await http.get(uri, headers: _headers);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<dynamic> records = [];
        if (data is List) {
          records = data;
        } else if (data is Map<String, dynamic> && data['data'] is List) {
          records = data['data'];
        }
        return records.map((e) => Map<String, dynamic>.from(e)).toList();
      }
      return [];
    } catch (e) {
      print('Error loading contacts: $e');
      return [];
    }
  }

  /// REST API: Get all sessions
  Future<List<ChatSession>> getSessions() async {
    try {
      final response = await http.get(Uri.parse('${AppConfig.apiBaseUrl}/communication/sessions?limit=100'), headers: _headers);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<dynamic> records = [];
        if (data is List) {
          records = data;
        } else if (data is Map<String, dynamic> && data['data'] is List) {
          records = data['data'];
        }
        return records.map((e) => ChatSession.fromJson(e as Map<String, dynamic>)).toList();
      }
      throw Exception('Failed to load sessions: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error loading sessions: $e');
    }
  }

  /// REST API: Get messages for a session
  Future<List<ChatMessage>> getMessages(int sessionId) async {
    try {
      final response = await http.get(Uri.parse('${AppConfig.apiBaseUrl}/communication/sessions/$sessionId/messages?limit=100'), headers: _headers);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<dynamic> records = [];
        if (data is List) {
          records = data;
        } else if (data is Map<String, dynamic> && data['data'] is List) {
          records = data['data'];
        }
        return records.map((e) => ChatMessage.fromJson(e as Map<String, dynamic>)).toList();
      }
      throw Exception('Failed to load messages');
    } catch (e) {
      throw Exception('Error loading messages: $e');
    }
  }

  /// REST API: Create or resume a session with ANY user (Vendor, Tenant, Landlord)
  Future<ChatSession> createSession({
    int? targetUserId,
    int? vendorId,
    int? tenantId,
    String? subject,
    String? initialMessage,
    int? propertyId,
    int? unitId,
    int? maintenanceId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/communication/sessions'),
        headers: _headers,
        body: json.encode({
          if (targetUserId != null) 'target_user_id': targetUserId,
          if (vendorId != null) 'vendor_id': vendorId,
          if (tenantId != null) 'tenant_id': tenantId,
          if (subject != null) 'subject': subject,
          if (initialMessage != null) 'initial_message': initialMessage,
          if (propertyId != null) 'property_id': propertyId,
          if (unitId != null) 'unit_id': unitId,
          if (maintenanceId != null) 'maintenance_id': maintenanceId,
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        Map<String, dynamic> record = {};
        if (data is Map<String, dynamic>) {
          record = data.containsKey('data') ? (data['data'] as Map<String, dynamic>? ?? {}) : data;
        }
        return ChatSession.fromJson(record);
      }
      final err = json.decode(response.body);
      throw Exception(err['message'] ?? 'Failed to create session');
    } catch (e) {
      throw Exception('Error creating session: $e');
    }
  }

  /// REST API: Upload image / attachment
  Future<String?> uploadAttachment(List<int> fileBytes, String filename) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConfig.apiBaseUrl}/communication/upload'),
      );
      if (_authService.accessToken != null) {
        request.headers['Authorization'] = 'Bearer ${_authService.accessToken}';
      }
      request.files.add(http.MultipartFile.fromBytes('file', fileBytes, filename: filename));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        final payload = data['data'] ?? data;
        return payload['url']?.toString();
      }
      return null;
    } catch (e) {
      print('Attachment upload error: $e');
      return null;
    }
  }

  /// REST API: React to message
  Future<void> sendHttpReaction(int messageId, String reaction) async {
    try {
      await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/communication/messages/$messageId/reaction'),
        headers: _headers,
        body: json.encode({'reaction': reaction}),
      );
    } catch (e) {
      print('Reaction HTTP error: $e');
    }
  }

  void dispose() {
    _socket?.disconnect();
    _socket?.dispose();
    _messageStreamController.close();
    _reactionStreamController.close();
    _typingStreamController.close();
    _stopTypingStreamController.close();
  }
}
