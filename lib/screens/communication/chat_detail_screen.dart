import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/chat_provider.dart';
import '../../models/communication/chat_session.dart';
import '../../services/auth_service.dart';

class ChatDetailScreen extends StatefulWidget {
  final ChatSession session;

  const ChatDetailScreen({super.key, required this.session});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final AuthService _authService = AuthService();
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().setActiveSession(widget.session.id);
    });
  }

  void _loadCurrentUser() {
    final user = _authService.user;
    if (user != null) {
      setState(() {
        _currentUserId = user.id;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.session.subject ?? 'Chat #${widget.session.id}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              // Show session details
            },
          ),
        ],
      ),
      body: Consumer<ChatProvider>(
        builder: (context, chatProvider, child) {
          if (chatProvider.isLoadingMessages) {
            return const Center(child: CircularProgressIndicator());
          }

          if (chatProvider.error != null) {
            return Center(child: Text(chatProvider.error!, style: const TextStyle(color: Colors.red)));
          }

          final messages = chatProvider.currentMessages;

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  reverse: true, // Show newest at bottom
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    // Reverse index because ListView is reversed
                    final msg = messages[messages.length - 1 - index];
                    final isMe = _currentUserId != null && msg.senderId == _currentUserId;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                        decoration: BoxDecoration(
                          color: isMe ? Theme.of(context).primaryColor : Colors.grey[200],
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(0),
                            bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(16),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            if (!isMe && msg.sender != null) ...[
                              Text(
                                msg.sender!['first_name'] ?? 'Support',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 2),
                            ],
                            Text(
                              msg.message,
                              style: TextStyle(
                                color: isMe ? Colors.white : Colors.black87,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              _buildMessageInput(chatProvider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMessageInput(ChatProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.attach_file),
              onPressed: () {
                // Attach file logic
              },
            ),
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                onChanged: (_) {
                  provider.notifyTyping();
                },
                onSubmitted: (text) => _sendMessage(provider),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor,
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white),
                onPressed: () => _sendMessage(provider),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendMessage(ChatProvider provider) {
    final text = _messageController.text;
    if (text.trim().isNotEmpty) {
      provider.sendMessage(text);
      _messageController.clear();
    }
  }
}
