import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../providers/chat_provider.dart';
import '../../models/communication/chat_session.dart';
import '../../models/communication/chat_message.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../config.dart';

class ChatView extends StatefulWidget {
  final ChatSession session;
  final bool isMobile;
  final VoidCallback? onBack;

  const ChatView({
    super.key,
    required this.session,
    this.isMobile = false,
    this.onBack,
  });

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> with TickerProviderStateMixin {
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final AuthService _authService = AuthService();
  final ImagePicker _picker = ImagePicker();

  int? _hoveredMessageId;
  int? _reactionPickerMessageId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().setActiveSession(widget.session.id);
    });
  }

  @override
  void didUpdateWidget(covariant ChatView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session.id != widget.session.id) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<ChatProvider>().setActiveSession(widget.session.id);
      });
    }
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Color _getRoleColor(String? role) {
    if (role == null) return Colors.grey.shade600;
    switch (role.toString().toUpperCase()) {
      case 'VENDOR':
        return const Color(0xFFF59E0B);
      case 'TENANT':
        return const Color(0xFF3B82F6);
      case 'OWNER':
        return const Color(0xFF10B981);
      case 'CARETAKER':
        return const Color(0xFF8B5CF6);
      case 'ADMIN':
        return const Color(0xFFEF4444);
      default:
        return Colors.grey.shade600;
    }
  }

  Future<void> _pickAndSendImage(ChatProvider provider) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        await provider.sendImageAttachment(bytes, image.name);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  void _sendMessage(ChatProvider provider) {
    final text = _msgCtrl.text.trim();
    if (text.isNotEmpty) {
      provider.sendMessage(text);
      _msgCtrl.clear();
      setState(() {});
    }
  }

  void _sendQuickReaction(ChatProvider provider, String emoji) {
    provider.sendMessage(emoji);
  }

  void _showSessionInfo(BuildContext context) {
    final session = widget.session;
    final other = session.otherParticipant;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E222B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: _getRoleColor(session.recipientRole),
                      child: Text(
                        session.recipientName.isNotEmpty ? session.recipientName[0].toUpperCase() : '?',
                        style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            session.recipientName,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : AppTheme.navy,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _getRoleColor(session.recipientRole).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              session.recipientRole,
                              style: GoogleFonts.dmSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: _getRoleColor(session.recipientRole),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(),
                if (other?['email'] != null && other!['email'].toString().isNotEmpty)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.email_outlined, color: AppTheme.teal),
                    title: const Text('Email'),
                    subtitle: Text(other['email'].toString()),
                  ),
                if (other?['phone'] != null && other!['phone'].toString().isNotEmpty)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.phone_outlined, color: AppTheme.teal),
                    title: const Text('Phone'),
                    subtitle: Text(other['phone'].toString()),
                    trailing: IconButton(
                      icon: const Icon(Icons.call, color: AppTheme.teal),
                      onPressed: () => launchUrl(Uri.parse('tel:${other['phone']}')),
                    ),
                  ),
                if (session.maintenance != null)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.build_circle_outlined, color: Colors.orange),
                    title: const Text('Maintenance Request'),
                    subtitle: Text(session.maintenance!['title'] ?? 'Ticket #${session.maintenanceId}'),
                  ),
                if (session.property != null)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.apartment_outlined, color: Colors.blue),
                    title: const Text('Property'),
                    subtitle: Text(session.property!['name'] ?? ''),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _authService.user?.id;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF13151B) : const Color(0xFFFAFBFC);
    final headerBg = isDark ? const Color(0xFF1A1D24) : Colors.white;
    final textColor = isDark ? Colors.white : AppTheme.navy;

    return Container(
      color: bgColor,
      child: Column(
        children: [
          // Header (Instagram / Facebook Messenger style)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: headerBg,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? Colors.white12 : Colors.grey.shade200,
                  width: 1,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  if (widget.isMobile)
                    IconButton(
                      icon: Icon(Icons.arrow_back_ios_new, size: 20, color: textColor),
                      onPressed: widget.onBack ?? () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  if (widget.isMobile) const SizedBox(width: 8),

                  // Avatar with online status
                  Stack(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _getRoleColor(widget.session.recipientRole).withValues(alpha: 0.85),
                              _getRoleColor(widget.session.recipientRole),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            widget.session.recipientName.isNotEmpty ? widget.session.recipientName[0].toUpperCase() : '?',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      PositionedDirectional(
                        bottom: 0,
                        end: 0,
                        child: Container(
                          width: 13,
                          height: 13,
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981), // active green
                            shape: BoxShape.circle,
                            border: Border.all(color: headerBg, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),

                  // Name, role, context badge
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                widget.session.recipientName,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: textColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: _getRoleColor(widget.session.recipientRole).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: _getRoleColor(widget.session.recipientRole).withValues(alpha: 0.25),
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                widget.session.recipientRole,
                                style: GoogleFonts.dmSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: _getRoleColor(widget.session.recipientRole),
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Consumer<ChatProvider>(
                              builder: (context, provider, _) {
                                final isTyping = provider.isSessionTyping(widget.session.id);
                                if (isTyping) {
                                  return Text(
                                    'typing...',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF0084FF),
                                    ),
                                  );
                                }
                                return Text(
                                  'Active now',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 12,
                                    color: isDark ? Colors.white54 : Colors.grey.shade500,
                                  ),
                                );
                              },
                            ),
                            if (widget.session.maintenance != null) ...[
                              Text(' • ', style: TextStyle(color: isDark ? Colors.white24 : Colors.grey.shade400)),
                              Flexible(
                                child: Text(
                                  'Ticket #${widget.session.maintenanceId}',
                                  style: GoogleFonts.dmSans(fontSize: 12, color: Colors.orange.shade700, fontWeight: FontWeight.w600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Actions
                  if (widget.session.otherParticipant != null && 
                      widget.session.otherParticipant!['phone'] != null && 
                      widget.session.otherParticipant!['phone'].toString().trim().isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.phone_outlined, size: 22, color: Color(0xFF0084FF)),
                      tooltip: 'Call Phone',
                      onPressed: () {
                        final phone = widget.session.otherParticipant!['phone'].toString();
                        launchUrl(Uri.parse('tel:$phone'));
                      },
                    ),
                  IconButton(
                    icon: Icon(Icons.info_outline, size: 22, color: isDark ? Colors.white70 : Colors.grey.shade700),
                    tooltip: 'Details',
                    onPressed: () => _showSessionInfo(context),
                  ),
                ],
              ),
            ),
          ),

          // Messages View
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, provider, child) {
                if (provider.isLoadingMessages) {
                  return const Center(child: CircularProgressIndicator(color: AppTheme.teal));
                }

                if (provider.error != null) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
                          const SizedBox(height: 12),
                          Text('Failed to load messages', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () => provider.setActiveSession(widget.session.id),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final messages = provider.currentMessages;

                if (messages.isEmpty) {
                  return _buildEmptyConversationState(isDark);
                }

                return GestureDetector(
                  onTap: () {
                    if (_reactionPickerMessageId != null) {
                      setState(() => _reactionPickerMessageId = null);
                    }
                  },
                  child: ListView.builder(
                    controller: _scrollCtrl,
                    reverse: true, // newest messages at bottom
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    itemCount: messages.length + (provider.isSessionTyping(widget.session.id) ? 1 : 0),
                    itemBuilder: (context, index) {
                      // If typing indicator row
                      if (provider.isSessionTyping(widget.session.id) && index == 0) {
                        return _buildTypingBubble(isDark);
                      }

                      final msgIndex = provider.isSessionTyping(widget.session.id) ? index - 1 : index;
                      final message = messages[messages.length - 1 - msgIndex];
                      final isMe = currentUserId != null && message.senderId == currentUserId;

                      return _buildMessageBubble(
                        message: message,
                        isMe: isMe,
                        isDark: isDark,
                        provider: provider,
                      );
                    },
                  ),
                );
              },
            ),
          ),

          // Uploading Attachment Progress Bar
          Consumer<ChatProvider>(
            builder: (context, provider, _) {
              if (provider.isUploadingAttachment) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: isDark ? const Color(0xFF1E222B) : const Color(0xFFEFF6FF),
                  child: Row(
                    children: [
                      const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0084FF))),
                      const SizedBox(width: 12),
                      Text('Uploading photo...', style: GoogleFonts.dmSans(fontSize: 13, color: const Color(0xFF0084FF))),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),

          // Composer Input Bar (Facebook Messenger / Instagram Direct style)
          _buildComposer(context, isDark),
        ],
      ),
    );
  }

  Widget _buildEmptyConversationState(bool isDark) {
    final roleColor = _getRoleColor(widget.session.recipientRole);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [roleColor.withValues(alpha: 0.8), roleColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: roleColor.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6)),
                ],
              ),
              child: Center(
                child: Text(
                  widget.session.recipientName.isNotEmpty ? widget.session.recipientName[0].toUpperCase() : '?',
                  style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.session.recipientName,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppTheme.navy,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${widget.session.recipientRole} • ${widget.session.recipientSubtitle}',
              style: GoogleFonts.dmSans(fontSize: 14, color: isDark ? Colors.white60 : Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Say hello or discuss property tasks! 👋',
                style: GoogleFonts.dmSans(fontSize: 13, color: isDark ? Colors.white70 : Colors.grey.shade700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingBubble(bool isDark) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8, top: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF262A34) : const Color(0xFFE4E6EB),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomRight: Radius.circular(18),
            bottomLeft: Radius.circular(4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildBouncingDot(0),
            const SizedBox(width: 4),
            _buildBouncingDot(1),
            const SizedBox(width: 4),
            _buildBouncingDot(2),
          ],
        ),
      ),
    );
  }

  Widget _buildBouncingDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + index * 200),
      builder: (context, val, child) {
        return Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: Colors.grey.shade600,
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  Widget _buildMessageBubble({
    required ChatMessage message,
    required bool isMe,
    required bool isDark,
    required ChatProvider provider,
  }) {
    final showReactionPicker = _reactionPickerMessageId == message.id;

    // Instagram / Messenger colors
    const sentGradient = LinearGradient(
      colors: [Color(0xFF0084FF), Color(0xFF0072E5)],
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
    );
    final receivedBg = isDark ? const Color(0xFF262A34) : const Color(0xFFE4E6EB);
    final receivedTextColor = isDark ? Colors.white : const Color(0xFF050505);

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredMessageId = message.id),
      onExit: (_) => setState(() {
        if (_hoveredMessageId == message.id) _hoveredMessageId = null;
      }),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Emoji reaction picker (floating bar on hover / long-press)
            if (showReactionPicker)
              _buildFloatingReactionPicker(message, provider, isDark),

            Row(
              mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Sender avatar for received messages
                if (!isMe) ...[
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: _getRoleColor(message.sender != null ? message.sender!['role']?.toString() : 'USER'),
                    child: Text(
                      message.senderName.isNotEmpty ? message.senderName[0].toUpperCase() : '?',
                      style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],

                // Action buttons on hover (react ❤️ icon)
                if (isMe && _hoveredMessageId == message.id && !showReactionPicker)
                  IconButton(
                    icon: const Icon(Icons.add_reaction_outlined, size: 18, color: Colors.grey),
                    tooltip: 'React',
                    onPressed: () => setState(() => _reactionPickerMessageId = message.id),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),

                // Main Bubble
                Flexible(
                  child: GestureDetector(
                    onLongPress: () => setState(() => _reactionPickerMessageId = message.id),
                    onDoubleTap: () => provider.reactToMessage(message.id, '❤️'),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          constraints: const BoxConstraints(maxWidth: 420),
                          padding: message.messageType == 'IMAGE' 
                              ? const EdgeInsets.all(4) 
                              : const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                          decoration: BoxDecoration(
                            gradient: isMe ? sentGradient : null,
                            color: isMe ? null : receivedBg,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(18),
                              topRight: const Radius.circular(18),
                              bottomLeft: isMe ? const Radius.circular(18) : const Radius.circular(4),
                              bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(18),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              )
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              // Sender name for other party
                              if (!isMe && message.sender != null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 2),
                                  child: Text(
                                    message.senderName,
                                    style: GoogleFonts.dmSans(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
                                      color: _getRoleColor(message.sender!['role']?.toString()),
                                    ),
                                  ),
                                ),

                              // Image message
                              if (message.messageType == 'IMAGE' && message.mediaUrl != null)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: Image.network(
                                    message.mediaUrl!.startsWith('http') 
                                        ? message.mediaUrl! 
                                        : '${AppConfig.apiBaseUrl.replaceAll('/api', '')}${message.mediaUrl}',
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      height: 140,
                                      color: Colors.grey.shade300,
                                      child: const Center(child: Icon(Icons.broken_image, size: 36)),
                                    ),
                                  ),
                                ),

                              // Message Text
                              if (message.message.isNotEmpty)
                                Padding(
                                  padding: EdgeInsets.only(top: message.messageType == 'IMAGE' ? 6 : 0),
                                  child: Text(
                                    message.message,
                                    style: GoogleFonts.dmSans(
                                      fontSize: 14.5,
                                      height: 1.35,
                                      color: isMe ? Colors.white : receivedTextColor,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        // Reaction Pill badge attached to bottom of bubble
                        if (message.reaction != null && message.reaction!.isNotEmpty)
                          Positioned(
                            bottom: -9,
                            right: isMe ? 8 : null,
                            left: isMe ? null : 8,
                            child: GestureDetector(
                              onTap: () => provider.reactToMessage(message.id, message.reaction!),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF262A34) : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isDark ? Colors.white12 : Colors.grey.shade300,
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    )
                                  ],
                                ),
                                child: Text(
                                  message.reaction!,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Action buttons on hover (react ❤️ icon for received)
                if (!isMe && _hoveredMessageId == message.id && !showReactionPicker)
                  IconButton(
                    icon: const Icon(Icons.add_reaction_outlined, size: 18, color: Colors.grey),
                    tooltip: 'React',
                    onPressed: () => setState(() => _reactionPickerMessageId = message.id),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),

            // Timestamp and read receipt
            Padding(
              padding: EdgeInsets.only(
                top: (message.reaction != null ? 8 : 3),
                right: isMe ? 4 : 0,
                left: isMe ? 0 : 36,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    timeago.format(message.createdAt, locale: 'en_short'),
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      color: isDark ? Colors.white38 : Colors.grey.shade500,
                    ),
                  ),
                  if (isMe) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.done_all, size: 14, color: Color(0xFF0084FF)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingReactionPicker(ChatMessage message, ChatProvider provider, bool isDark) {
    const emojis = ['❤️', '👍', '😂', '😮', '😢', '🔥'];

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF262A34) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: emojis.map((emoji) {
          final isSelected = message.reaction == emoji;
          return InkWell(
            onTap: () {
              provider.reactToMessage(message.id, emoji);
              setState(() => _reactionPickerMessageId = null);
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? (isDark ? Colors.white24 : Colors.grey.shade200) : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Text(emoji, style: const TextStyle(fontSize: 18)),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildComposer(BuildContext context, bool isDark) {
    final provider = context.read<ChatProvider>();
    final inputBg = isDark ? const Color(0xFF262A34) : const Color(0xFFF0F2F5);
    final textColor = isDark ? Colors.white : AppTheme.navy;
    final hasText = _msgCtrl.text.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1D24) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white12 : Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Attach image button
            IconButton(
              icon: const Icon(Icons.photo_library_outlined, size: 24, color: Color(0xFF0084FF)),
              tooltip: 'Send Photo',
              onPressed: () => _pickAndSendImage(provider),
            ),

            // Quick heart reaction
            IconButton(
              icon: const Icon(Icons.favorite_outline, size: 24, color: Color(0xFFE1306C)),
              tooltip: 'Send Heart',
              onPressed: () => _sendQuickReaction(provider, '❤️'),
            ),

            // Pill text field
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 120),
                decoration: BoxDecoration(
                  color: inputBg,
                  borderRadius: BorderRadius.circular(22),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _msgCtrl,
                  style: GoogleFonts.dmSans(color: textColor, fontSize: 14.5),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  decoration: InputDecoration(
                    hintText: 'Message...',
                    hintStyle: GoogleFonts.dmSans(
                      color: isDark ? Colors.white38 : Colors.grey.shade500,
                      fontSize: 14.5,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onChanged: (text) {
                    provider.notifyTyping();
                    setState(() {});
                  },
                  onSubmitted: (_) => _sendMessage(provider),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Send / Thumbs up button (Facebook Messenger style)
            if (hasText)
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0084FF), Color(0xFF00C6FF)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 20),
                  onPressed: () => _sendMessage(provider),
                ),
              )
            else
              IconButton(
                icon: const Icon(Icons.thumb_up, color: Color(0xFF0084FF), size: 24),
                tooltip: 'Send Thumbs Up',
                onPressed: () => _sendQuickReaction(provider, '👍'),
              ),
          ],
        ),
      ),
    );
  }
}
