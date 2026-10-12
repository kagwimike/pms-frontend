import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/communication/chat_session.dart';
import '../models/communication/chat_message.dart';
import '../services/communication_service.dart';
import '../services/auth_service.dart';

class ChatProvider extends ChangeNotifier {
  final CommunicationService _service = CommunicationService();
  final AuthService _authService = AuthService();
  
  List<ChatSession> _sessions = [];
  List<ChatMessage> _currentSessionMessages = [];
  ChatSession? _activeSession;
  int? _activeSessionId;
  
  bool _isLoadingSessions = false;
  bool _isLoadingMessages = false;
  bool _isLoadingContacts = false;
  bool _isUploadingAttachment = false;
  String? _error;
  
  // Real-time indicators
  final Map<int, bool> _typingUsers = {}; // sessionId -> isTyping
  Timer? _typingDebounce;

  // Contacts
  List<Map<String, dynamic>> _contacts = [];
  String _selectedFilter = 'ALL'; // ALL, UNREAD, VENDOR, TENANT, STAFF
  String _searchQuery = '';

  // Real-time subscriptions
  StreamSubscription? _messageSub;
  StreamSubscription? _reactionSub;
  StreamSubscription? _typingSub;
  StreamSubscription? _stopTypingSub;

  List<ChatSession> get sessions => _sessions;
  ChatSession? get activeSession => _activeSession;
  int? get activeSessionId => _activeSessionId;
  List<ChatMessage> get currentMessages => _currentSessionMessages;
  bool get isLoadingSessions => _isLoadingSessions;
  bool get isLoadingMessages => _isLoadingMessages;
  bool get isLoadingContacts => _isLoadingContacts;
  bool get isUploadingAttachment => _isUploadingAttachment;
  String? get error => _error;
  String get selectedFilter => _selectedFilter;
  String get searchQuery => _searchQuery;
  List<Map<String, dynamic>> get contacts => _contacts;

  bool isSessionTyping(int sessionId) => _typingUsers[sessionId] ?? false;

  List<ChatSession> get filteredSessions {
    return _sessions.where((session) {
      // 1. Role / Tab filter
      if (_selectedFilter == 'UNREAD' && !session.isUnread) return false;
      if (_selectedFilter == 'VENDOR' && session.recipientRole != 'VENDOR') return false;
      if (_selectedFilter == 'TENANT' && session.recipientRole != 'TENANT') return false;
      if (_selectedFilter == 'STAFF' && !['OWNER', 'CARETAKER', 'ADMIN'].contains(session.recipientRole)) return false;

      // 2. Search query filter
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.toLowerCase().trim();
        final nameMatch = session.recipientName.toLowerCase().contains(q);
        final subtitleMatch = session.recipientSubtitle.toLowerCase().contains(q);
        final lastMsgMatch = session.previewMessage.toLowerCase().contains(q);
        return nameMatch || subtitleMatch || lastMsgMatch;
      }

      return true;
    }).toList();
  }

  ChatProvider() {
    _initSocketListeners();
  }

  Future<void> initialize() async {
    await _service.initSocket();
    await fetchSessions();
  }

  void setFilter(String filter) {
    _selectedFilter = filter;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void _initSocketListeners() {
    _messageSub = _service.onMessageReceived.listen((message) {
      final currentUserId = _authService.user?.id;

      if (_activeSessionId == message.sessionId) {
        // Avoid duplicate messages if already present
        final exists = _currentSessionMessages.any((m) => m.id == message.id);
        if (!exists) {
          _currentSessionMessages.add(message);
          notifyListeners();
        }
      }
      
      // Update session in list
      final index = _sessions.indexWhere((s) => s.id == message.sessionId);
      if (index != -1) {
        final existing = _sessions[index];
        final updatedSession = ChatSession(
          id: existing.id,
          status: existing.status,
          tenantId: existing.tenantId,
          createdBy: existing.createdBy,
          createdAt: existing.createdAt,
          updatedAt: message.createdAt,
          subject: existing.subject,
          tenant: existing.tenant,
          propertyId: existing.propertyId,
          unitId: existing.unitId,
          maintenanceId: existing.maintenanceId,
          otherParticipant: existing.otherParticipant,
          property: existing.property,
          unit: existing.unit,
          maintenance: existing.maintenance,
          lastMessage: {
            'id': message.id,
            'text': message.messageType == 'IMAGE' ? '📷 Photo' : message.message,
            'time': message.createdAt.toIso8601String(),
            'sender_id': message.senderId,
            'sender_name': message.senderName,
          },
          isUnread: _activeSessionId != message.sessionId && message.senderId != currentUserId,
        );
        _sessions[index] = updatedSession;
        _sessions.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        notifyListeners();
      } else {
        // New session initiated remotely, refresh sessions list
        fetchSessions();
      }
    });

    _reactionSub = _service.onReactionReceived.listen((data) {
      final messageId = data['messageId'] as int?;
      final reaction = data['reaction'] as String?;
      if (messageId != null) {
        final msgIdx = _currentSessionMessages.indexWhere((m) => m.id == messageId);
        if (msgIdx != -1) {
          _currentSessionMessages[msgIdx] = _currentSessionMessages[msgIdx].copyWith(reaction: reaction);
          notifyListeners();
        }
      }
    });

    _typingSub = _service.onUserTyping.listen((data) {
      final sId = data['sessionId'] as int?;
      final uId = data['userId'] as int?;
      if (sId != null && uId != _authService.user?.id) {
        _typingUsers[sId] = true;
        notifyListeners();
      }
    });

    _stopTypingSub = _service.onUserStopTyping.listen((data) {
      final sId = data['sessionId'] as int?;
      if (sId != null) {
        _typingUsers[sId] = false;
        notifyListeners();
      }
    });
  }

  Future<void> fetchSessions() async {
    _isLoadingSessions = true;
    _error = null;
    notifyListeners();

    try {
      _sessions = await _service.getSessions();
      if (_activeSessionId != null) {
        _activeSession = _sessions.firstWhere(
          (s) => s.id == _activeSessionId, 
          orElse: () => _sessions.isNotEmpty ? _sessions.first : _sessions.first
        );
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingSessions = false;
      notifyListeners();
    }
  }

  Future<void> fetchContacts({String? query, String? role}) async {
    _isLoadingContacts = true;
    notifyListeners();
    try {
      _contacts = await _service.getContacts(query: query, role: role);
    } catch (e) {
      print('Failed to load contacts: $e');
    } finally {
      _isLoadingContacts = false;
      notifyListeners();
    }
  }

  Future<void> setActiveSession(int sessionId) async {
    if (_activeSessionId == sessionId && _currentSessionMessages.isNotEmpty) return;

    if (_activeSessionId != null) {
      _service.leaveSession(_activeSessionId!);
    }

    _activeSessionId = sessionId;
    final found = _sessions.where((s) => s.id == sessionId).toList();
    if (found.isNotEmpty) {
      _activeSession = found.first;
    }
    
    _currentSessionMessages = [];
    _isLoadingMessages = true;
    _error = null;
    notifyListeners();

    try {
      _currentSessionMessages = await _service.getMessages(sessionId);
      _service.joinSession(sessionId);

      // Mark session as read locally
      final sIdx = _sessions.indexWhere((s) => s.id == sessionId);
      if (sIdx != -1) {
        final cur = _sessions[sIdx];
        _sessions[sIdx] = ChatSession(
          id: cur.id,
          status: cur.status,
          subject: cur.subject,
          tenantId: cur.tenantId,
          createdBy: cur.createdBy,
          propertyId: cur.propertyId,
          unitId: cur.unitId,
          maintenanceId: cur.maintenanceId,
          createdAt: cur.createdAt,
          updatedAt: cur.updatedAt,
          tenant: cur.tenant,
          otherParticipant: cur.otherParticipant,
          lastMessage: cur.lastMessage,
          isUnread: false,
          property: cur.property,
          unit: cur.unit,
          maintenance: cur.maintenance,
        );
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingMessages = false;
      notifyListeners();
    }
  }

  /// Start or resume chat with a vendor (Landlord -> Vendor)
  Future<ChatSession?> startChatWithVendor(int vendorId, {String? vendorName, String? initialMessage}) async {
    try {
      final session = await _service.createSession(
        vendorId: vendorId,
        subject: vendorName != null ? 'Chat with $vendorName' : null,
        initialMessage: initialMessage,
      );
      
      final existingIdx = _sessions.indexWhere((s) => s.id == session.id);
      if (existingIdx != -1) {
        _sessions[existingIdx] = session;
      } else {
        _sessions.insert(0, session);
      }
      
      _activeSession = session;
      _activeSessionId = session.id;
      notifyListeners();

      await setActiveSession(session.id);
      return session;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Start or resume chat with any user (e.g. Tenant, Caretaker, Owner)
  Future<ChatSession?> startChatWithUser(int userId, {String? name, String? initialMessage}) async {
    try {
      final session = await _service.createSession(
        targetUserId: userId,
        subject: name != null ? 'Chat with $name' : null,
        initialMessage: initialMessage,
      );

      final existingIdx = _sessions.indexWhere((s) => s.id == session.id);
      if (existingIdx != -1) {
        _sessions[existingIdx] = session;
      } else {
        _sessions.insert(0, session);
      }

      _activeSession = session;
      _activeSessionId = session.id;
      notifyListeners();

      await setActiveSession(session.id);
      return session;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<void> createSession(int tenantId, {String? subject}) async {
    try {
      final session = await _service.createSession(tenantId: tenantId, subject: subject);
      _sessions.insert(0, session);
      _activeSession = session;
      _activeSessionId = session.id;
      notifyListeners();
      await setActiveSession(session.id);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void sendMessage(String text, {String? mediaUrl, int? replyToMessageId}) {
    if (_activeSessionId == null) return;
    final trimmed = text.trim();
    if (trimmed.isEmpty && mediaUrl == null) return;

    final messageType = mediaUrl != null ? 'IMAGE' : 'TEXT';
    _service.sendMessageViaSocket(
      _activeSessionId!,
      trimmed,
      messageType: messageType,
      mediaUrl: mediaUrl,
      replyToMessageId: replyToMessageId,
    );

    // Stop typing immediately on send
    _service.sendStopTyping(_activeSessionId!);
  }

  Future<void> sendImageAttachment(List<int> bytes, String filename, {String caption = ''}) async {
    if (_activeSessionId == null) return;
    _isUploadingAttachment = true;
    notifyListeners();

    try {
      final mediaUrl = await _service.uploadAttachment(bytes, filename);
      if (mediaUrl != null) {
        sendMessage(caption, mediaUrl: mediaUrl);
      }
    } catch (e) {
      print('Failed to upload image: $e');
    } finally {
      _isUploadingAttachment = false;
      notifyListeners();
    }
  }

  void reactToMessage(int messageId, String emoji) {
    if (_activeSessionId == null) return;
    // Optimistic reaction update
    final idx = _currentSessionMessages.indexWhere((m) => m.id == messageId);
    if (idx != -1) {
      final curReaction = _currentSessionMessages[idx].reaction;
      final newReaction = curReaction == emoji ? null : emoji;
      _currentSessionMessages[idx] = _currentSessionMessages[idx].copyWith(reaction: newReaction);
      notifyListeners();
    }
    _service.reactToMessage(messageId, _activeSessionId!, emoji);
  }

  void notifyTyping() {
    if (_activeSessionId != null) {
      _service.sendTyping(_activeSessionId!);
      _typingDebounce?.cancel();
      _typingDebounce = Timer(const Duration(seconds: 3), () {
        if (_activeSessionId != null) {
          _service.sendStopTyping(_activeSessionId!);
        }
      });
    }
  }

  @override
  void dispose() {
    _messageSub?.cancel();
    _reactionSub?.cancel();
    _typingSub?.cancel();
    _stopTypingSub?.cancel();
    _typingDebounce?.cancel();
    _service.dispose();
    super.dispose();
  }
}
