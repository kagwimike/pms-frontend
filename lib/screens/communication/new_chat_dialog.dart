import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/chat_provider.dart';
import '../../models/communication/chat_session.dart';
import '../../theme/app_theme.dart';

class NewChatDialog extends StatefulWidget {
  final Function(ChatSession session)? onSessionCreated;

  const NewChatDialog({super.key, this.onSessionCreated});

  @override
  State<NewChatDialog> createState() => _NewChatDialogState();
}

class _NewChatDialogState extends State<NewChatDialog> {
  final TextEditingController _searchCtrl = TextEditingController();
  final TextEditingController _initialMsgCtrl = TextEditingController();
  String _selectedCategory = 'ALL'; // ALL, VENDOR, TENANT, STAFF
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().fetchContacts();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _initialMsgCtrl.dispose();
    super.dispose();
  }

  Color _getRoleColor(String role) {
    switch (role.toUpperCase()) {
      case 'VENDOR':
        return const Color(0xFFF59E0B); // Amber / orange
      case 'TENANT':
        return const Color(0xFF3B82F6); // Blue
      case 'OWNER':
        return const Color(0xFF10B981); // Emerald green
      case 'CARETAKER':
        return const Color(0xFF8B5CF6); // Purple
      case 'ADMIN':
        return const Color(0xFFEF4444); // Red
      default:
        return Colors.grey.shade600;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role.toUpperCase()) {
      case 'VENDOR':
        return Icons.handyman_outlined;
      case 'TENANT':
        return Icons.home_outlined;
      case 'OWNER':
        return Icons.apartment_outlined;
      case 'CARETAKER':
        return Icons.shield_outlined;
      default:
        return Icons.person_outline;
    }
  }

  Future<void> _startChat(Map<String, dynamic> contact) async {
    setState(() => _isCreating = true);
    final provider = context.read<ChatProvider>();
    final initialMessage = _initialMsgCtrl.text.trim().isNotEmpty ? _initialMsgCtrl.text.trim() : null;

    ChatSession? session;
    if (contact['vendor_id'] != null) {
      session = await provider.startChatWithVendor(
        contact['vendor_id'],
        vendorName: contact['name'],
        initialMessage: initialMessage,
      );
    } else if (contact['id'] != null) {
      session = await provider.startChatWithUser(
        contact['id'],
        name: contact['name'],
        initialMessage: initialMessage,
      );
    }

    setState(() => _isCreating = false);

    if (mounted) {
      Navigator.of(context).pop();
      if (session != null && widget.onSessionCreated != null) {
        widget.onSessionCreated!(session);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = isDark ? const Color(0xFF1A1D24) : Colors.white;
    final textColor = isDark ? Colors.white : AppTheme.navy;

    return Dialog(
      backgroundColor: dialogBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 680),
        child: Column(
          children: [
            // Header (Instagram / Messenger style)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? Colors.white12 : Colors.grey.shade200,
                  ),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.close, color: textColor, size: 22),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'New Message',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                  ),
                  if (_isCreating)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.teal),
                    ),
                ],
              ),
            ),

            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF262A34) : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _searchCtrl,
                  style: GoogleFonts.dmSans(color: textColor, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search vendors, tenants, staff...',
                    hintStyle: GoogleFonts.dmSans(
                      color: isDark ? Colors.white38 : Colors.grey.shade500,
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: isDark ? Colors.white54 : Colors.grey.shade500,
                      size: 20,
                    ),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onChanged: (val) => setState(() {}),
                ),
              ),
            ),

            // Category Filter Pills
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('ALL', 'All Contacts', Icons.people_outline),
                    const SizedBox(width: 8),
                    _buildFilterChip('VENDOR', 'Vendors 🛠️', Icons.handyman_outlined),
                    const SizedBox(width: 8),
                    _buildFilterChip('TENANT', 'Tenants 🏠', Icons.home_outlined),
                    const SizedBox(width: 8),
                    _buildFilterChip('STAFF', 'Staff & Landlords 👔', Icons.badge_outlined),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Contact List
            Expanded(
              child: Consumer<ChatProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoadingContacts) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppTheme.teal),
                    );
                  }

                  final contacts = provider.contacts.where((c) {
                    // Filter category
                    final role = (c['role'] ?? '').toString().toUpperCase();
                    if (_selectedCategory == 'VENDOR' && role != 'VENDOR') return false;
                    if (_selectedCategory == 'TENANT' && role != 'TENANT') return false;
                    if (_selectedCategory == 'STAFF' && !['OWNER', 'CARETAKER', 'ADMIN'].contains(role)) return false;

                    // Filter search
                    final query = _searchCtrl.text.trim().toLowerCase();
                    if (query.isNotEmpty) {
                      final name = (c['name'] ?? '').toString().toLowerCase();
                      final email = (c['email'] ?? '').toString().toLowerCase();
                      final phone = (c['phone'] ?? '').toString().toLowerCase();
                      final subtitle = (c['subtitle'] ?? '').toString().toLowerCase();
                      return name.contains(query) || email.contains(query) || phone.contains(query) || subtitle.contains(query);
                    }
                    return true;
                  }).toList();

                  if (contacts.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.person_search_outlined,
                            size: 48,
                            color: isDark ? Colors.white24 : Colors.grey.shade400,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No contacts found',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Try a different search term or category.',
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              color: isDark ? Colors.white54 : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    itemCount: contacts.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      color: isDark ? Colors.white10 : Colors.grey.shade100,
                    ),
                    itemBuilder: (context, index) {
                      final contact = contacts[index];
                      final name = contact['name'] ?? 'Contact';
                      final role = (contact['role'] ?? 'USER').toString();
                      final subtitle = contact['subtitle'] ?? contact['email'] ?? '';
                      final roleColor = _getRoleColor(role);
                      final roleIcon = _getRoleIcon(role);

                      return InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: _isCreating ? null : () => _startChat(contact),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                          child: Row(
                            children: [
                              // Avatar
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      roleColor.withValues(alpha: 0.85),
                                      roleColor,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: roleColor.withValues(alpha: 0.25),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    )
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),

                              // Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            name,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
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
                                            color: roleColor.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(
                                              color: roleColor.withValues(alpha: 0.3),
                                              width: 0.8,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(roleIcon, size: 11, color: roleColor),
                                              const SizedBox(width: 3),
                                              Text(
                                                role.toUpperCase(),
                                                style: GoogleFonts.dmSans(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w700,
                                                  color: roleColor,
                                                  letterSpacing: 0.4,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      subtitle,
                                      style: GoogleFonts.dmSans(
                                        fontSize: 13,
                                        color: isDark ? Colors.white60 : Colors.grey.shade600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),

                              // Chat action button
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF0084FF), Color(0xFF00C6FF)],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF0084FF).withValues(alpha: 0.3),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    )
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.chat_bubble_outline, size: 14, color: Colors.white),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Chat',
                                      style: GoogleFonts.plusJakartaSans(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // Optional Initial message bar
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E222B) : const Color(0xFFF9FAFB),
                border: Border(
                  top: BorderSide(
                    color: isDark ? Colors.white10 : Colors.grey.shade200,
                  ),
                ),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _initialMsgCtrl,
                      style: GoogleFonts.dmSans(color: textColor, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Type an initial greeting (optional)...',
                        hintStyle: GoogleFonts.dmSans(
                          color: isDark ? Colors.white38 : Colors.grey.shade500,
                          fontSize: 13,
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: isDark ? Colors.white12 : Colors.grey.shade300,
                          ),
                        ),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF262A34) : Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String key, String label, IconData icon) {
    final isSelected = _selectedCategory == key;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () => setState(() => _selectedCategory = key),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? Colors.white : AppTheme.navy)
              : (isDark ? const Color(0xFF262A34) : const Color(0xFFF3F4F6)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? (isDark ? Colors.black : Colors.white)
                : (isDark ? Colors.white70 : Colors.grey.shade700),
          ),
        ),
      ),
    );
  }
}
