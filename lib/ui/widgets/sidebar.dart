import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';

class Sidebar extends StatelessWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final displayName = user?.firstName.isNotEmpty == true
        ? user!.firstName
        : user?.username ?? 'Property owner';
    final initials = displayName.isEmpty
        ? 'O'
        : displayName.substring(0, 1).toUpperCase();

    return Container(
      width: 258,
      color: const Color(0xFF163B36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 24, 18, 22),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFB8E1CB),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(
                    Icons.apartment_rounded,
                    color: Color(0xFF163B36),
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'PMS Pro',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Color(0xFF315B51), height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFFD7EBDD),
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: Color(0xFF27624D),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        user?.role == 'ADMIN'
                            ? 'Administrator'
                            : 'Property Owner',
                        style: const TextStyle(
                          color: Color(0xFFA9C7BB),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Color(0xFFA9C7BB),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _section('WORKSPACE'),
                _item(
                  context,
                  Icons.grid_view_rounded,
                  'Dashboard',
                  '/dashboard',
                ),
                _item(
                  context,
                  Icons.home_work_outlined,
                  'Properties',
                  '/properties',
                ),
                _item(
                  context,
                  Icons.meeting_room_outlined,
                  'Units',
                  '/units',
                ),
                _item(
                  context,
                  Icons.people_outline_rounded,
                  'Tenants',
                  '/leases',
                ),
                _item(
                  context,
                  Icons.payments_outlined,
                  'Payments',
                  '/payments',
                ),
                _item(
                  context,
                  Icons.calendar_month_outlined,
                  'Calendar',
                  '/inspections',
                ),
                const SizedBox(height: 18),
                _section('PROPERTY OPERATIONS'),
                _item(
                  context,
                  Icons.add_home_work_outlined,
                  'Add property',
                  '/properties',
                ),
                _item(context, Icons.assignment_outlined, 'Leases', '/leases'),
                _item(
                  context,
                  Icons.build_outlined,
                  'Maintenance',
                  '/maintenance-requests',
                ),
                _item(
                  context,
                  Icons.fact_check_outlined,
                  'Inspections',
                  '/inspections',
                ),
                const SizedBox(height: 18),
                _section('FINANCE & RECORDS'),
                _item(
                  context,
                  Icons.receipt_long_outlined,
                  'Invoices',
                  '/invoices',
                ),
                _item(
                  context,
                  Icons.description_outlined,
                  'Documents',
                  '/documents',
                ),
                _item(
                  context,
                  Icons.notifications_none_rounded,
                  'Notifications',
                  '/notifications',
                ),
                if (user?.role == 'ADMIN' || user?.role == 'OWNER')
                  _item(
                    context,
                    Icons.history_rounded,
                    'Audit logs',
                    '/auditlogs',
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
            child: _item(
              context,
              Icons.logout_rounded,
              auth.isAuthenticated ? 'Sign out' : 'Sign in',
              '/login',
              onTap: () async {
                if (auth.isAuthenticated) {
                  await auth.logout();
                  if (context.mounted) context.go('/login');
                } else {
                  context.go('/login');
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String title) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 8, 12, 7),
    child: Text(
      title,
      style: const TextStyle(
        color: Color(0xFF7FA99A),
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.3,
      ),
    ),
  );

  Widget _item(
    BuildContext context,
    IconData icon,
    String label,
    String route, {
    VoidCallback? onTap,
  }) {
    final active = GoRouterState.of(context).matchedLocation == route;
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Material(
        color: active ? const Color(0xFF2A6858) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap ?? () => context.go(route),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 19,
                  color: active ? Colors.white : const Color(0xFFA9C7BB),
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: active ? Colors.white : const Color(0xFFD4E5DE),
                    fontSize: 13,
                    fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
