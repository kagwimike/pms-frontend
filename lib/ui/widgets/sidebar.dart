import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class Sidebar extends StatelessWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFF1E2733);
    const dividerColor = Color(0xFF334155);
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Container(
      width: 250,
      color: bgColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(user?.username ?? 'Guest User', user?.role ?? 'GUEST'),
          const Divider(color: dividerColor, height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 20),
              children: [
                _buildSectionTitle('CORE'),
                _buildNavItem(context, 'Home', '/'),
                _buildNavItem(context, 'Properties', '/properties'),
                _buildNavItem(context, 'Leases', '/leases'),
                const SizedBox(height: 16),
                _buildSectionTitle('MANAGEMENT'),
                _buildNavItem(context, 'Add Property', '/add-property'),
                _buildNavItem(context, 'Create Lease', '/create-lease'),
                const SizedBox(height: 16),
                _buildSectionTitle('FINANCIALS'),
                _buildNavItem(context, 'Global Invoices', '/invoices'),
                _buildNavItem(context, 'Collected Payments', '/payments'),
                _buildNavItem(context, 'Process Deposit Refund', '/refunds'),
                const SizedBox(height: 16),
                _buildSectionTitle('INSPECTIONS'),
                _buildNavItem(context, 'View Inspections', '/inspections'),
                _buildNavItem(context, 'New Inspection', '/new-inspection'),
                _buildNavItem(context, 'Record Damage', '/record-damage'),
                _buildNavItem(context, 'Deposit Summary', '/deposit-summary'),
                const SizedBox(height: 16),
                _buildSectionTitle('MAINTENANCE'),
                _buildNavItem(context, 'All Requests', '/maintenance-requests'),
                _buildNavItem(context, 'New Request', '/new-maintenance'),
                _buildNavItem(context, 'Vendors', '/vendors'),
                const SizedBox(height: 16),
                _buildSectionTitle('COMPANY'),
                _buildNavItem(context, 'About PMS Pro', '/about'),
                _buildNavItem(context, 'Contact', '/contact'),
                const SizedBox(height: 16),
                _buildSectionTitle('ACCOUNT'),
                _buildNavItem(context, 'Dashboard', '/dashboard'),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE5534B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () async {
                if (authProvider.isAuthenticated) {
                  await authProvider.logout();
                  if (context.mounted) {
                    context.go('/login');
                  }
                } else {
                  context.go('/login');
                }
              },
              child: Text(
                authProvider.isAuthenticated ? 'Logout' : 'Login',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(String name, String role) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFF3B82F6),
            radius: 24,
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'U',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  role,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 11,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF94A3B8),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, String title, String route) {
    final currentRoute = GoRouterState.of(context).uri.toString();
    final isActive = currentRoute == route;

    return InkWell(
      onTap: () {
        context.go(route);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Text(
          title,
          style: TextStyle(
            color: isActive ? Colors.white : const Color(0xFFE2E8F0),
            fontSize: 15,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
