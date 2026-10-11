import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../widgets/search_overlay.dart';
import '../../widgets/quick_create_modal.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';

class TopNavBar extends StatefulWidget {
  final bool isCompact;
  final VoidCallback? onNotificationTapped;

  const TopNavBar({super.key, this.isCompact = false, this.onNotificationTapped});

  @override
  State<TopNavBar> createState() => _TopNavBarState();
}

class _TopNavBarState extends State<TopNavBar> {
  final AuthService _auth = AuthService();
  final ApiService _apiService = ApiService();
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
  }

  Future<void> _loadUnreadCount() async {
    try {
      final res = await _apiService.getNotifications(limit: 50);
      final notifications = res['data'] ?? [];
      int unread = 0;
      for (var n in notifications) {
        if (n['read'] == false || n['read'] == 0) {
          unread++;
        }
      }
      if (mounted) {
        setState(() {
          _unreadCount = unread;
        });
      }
    } catch (e) {
      // Ignore error for notifications badge
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF18181B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0);
    final searchBgColor = isDark ? const Color(0xFF27272A) : const Color(0xFFF1F5F9);
    final iconColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);
    final textMuted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF94A3B8);

    return Container(
      height: 64,
      padding: EdgeInsets.symmetric(horizontal: widget.isCompact ? 16 : 24),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Row(
        children: [
          if (widget.isCompact) ...[
            IconButton(
              tooltip: 'Open navigation',
              onPressed: () => Scaffold.of(context).openDrawer(),
              icon: Icon(Icons.menu_rounded, color: iconColor),
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
                      builder: (context) => const SearchOverlay(),
                    );
                  },
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: searchBgColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.search_rounded, size: 20, color: iconColor),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Search PMS Pro...',
                            style: TextStyle(
                              fontSize: 14,
                              color: textMuted,
                            ),
                          ),
                        ),
                        if (!widget.isCompact)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: borderColor),
                            ),
                            child: Text(
                              'Ctrl K',
                              style: TextStyle(
                                color: textMuted,
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
          
          const SizedBox(width: 24),
          
          // + New Button
          ElevatedButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const QuickCreateModal(),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF27624D), // AppTheme.teal
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              minimumSize: const Size(0, 36),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              elevation: 0,
            ),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('New', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          
          const SizedBox(width: 12),
          
          // Upgrade Button
          if (!widget.isCompact)
            TextButton.icon(
              onPressed: () {},
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF27624D).withValues(alpha: 0.1),
                foregroundColor: const Color(0xFF27624D),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                minimumSize: const Size(0, 36),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              icon: const Icon(Icons.rocket_launch_outlined, size: 16),
              label: const Text('Upgrade', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          
          const SizedBox(width: 16),
          
          // Theme toggle (Dynamic icon depending on current mode)
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, _) {
              IconData currentIcon;
              String tooltipText;
              switch (themeProvider.themeMode) {
                case ThemeMode.light:
                  currentIcon = Icons.light_mode_outlined;
                  tooltipText = 'Theme: Light';
                  break;
                case ThemeMode.dark:
                  currentIcon = Icons.dark_mode_outlined;
                  tooltipText = 'Theme: Dark';
                  break;
                case ThemeMode.system:
                  currentIcon = Icons.brightness_auto_outlined;
                  tooltipText = 'Theme: System';
                  break;
              }

              return PopupMenuButton<ThemeMode>(
                tooltip: tooltipText,
                icon: Icon(currentIcon, color: iconColor),
                offset: const Offset(0, 40),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                initialValue: themeProvider.themeMode,
                onSelected: (mode) => themeProvider.setThemeMode(mode),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: ThemeMode.system,
                    child: Row(
                      children: [
                        Icon(Icons.brightness_auto_outlined, size: 20, color: themeProvider.themeMode == ThemeMode.system ? Theme.of(context).primaryColor : null),
                        const SizedBox(width: 12),
                        const Text('System Default'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: ThemeMode.light,
                    child: Row(
                      children: [
                        Icon(Icons.light_mode_outlined, size: 20, color: themeProvider.themeMode == ThemeMode.light ? Theme.of(context).primaryColor : null),
                        const SizedBox(width: 12),
                        const Text('Light Mode'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: ThemeMode.dark,
                    child: Row(
                      children: [
                        Icon(Icons.dark_mode_outlined, size: 20, color: themeProvider.themeMode == ThemeMode.dark ? Theme.of(context).primaryColor : null),
                        const SizedBox(width: 12),
                        const Text('Dark Mode'),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
            
          const SizedBox(width: 8),
          
          // Notifications
          IconButton(
            onPressed: () {
              if (widget.onNotificationTapped != null) {
                widget.onNotificationTapped!();
                _loadUnreadCount();
              } else {
                Navigator.of(context).pushNamed('/notifications').then((_) => _loadUnreadCount());
              }
            },
            icon: Badge(
              isLabelVisible: _unreadCount > 0,
              label: Text(_unreadCount > 99 ? '99+' : _unreadCount.toString()),
              backgroundColor: const Color(0xFFEF4444),
              child: Icon(Icons.notifications_none_rounded, color: iconColor),
            ),
          ),
          
          const SizedBox(width: 8),
          
          // User Dropdown (Sign out)
          PopupMenuButton<String>(
            offset: const Offset(0, 48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (value) async {
              if (value == 'logout') {
                await _auth.logout();
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
                final displayName = _auth.user?.username ?? 'O';
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

