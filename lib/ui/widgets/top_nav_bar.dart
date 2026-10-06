import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import 'search_panel.dart';

class TopNavBar extends StatelessWidget {
  final bool isCompact;

  const TopNavBar({super.key, this.isCompact = false});

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();

    return Container(
      height: 64,
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 16 : 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          if (isCompact) ...[
            IconButton(
              tooltip: 'Open navigation',
              onPressed: () => Scaffold.of(context).openDrawer(),
              icon: const Icon(Icons.menu_rounded, color: Color(0xFF475569)),
            ),
            const SizedBox(width: 8),
          ],
          
          // Global Search Trigger
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    showDialog(
                      context: context,
                      barrierColor: Colors.black.withValues(alpha: 0.4),
                      builder: (context) => const SearchPanelDialog(),
                    );
                  },
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search_rounded, size: 20, color: Color(0xFF64748B)),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Search PMS Pro...',
                            style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (!isCompact)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: const Color(0xFFCBD5E1)),
                            ),
                            child: const Text(
                              'Ctrl K',
                              style: TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Notifications
          IconButton(
            onPressed: () {
              Navigator.of(context).pushNamed('/notifications');
            },
            icon: const Badge(
              backgroundColor: Color(0xFFEF4444),
              child: Icon(Icons.notifications_none_rounded, color: Color(0xFF475569)),
            ),
          ),
          
          const SizedBox(width: 8),
          
          // User Dropdown (Sign out)
          PopupMenuButton<String>(
            offset: const Offset(0, 48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (value) async {
              if (value == 'logout') {
                await auth.logout();
                if (context.mounted) {
                  Navigator.of(context).pushReplacementNamed('/login');
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded, size: 20, color: Color(0xFFEF4444)),
                    SizedBox(width: 12),
                    Text('Sign out', style: TextStyle(color: Color(0xFFEF4444))),
                  ],
                ),
              ),
            ],
            child: CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFFD7EBDD),
              child: Builder(builder: (context) {
                final displayName = auth.user?.username ?? 'O';
                final initials = displayName.isNotEmpty ? displayName.substring(0, 1).toUpperCase() : 'O';
                return Text(
                  initials,
                  style: const TextStyle(
                    color: Color(0xFF27624D),
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
