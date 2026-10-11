import 'dart:async';
import 'package:flutter/material.dart';
import '../../../models/communication/chat_session.dart';
import '../../../models/communication/chat_message.dart';
import '../../../services/communication_service.dart';
import '../../../services/auth_service.dart';

class CommunicationProvider extends ChangeNotifier {
  final CommunicationService _service = CommunicationService();
  final AuthService _authService = AuthService();

  List<ChatSession> _sessions = [];
  Map<int, List<ChatMessage>> _messages = {};
  Map<int, bool> _typingStatus = {};

  bool _isLoading = false;
  bool _isConnected = false;

  List<ChatSession> get sessions => _sessions;
  bool get isLoading => _isLoading;
  bool get isConnected => _isConnected;

  StreamSubscription? _messageSub;
  StreamSubscription? _typingSub;

  CommunicationProvider() {
    _initSocket();
  }

  void _initSocket() async {
    await _service.initSocket();
    _isConnected = true;
    notifyListeners();

    _messageSub = _service.onMessageReceived.listen((message) {
      if (message.sessionId != null) {
        if (!_messages.containsKey(message.sessionId)) {
          _messages[message.sessionId!] = [];
        }
        _messages[message.sessionId!]!.add(message);
        notifyListeners();
      }
    });

    _typingSub = _service.onUserTyping.listen((data) {
      final sessionId = data['sessionId'] as int?;
      if (sessionId != null) {
        _typingStatus[sessionId] = true;
        notifyListeners();
        
        // Auto reset typing after 3 seconds
        Future.delayed(const Duration(seconds: 3), () {
          _typingStatus[sessionId] = false;
          notifyListeners();
        });
      }
    });
  }

  bool isTyping(int sessionId) => _typingStatus[sessionId] ?? false;

  List<ChatMessage> getMessagesForSession(int sessionId) {
    return _messages[sessionId] ?? [];
  }

  Future<void> fetchSessions() async {
    _isLoading = true;
    notifyListeners();
    try {
      _sessions = await _service.getSessions();
    } catch (e) {
      print("Failed to fetch sessions: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMessages(int sessionId) async {
    try {
      final msgs = await _service.getMessages(sessionId);
      _messages[sessionId] = msgs;
      notifyListeners();
    } catch (e) {
      print("Failed to load messages for $sessionId: $e");
    }
  }

  void joinSession(int sessionId) {
    _service.joinSession(sessionId);
    loadMessages(sessionId);
  }

  void leaveSession(int sessionId) {
    _service.leaveSession(sessionId);
  }

  void sendMessage(int sessionId, String text) {
    // Optimistic UI update could go here
    _service.sendMessageViaSocket(sessionId, text);
  }

  void sendTyping(int sessionId) {
    _service.sendTyping(sessionId);
  }

  @override
  void dispose() {
    _messageSub?.cancel();
    _typingSub?.cancel();
    _service.dispose();
    super.dispose();
  }
}
