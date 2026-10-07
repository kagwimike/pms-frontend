import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../config.dart';

class TicketChatWidget extends StatefulWidget {
  final int maintenanceId;

  const TicketChatWidget({super.key, required this.maintenanceId});

  @override
  State<TicketChatWidget> createState() => _TicketChatWidgetState();
}

class _TicketChatWidgetState extends State<TicketChatWidget> {
  final ApiService _api = ApiService();
  final _authService = AuthService();
  
  bool _isLoading = true;
  String? _error;
  
  int? _sessionId;
  List<dynamic> _messages = [];
  
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  
  IO.Socket? _socket;

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  Future<void> _initChat() async {
    try {
      final sessionRes = await _api.getSessionByMaintenance(widget.maintenanceId);
      if (!mounted) return;
      
      _sessionId = sessionRes['id'];
      
      if (_sessionId != null) {
        final msgsRes = await _api.getMessages(_sessionId!);
        if (mounted) {
          setState(() {
            _messages = msgsRes['data'] ?? msgsRes;
            _isLoading = false;
          });
          _scrollToBottom();
          _connectSocket();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().contains('404') ? 'Chat session not found for this ticket.' : e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _connectSocket() {
    if (_sessionId == null) return;
    
    _socket = IO.io(AppConfig.apiBaseUrl.replaceAll('/api/v1', ''), <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'auth': {'token': _authService.accessToken},
    });

    _socket!.connect();

    _socket!.onConnect((_) {
      _socket!.emit('join_session', _sessionId);
    });

    _socket!.on('receive_message', (data) {
      if (mounted) {
        setState(() => _messages.add(data));
        _scrollToBottom();
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _sessionId == null) return;
    
    _msgCtrl.clear();
    
    try {
      // Send via REST API, which will broadcast to socket
      await _api.sendMessage(_sessionId!, text);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to send: $e')));
      }
    }
  }

  @override
  void dispose() {
    _socket?.disconnect();
    _socket?.dispose();
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: AppTheme.teal));
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(_error!, style: const TextStyle(color: Colors.red)),
        ),
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppTheme.border)),
          ),
          child: Row(
            children: [
              const Icon(Icons.forum_outlined, color: AppTheme.navy),
              const SizedBox(width: 8),
              Text('Ticket Communication', style: GoogleFonts.bricolageGrotesque(fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        Expanded(
          child: _messages.isEmpty
              ? Center(child: Text('No messages yet. Start the conversation!', style: GoogleFonts.dmSans(color: AppTheme.mutedText)))
              : ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    final sender = msg['sender'] ?? {};
                    final isMe = sender['id'].toString() == _authService.user?.id.toString();
                    final time = DateTime.tryParse(msg['created_at'] ?? '');
                    
                    return _buildMessageBubble(
                      text: msg['message'] ?? '',
                      senderName: '${sender['first_name'] ?? ''} ${sender['last_name'] ?? ''}'.trim(),
                      role: sender['role'] ?? 'USER',
                      isMe: isMe,
                      time: time,
                    );
                  },
                ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppTheme.border)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _msgCtrl,
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(color: AppTheme.border),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                backgroundColor: AppTheme.teal,
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white, size: 18),
                  onPressed: _sendMessage,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessageBubble({
    required String text,
    required String senderName,
    required String role,
    required bool isMe,
    required DateTime? time,
  }) {
    final bgColor = isMe ? AppTheme.teal : Colors.grey.shade100;
    final textColor = isMe ? Colors.white : AppTheme.navy;
    final align = isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    
    // Formatting role tag
    String roleTag = '';
    if (role == 'VENDOR') roleTag = 'Vendor';
    if (role == 'CARETAKER') roleTag = 'Caretaker';
    if (role == 'OWNER') roleTag = 'Manager';
    if (role == 'TENANT') roleTag = 'Tenant';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: align,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(isMe ? 'You' : (senderName.isEmpty ? 'Unknown' : senderName), style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              if (!isMe && roleTag.isNotEmpty) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(4)),
                  child: Text(roleTag, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                ),
              ]
            ],
          ),
          const SizedBox(height: 4),
          Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16).copyWith(
                bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(16),
                bottomLeft: !isMe ? const Radius.circular(0) : const Radius.circular(16),
              ),
            ),
            child: Text(text, style: GoogleFonts.dmSans(color: textColor, fontSize: 14)),
          ),
          if (time != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(timeago.format(time), style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
            ),
        ],
      ),
    );
  }
}
