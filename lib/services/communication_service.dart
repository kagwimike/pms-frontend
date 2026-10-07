import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../models/communication/chat_session.dart';
import '../models/communication/chat_message.dart';
import '../config.dart';
import 'api_service.dart';
import 'auth_service.dart';

class CommunicationService {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();
  IO.Socket? _socket;
  
  // Streams for real-time events
  final _messageStreamController = StreamController<ChatMessage>.broadcast();
  final _typingStreamController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<ChatMessage> get onMessageReceived => _messageStreamController.stream;
  Stream<Map<String, dynamic>> get onUserTyping => _typingStreamController.stream;

  String get _socketUrl {
    // Return base url without /api
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
        final message = ChatMessage.fromJson(data);
        _messageStreamController.add(message);
      }
    });

    _socket?.on('user_typing', (data) {
      if (data != null) {
        _typingStreamController.add(Map<String, dynamic>.from(data));
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

  /// Send message directly via Socket.IO
  void sendMessageViaSocket(int sessionId, String text) {
    _socket?.emit('send_message', {
      'sessionId': sessionId,
      'message': text,
      'message_type': 'TEXT'
    });
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_authService.accessToken != null) 'Authorization': 'Bearer ${_authService.accessToken}',
      };

  /// REST API: Get all sessions
  Future<List<ChatSession>> getSessions() async {
    try {
      final response = await http.get(Uri.parse('${AppConfig.apiBaseUrl}/communication/sessions'), headers: _headers);
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
      throw Exception('Failed to load sessions');
    } catch (e) {
      throw Exception('Error loading sessions: $e');
    }
  }

  /// REST API: Get messages for a session
  Future<List<ChatMessage>> getMessages(int sessionId) async {
    try {
      final response = await http.get(Uri.parse('${AppConfig.apiBaseUrl}/communication/sessions/$sessionId/messages'), headers: _headers);
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

  /// REST API: Create a new session
  Future<ChatSession> createSession({
    required int tenantId,
    String? subject,
    int? propertyId,
    int? unitId,
    int? maintenanceId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/communication/sessions'),
        headers: _headers,
        body: json.encode({
          'tenant_id': tenantId,
          'subject': subject,
          'property_id': propertyId,
          'unit_id': unitId,
          'maintenance_id': maintenanceId,
        }),
      );
      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        Map<String, dynamic> record = {};
        if (data is Map<String, dynamic>) {
           record = data.containsKey('data') ? (data['data'] as Map<String, dynamic>? ?? {}) : data;
        }
        return ChatSession.fromJson(record);
      }
      throw Exception('Failed to create session');
    } catch (e) {
      throw Exception('Error creating session: $e');
    }
  }

  void dispose() {
    _socket?.disconnect();
    _socket?.dispose();
    _messageStreamController.close();
    _typingStreamController.close();
  }
}
