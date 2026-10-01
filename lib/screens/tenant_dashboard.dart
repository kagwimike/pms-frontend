import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../widgets/dashboard_sidebar.dart';

class TenantDashboard extends StatefulWidget {
  const TenantDashboard({super.key});

  @override
  State<TenantDashboard> createState() => _TenantDashboardState();
}

class _TenantDashboardState extends State<TenantDashboard> {
  String _selectedNav = 'dashboard';
  final _auth = AuthService();

  static const _navItems = [
    SidebarItem(icon: Icons.dashboard_outlined, label: 'Dashboard', key: 'dashboard'),
    SidebarItem(icon: Icons.home_outlined, label: 'My Home', key: 'home'),
    SidebarItem(icon: Icons.description_outlined, label: 'My Lease', key: 'lease'),
    SidebarItem(icon: Icons.receipt_long_outlined, label: 'Rent & Invoices', key: 'invoices'),
    SidebarItem(icon: Icons.account_balance_wallet_outlined, label: 'Payment History', key: 'payments'),
    SidebarItem(icon: Icons.build_outlined, label: 'Maintenance', key: 'maintenance'),
    SidebarItem(icon: Icons.checklist_outlined, label: 'Inspections', key: 'inspections'),
    SidebarItem(icon: Icons.folder_outlined, label: 'Documents', key: 'documents'),
    SidebarItem(icon: Icons.notifications_outlined, label: 'Notifications', key: 'notifications'),
    SidebarItem(icon: Icons.settings_outlined, label: 'Settings', key: 'settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgGreyGreen,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 900;

          if (isMobile) {
            return Scaffold(
              backgroundColor: AppTheme.bgGreyGreen,
              drawer: SizedBox(
                width: 260,
                child: DashboardSidebar(
                  items: _navItems,
                  selectedKey: _selectedNav,
                  onItemSelected: (key) {
                    setState(() => _selectedNav = key);
                    Navigator.of(context).pop();
                  },
                  roleBadge: 'TENANT',
                  roleBadgeColor: AppTheme.brass,
                ),
              ),
              body: Column(
                children: [
                  _buildTopBar(isMobile: true),
                  Expanded(child: _buildContent()),
                ],
              ),
            );
          }

          return Row(
            children: [
              DashboardSidebar(
                items: _navItems,
                selectedKey: _selectedNav,
                onItemSelected: (key) => setState(() => _selectedNav = key),
                roleBadge: 'TENANT',
                roleBadgeColor: AppTheme.brass,
              ),
              Expanded(
                child: Column(
                  children: [
                    _buildTopBar(isMobile: false),
                    Expanded(child: _buildContent()),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTopBar({required bool isMobile}) {
    final now = DateTime.now();
    final months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final dateStr = '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}, ${now.year}';

    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 32, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          if (isMobile)
            Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(Icons.menu, color: AppTheme.navy),
                onPressed: () => Scaffold.of(ctx).openDrawer(),
              ),
            ),
          if (isMobile) const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _selectedNav[0].toUpperCase() + _selectedNav.substring(1).replaceAll('_', ' '),
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.navy,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            dateStr,
            style: GoogleFonts.dmSans(fontSize: 13, color: AppTheme.mutedText),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.bgGreyGreen,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.notifications_outlined, size: 20, color: AppTheme.navy),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedNav) {
      case 'dashboard':
        return _buildDashboardHome();
      case 'home':
        return _buildPlaceholder('My Home', Icons.home_outlined, 'View property and unit details');
      case 'lease':
        return _buildPlaceholder('My Lease', Icons.description_outlined, 'View lease agreement and terms');
      case 'invoices':
        return _buildPlaceholder('Rent & Invoices', Icons.receipt_long_outlined, 'View and pay rent');
      case 'payments':
        return _buildPlaceholder('Payment History', Icons.account_balance_wallet_outlined, 'View past payments');
      case 'maintenance':
        return _buildPlaceholder('Maintenance', Icons.build_outlined, 'Report and track maintenance issues');
      case 'inspections':
        return _buildPlaceholder('Inspections', Icons.checklist_outlined, 'View inspection reports');
      case 'documents':
        return _buildPlaceholder('Documents', Icons.folder_outlined, 'Access your lease and other documents');
      case 'notifications':
        return _buildPlaceholder('Notifications', Icons.notifications_outlined, 'View all system notifications');
      case 'settings':
        return _buildPlaceholder('Settings', Icons.settings_outlined, 'Manage your account and preferences');
      default:
        return _buildDashboardHome();
    }
  }

  Widget _buildDashboardHome() {
    final username = _auth.user?.username ?? 'Tenant';
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good morning' : (hour < 17 ? 'Good afternoon' : 'Good evening');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting
          Text(
            '$greeting, $username',
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: AppTheme.navy,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Here is the current status of your rental.',
            style: GoogleFonts.dmSans(fontSize: 14, color: AppTheme.mutedText),
          ),
          const SizedBox(height: 28),

          // ── Row 1: Primary Stats ──
          LayoutBuilder(
            builder: (context, constraints) {
              final cards = [
                _StatCard(
                  icon: Icons.home_outlined,
                  iconBg: AppTheme.teal.withOpacity(0.1),
                  iconColor: AppTheme.teal,
                  value: 'A-101',
                  label: 'My Unit',
                  sublabel: 'Oceanview Apartments',
                ),
                _StatCard(
                  icon: Icons.description_outlined,
                  iconBg: AppTheme.navy.withOpacity(0.08),
                  iconColor: AppTheme.navy,
                  value: 'Active',
                  label: 'Lease Status',
                  sublabel: 'Valid until Sep 2027',
                ),
                _StatCard(
                  icon: Icons.account_balance_wallet_outlined,
                  iconBg: AppTheme.brass.withOpacity(0.12),
                  iconColor: AppTheme.brass,
                  value: 'KSh 45,000',
                  label: 'Monthly Rent',
                  sublabel: 'Due on 5th of every month',
                ),
                _StatCard(
                  icon: Icons.build_outlined,
                  iconBg: Colors.orange.withOpacity(0.1),
                  iconColor: Colors.orange.shade700,
                  value: '1',
                  label: 'Open Maintenance',
                  sublabel: 'Active requests',
                ),
              ];

              if (constraints.maxWidth < 600) {
                return Wrap(spacing: 16, runSpacing: 16, children: cards.map((c) => SizedBox(width: constraints.maxWidth, child: c)).toList());
              }
              return Row(
                children: cards.map((c) => Expanded(child: Padding(padding: const EdgeInsets.only(right: 16), child: c))).toList(),
              );
            },
          ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.05),
          const SizedBox(height: 28),

          // ── Row 2: Next Payment + Quick Actions ──
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 700) {
                return Column(
                  children: [
                    _buildNextPaymentCard(),
                    const SizedBox(height: 16),
                    _buildQuickActionsCard(),
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: _buildNextPaymentCard()),
                  const SizedBox(width: 16),
                  Expanded(flex: 2, child: _buildQuickActionsCard()),
                ],
              );
            },
          ).animate().fadeIn(duration: 500.ms, delay: 200.ms).slideY(begin: 0.05),
        ],
      ),
    );
  }

  Widget _buildNextPaymentCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Next Payment',
                style: GoogleFonts.bricolageGrotesque(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.navy),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'UNPAID',
                  style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.red.shade700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.bgGreyGreen,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.receipt_long_outlined, size: 32, color: AppTheme.navy),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'October 2026 Rent',
                      style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.navy),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Due: 05 Oct 2026',
                      style: GoogleFonts.dmSans(fontSize: 14, color: AppTheme.mutedText),
                    ),
                  ],
                ),
              ),
              Text(
                'KSh 45,000',
                style: GoogleFonts.bricolageGrotesque(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.navy),
              ),
            ],
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // Implement M-Pesa payment flow
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('PAY NOW WITH M-PESA', style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: GoogleFonts.bricolageGrotesque(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.navy),
          ),
          const SizedBox(height: 4),
          Text(
            'What do you need to do?',
            style: GoogleFonts.dmSans(fontSize: 12, color: AppTheme.mutedText),
          ),
          const SizedBox(height: 20),
          _buildActionRow(Icons.build_outlined, 'Report Maintenance', () => setState(() => _selectedNav = 'maintenance')),
          _buildActionRow(Icons.description_outlined, 'View Lease', () => setState(() => _selectedNav = 'lease')),
          _buildActionRow(Icons.account_balance_wallet_outlined, 'Payment History', () => setState(() => _selectedNav = 'payments')),
        ],
      ),
    );
  }

  Widget _buildActionRow(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppTheme.navy),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.navy),
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.mutedText),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(String title, IconData icon, String description) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.brass.withOpacity(0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(icon, size: 40, color: AppTheme.brass),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: GoogleFonts.bricolageGrotesque(fontSize: 24, fontWeight: FontWeight.w700, color: AppTheme.navy),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: GoogleFonts.dmSans(fontSize: 14, color: AppTheme.mutedText),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.bgGreyGreen,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.border),
            ),
            child: Text(
              'Coming soon',
              style: GoogleFonts.dmSans(fontSize: 13, color: AppTheme.mutedText),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String value;
  final String label;
  final String sublabel;

  const _StatCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.value,
    required this.label,
    required this.sublabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: GoogleFonts.dmSans(fontSize: 13, color: AppTheme.mutedText, fontWeight: FontWeight.w500),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppTheme.navy,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            sublabel,
            style: GoogleFonts.dmSans(fontSize: 11, color: AppTheme.mutedText.withOpacity(0.7)),
          ),
        ],
      ),
    );
  }
}
