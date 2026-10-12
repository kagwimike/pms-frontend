import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../providers/chat_provider.dart';
import '../../theme/app_theme.dart';
import 'chat_view.dart';
import 'chat_detail_screen.dart';
import 'new_chat_dialog.dart';

class CommunicationInboxScreen extends StatefulWidget {
  final int? initialVendorId;
  final int? initialUserId;

  const CommunicationInboxScreen({
    super.key,
    this.initialVendorId,
    this.initialUserId,
  });

  @override
  State<CommunicationInboxScreen> createState() => _CommunicationInboxScreenState();
}

class _CommunicationInboxScreenState extends State<CommunicationInboxScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<ChatProvider>();
      await provider.initialize();

      if (widget.initialVendorId != null) {
        await provider.startChatWithVendor(widget.initialVendorId!);
      } else if (widget.initialUserId != null) {
        await provider.startChatWithUser(widget.initialUserId!);
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Color _getRoleColor(String role) {
    switch (role.toUpperCase()) {
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

  void _openNewChatDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => NewChatDialog(
        onSessionCreated: (session) {
          final isDesktop = MediaQuery.of(context).size.width >= 720;
          if (!isDesktop) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ChatDetailScreen(session: session)),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = MediaQuery.of(context).size.width >= 720;
    final bgColor = isDark ? const Color(0xFF13151B) : const Color(0xFFF7F9F8);
    final sidebarBg = isDark ? const Color(0xFF1A1D24) : Colors.white;
    final textColor = isDark ? Colors.white : AppTheme.navy;

    final content = LayoutBuilder(
      builder: (context, constraints) {
        if (!isDesktop) {
          // Mobile layout: single column list
          return _buildMobileView(context, isDark, sidebarBg, textColor);
        }

        // Desktop / Tablet layout: Instagram Direct / Messenger split pane
        return SizedBox(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left Conversations Sidebar
              SizedBox(
                width: 380,
                child: Container(
                  decoration: BoxDecoration(
                    color: sidebarBg,
                    border: Border(
                      right: BorderSide(
                        color: isDark ? Colors.white12 : Colors.grey.shade200,
                        width: 1,
                      ),
                    ),
                  ),
                  child: _buildSidebarContent(context, isDark, textColor, isDesktop: true),
                ),
              ),

              // Right Conversation View or Empty State
              Expanded(
                child: Consumer<ChatProvider>(
                  builder: (context, provider, child) {
                    final activeSession = provider.activeSession;
                    if (activeSession != null) {
                      return ChatView(
                        key: ValueKey(activeSession.id),
                        session: activeSession,
                        isMobile: false,
                      );
                    }
                    return _buildDesktopEmptyState(isDark, textColor);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );

    return Scaffold(
      backgroundColor: bgColor,
      body: content,
      floatingActionButton: !isDesktop
          ? FloatingActionButton(
              backgroundColor: const Color(0xFF0084FF),
              onPressed: () => _openNewChatDialog(context),
              child: const Icon(Icons.edit_outlined, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildMobileView(BuildContext context, bool isDark, Color sidebarBg, Color textColor) {
    return Container(
      color: sidebarBg,
      child: SafeArea(
        child: _buildSidebarContent(context, isDark, textColor, isDesktop: false),
      ),
    );
  }

  Widget _buildSidebarContent(BuildContext context, bool isDark, Color textColor, {required bool isDesktop}) {
    return Consumer<ChatProvider>(
      builder: (context, provider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar: "Messages" & Compose button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0084FF), Color(0xFF00C6FF)],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.send_rounded, size: 16, color: Colors.white),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Messages',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white12 : Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.edit_square,
                        size: 18,
                        color: textColor,
                      ),
                    ),
                    tooltip: 'New Message',
                    onPressed: () => _openNewChatDialog(context),
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF262A34) : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _searchCtrl,
                  style: GoogleFonts.dmSans(color: textColor, fontSize: 13.5),
                  decoration: InputDecoration(
                    hintText: 'Search messages...',
                    hintStyle: GoogleFonts.dmSans(
                      color: isDark ? Colors.white38 : Colors.grey.shade500,
                      fontSize: 13.5,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: isDark ? Colors.white54 : Colors.grey.shade500,
                      size: 18,
                    ),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 16),
                            onPressed: () {
                              _searchCtrl.clear();
                              provider.setSearchQuery('');
                              setState(() {});
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onChanged: (val) {
                    provider.setSearchQuery(val);
                    setState(() {});
                  },
                ),
              ),
            ),

            // Filter Tabs (All, Unread, Vendors, Tenants, Staff)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip(provider, 'ALL', 'All'),
                    const SizedBox(width: 6),
                    _buildFilterChip(provider, 'UNREAD', 'Unread'),
                    const SizedBox(width: 6),
                    _buildFilterChip(provider, 'VENDOR', 'Vendors 🛠️'),
                    const SizedBox(width: 6),
                    _buildFilterChip(provider, 'TENANT', 'Tenants 🏠'),
                    const SizedBox(width: 6),
                    _buildFilterChip(provider, 'STAFF', 'Staff 👔'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 4),

            // Conversations List
            Expanded(
              child: RefreshIndicator(
                color: AppTheme.teal,
                onRefresh: () => provider.fetchSessions(),
                child: _buildConversationsList(context, provider, isDark, textColor, isDesktop),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterChip(ChatProvider provider, String filterKey, String label) {
    final isSelected = provider.selectedFilter == filterKey;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () => provider.setFilter(filterKey),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF0084FF)
              : (isDark ? const Color(0xFF262A34) : const Color(0xFFF3F4F6)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.white70 : Colors.grey.shade700),
          ),
        ),
      ),
    );
  }

  Widget _buildConversationsList(
    BuildContext context,
    ChatProvider provider,
    bool isDark,
    Color textColor,
    bool isDesktop,
  ) {
    if (provider.isLoadingSessions) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.teal));
    }

    if (provider.error != null && provider.sessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off_outlined, size: 40, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text('Failed to load conversations', style: GoogleFonts.dmSans(color: Colors.grey)),
            TextButton(
              onPressed: () => provider.fetchSessions(),
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    final sessions = provider.filteredSessions;

    if (sessions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.chat_bubble_outline_rounded,
                size: 52,
                color: isDark ? Colors.white24 : Colors.grey.shade300,
              ),
              const SizedBox(height: 12),
              Text(
                'No conversations',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Start a chat with a vendor, tenant, or staff member.',
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: isDark ? Colors.white54 : Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.add_comment_outlined, size: 16),
                label: const Text('New Message'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0084FF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                onPressed: () => _openNewChatDialog(context),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      itemCount: sessions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 2),
      itemBuilder: (context, index) {
        final session = sessions[index];
        final isSelected = isDesktop && provider.activeSessionId == session.id;
        final roleColor = _getRoleColor(session.recipientRole);
        final isTyping = provider.isSessionTyping(session.id);

        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              provider.setActiveSession(session.id);
              if (!isDesktop) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ChatDetailScreen(session: session)),
                );
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDark ? const Color(0xFF262A34) : const Color(0xFFEBF5FF))
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                border: isSelected
                    ? Border.all(color: const Color(0xFF0084FF).withValues(alpha: 0.3), width: 1.2)
                    : null,
              ),
              child: Row(
                children: [
                  // Avatar with Online dot & Role indicator
                  Stack(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [roleColor.withValues(alpha: 0.85), roleColor],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            session.recipientName.isNotEmpty ? session.recipientName[0].toUpperCase() : '?',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontSize: 20,
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
                            color: const Color(0xFF10B981),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark ? const Color(0xFF1A1D24) : Colors.white,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),

                  // Middle info: Name, subtitle, last message snippet
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      session.recipientName,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 14.5,
                                        fontWeight: session.isUnread ? FontWeight.w800 : FontWeight.w600,
                                        color: textColor,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: roleColor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      session.recipientRole,
                                      style: GoogleFonts.dmSans(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: roleColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              timeago.format(session.updatedAt, locale: 'en_short'),
                              style: GoogleFonts.dmSans(
                                fontSize: 11,
                                fontWeight: session.isUnread ? FontWeight.w700 : FontWeight.w500,
                                color: session.isUnread
                                    ? const Color(0xFF0084FF)
                                    : (isDark ? Colors.white38 : Colors.grey.shade500),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Expanded(
                              child: isTyping
                                  ? Text(
                                      'typing...',
                                      style: GoogleFonts.dmSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF0084FF),
                                      ),
                                    )
                                  : Text(
                                      session.previewMessage,
                                      style: GoogleFonts.dmSans(
                                        fontSize: 13,
                                        fontWeight: session.isUnread ? FontWeight.w700 : FontWeight.w400,
                                        color: session.isUnread
                                            ? textColor
                                            : (isDark ? Colors.white60 : Colors.grey.shade600),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                            ),
                            if (session.isUnread) ...[
                              const SizedBox(width: 8),
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF0084FF),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDesktopEmptyState(bool isDark, Color textColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF0084FF).withValues(alpha: 0.1),
                  const Color(0xFF00C6FF).withValues(alpha: 0.15),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF0084FF).withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.send_outlined,
                size: 44,
                color: Color(0xFF0084FF),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Your Messages',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 340),
            child: Text(
              'Send private messages, updates, and photos to vendors, tenants, and caretakers.',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 14,
                color: isDark ? Colors.white60 : Colors.grey.shade600,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.edit_square, size: 18),
            label: const Text('Send Message'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0084FF),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              elevation: 2,
            ),
            onPressed: () => _openNewChatDialog(context),
          ),
        ],
      ),
    );
  }
}
