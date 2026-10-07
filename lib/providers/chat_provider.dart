import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/communication/chat_session.dart';
import '../models/communication/chat_message.dart';
import '../services/communication_service.dart';

class ChatProvider extends ChangeNotifier {
  final CommunicationService _service = CommunicationService();
  
  List<ChatSession> _sessions = [];
  List<ChatMessage> _currentSessionMessages = [];
  int? _activeSessionId;
  bool _isLoadingSessions = false;
  bool _isLoadingMessages = false;
  String? _error;
  
  // Real-time subscriptions
  StreamSubscription? _messageSub;
  StreamSubscription? _typingSub;

  List<ChatSession> get sessions => _sessions;
  List<ChatMessage> get currentMessages => _currentSessionMessages;
  bool get isLoadingSessions => _isLoadingSessions;
  bool get isLoadingMessages => _isLoadingMessages;
  String? get error => _error;
  int? get activeSessionId => _activeSessionId;

  ChatProvider() {
    _initSocketListeners();
  }

  Future<void> initialize() async {
    await _service.initSocket();
    await fetchSessions();
  }

  void _initSocketListeners() {
    _messageSub = _service.onMessageReceived.listen((message) {
      if (_activeSessionId == message.sessionId) {
        _currentSessionMessages.add(message);
        notifyListeners();
      }
      
      // Update session updated_at in the list
      final index = _sessions.indexWhere((s) => s.id == message.sessionId);
      if (index != -1) {
        final updatedSession = ChatSession(
          id: _sessions[index].id,
          status: _sessions[index].status,
          tenantId: _sessions[index].tenantId,
          createdAt: _sessions[index].createdAt,
          updatedAt: DateTime.now(),
          subject: _sessions[index].subject,
          tenant: _sessions[index].tenant,
          propertyId: _sessions[index].propertyId,
          unitId: _sessions[index].unitId,
          maintenanceId: _sessions[index].maintenanceId,
        );
        _sessions[index] = updatedSession;
        // Sort sessions by updated_at descending
        _sessions.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        notifyListeners();
      }
    });

    _typingSub = _service.onUserTyping.listen((data) {
      // Implement typing indicator logic if needed
    });
  }

  Future<void> fetchSessions() async {
    _isLoadingSessions = true;
    _error = null;
    notifyListeners();

    try {
      _sessions = await _service.getSessions();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingSessions = false;
      notifyListeners();
    }
  }

  Future<void> setActiveSession(int sessionId) async {
    // Leave previous session room
    if (_activeSessionId != null) {
      _service.leaveSession(_activeSessionId!);
    }

    _activeSessionId = sessionId;
    _currentSessionMessages = [];
    _isLoadingMessages = true;
    _error = null;
    notifyListeners();

    try {
      _currentSessionMessages = await _service.getMessages(sessionId);
      _service.joinSession(sessionId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingMessages = false;
      notifyListeners();
    }
  }

  Future<void> createSession(int tenantId, {String? subject}) async {
    try {
      final session = await _service.createSession(tenantId: tenantId, subject: subject);
      _sessions.insert(0, session);
      notifyListeners();
      await setActiveSession(session.id);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void sendMessage(String text) {
    if (_activeSessionId == null || text.trim().isEmpty) return;
    _service.sendMessageViaSocket(_activeSessionId!, text.trim());
  }

  void notifyTyping() {
    if (_activeSessionId != null) {
      _service.sendTyping(_activeSessionId!);
    }
  }

  @override
  void dispose() {
    _messageSub?.cancel();
    _typingSub?.cancel();
    _service.dispose();
    super.dispose();
  }
}
