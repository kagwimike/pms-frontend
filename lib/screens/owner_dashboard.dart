import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../widgets/dashboard_sidebar.dart';
import 'properties_screen.dart';
import 'units_screen.dart';
import 'leases_screen.dart';
import 'invoices_screen.dart';

class OwnerDashboard extends StatefulWidget {
  const OwnerDashboard({super.key});

  @override
  State<OwnerDashboard> createState() => _OwnerDashboardState();
}

class _OwnerDashboardState extends State<OwnerDashboard> {
  String _selectedNav = 'dashboard';
  final _auth = AuthService();

  static const _navItems = [
    SidebarItem(icon: Icons.dashboard_outlined, label: 'Dashboard', key: 'dashboard'),
    SidebarItem(icon: Icons.home_work_outlined, label: 'Properties', key: 'properties'),
    SidebarItem(icon: Icons.door_sliding_outlined, label: 'Units', key: 'units'),
    SidebarItem(icon: Icons.people_outline, label: 'Tenants', key: 'tenants'),
    SidebarItem(icon: Icons.description_outlined, label: 'Leases', key: 'leases'),
    SidebarItem(icon: Icons.receipt_long_outlined, label: 'Rent Collection', key: 'invoices'),
    SidebarItem(icon: Icons.account_balance_wallet_outlined, label: 'Deposits & Charges', key: 'payments'),
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
                  roleBadge: 'OWNER',
                  roleBadgeColor: AppTheme.teal,
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
                roleBadge: 'OWNER',
                roleBadgeColor: AppTheme.teal,
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
                _selectedNav[0].toUpperCase() + _selectedNav.substring(1),
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
      case 'properties':
        return const PropertiesScreen();
      case 'units':
        return const UnitsScreen();
      case 'tenants':
        return _buildPlaceholder('Tenants', Icons.people_outline, 'Manage tenant profiles and assignments');
      case 'leases':
        return const LeasesScreen();
      case 'invoices':
        return const InvoicesScreen();
      case 'payments':
        return _buildPlaceholder('Deposits & Charges', Icons.account_balance_wallet_outlined, 'Manage deposits, refunds, and charges');
      case 'maintenance':
        return _buildPlaceholder('Maintenance', Icons.build_outlined, 'View and manage maintenance requests');
      case 'inspections':
        return _buildPlaceholder('Inspections', Icons.checklist_outlined, 'Schedule and manage property inspections');
      case 'documents':
        return _buildPlaceholder('Documents', Icons.folder_outlined, 'Upload, view, and manage documents');
      case 'notifications':
        return _buildPlaceholder('Notifications', Icons.notifications_outlined, 'View all system notifications');
      case 'settings':
        return _buildPlaceholder('Settings', Icons.settings_outlined, 'Manage your account and preferences');
      default:
        return _buildDashboardHome();
    }
  }

  Widget _buildDashboardHome() {
    final username = _auth.user?.username ?? 'Owner';
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
            'Here is the current status of your property portfolio.',
            style: GoogleFonts.dmSans(fontSize: 14, color: AppTheme.mutedText),
          ),
          const SizedBox(height: 28),

          // ── Row 1: Primary Stats ──
          LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = constraints.maxWidth < 600 ? constraints.maxWidth : (constraints.maxWidth - 48) / 4;
              final cards = [
                _StatCard(
                  icon: Icons.home_work_outlined,
                  iconBg: AppTheme.teal.withOpacity(0.1),
                  iconColor: AppTheme.teal,
                  value: '3',
                  label: 'Properties',
                  sublabel: 'Active managed properties',
                ),
                _StatCard(
                  icon: Icons.door_sliding_outlined,
                  iconBg: AppTheme.navy.withOpacity(0.08),
                  iconColor: AppTheme.navy,
                  value: '8',
                  label: 'Total Units',
                  sublabel: 'Available rental units',
                ),
                _StatCard(
                  icon: Icons.people_outline,
                  iconBg: AppTheme.brass.withOpacity(0.12),
                  iconColor: AppTheme.brass,
                  value: '5',
                  label: 'Active Tenants',
                  sublabel: 'Currently active profiles',
                ),
                _StatCard(
                  icon: Icons.account_balance_wallet_outlined,
                  iconBg: Colors.green.withOpacity(0.1),
                  iconColor: Colors.green.shade700,
                  value: 'KSh 172,000',
                  label: 'Potential Rent',
                  sublabel: 'Monthly rent from active units',
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
          const SizedBox(height: 16),

          // ── Row 2: Financial Stats ──
          LayoutBuilder(
            builder: (context, constraints) {
              final cards = [
                _StatCard(
                  icon: Icons.check_circle_outline,
                  iconBg: Colors.green.withOpacity(0.1),
                  iconColor: Colors.green.shade700,
                  value: 'KSh 0.00',
                  label: 'Collected This Month',
                  sublabel: 'Rent payments received this month',
                ),
                _StatCard(
                  icon: Icons.warning_amber_outlined,
                  iconBg: Colors.orange.withOpacity(0.1),
                  iconColor: Colors.orange.shade700,
                  value: 'KSh 1,235,000',
                  label: 'Outstanding Rent',
                  sublabel: 'Remaining balances across schedules',
                ),
                _StatCard(
                  icon: Icons.schedule_outlined,
                  iconBg: Colors.red.withOpacity(0.08),
                  iconColor: Colors.red.shade600,
                  value: '10',
                  label: 'Overdue Accounts',
                  sublabel: 'Rent schedules requiring follow-up',
                ),
                _StatCard(
                  icon: Icons.build_outlined,
                  iconBg: AppTheme.brass.withOpacity(0.12),
                  iconColor: AppTheme.brass,
                  value: '2',
                  label: 'Open Maintenance',
                  sublabel: 'Unresolved maintenance requests',
                ),
              ];

              if (constraints.maxWidth < 600) {
                return Wrap(spacing: 16, runSpacing: 16, children: cards.map((c) => SizedBox(width: constraints.maxWidth, child: c)).toList());
              }
              return Row(
                children: cards.map((c) => Expanded(child: Padding(padding: const EdgeInsets.only(right: 16), child: c))).toList(),
              );
            },
          ).animate().fadeIn(duration: 500.ms, delay: 100.ms).slideY(begin: 0.05),
          const SizedBox(height: 28),

          // ── Row 3: Occupancy + Quick Actions ──
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 700) {
                return Column(
                  children: [
                    _buildOccupancyCard(),
                    const SizedBox(height: 16),
                    _buildQuickActionsCard(),
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: _buildOccupancyCard()),
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

  Widget _buildOccupancyCard() {
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
            'Occupancy Overview',
            style: GoogleFonts.bricolageGrotesque(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.navy),
          ),
          const SizedBox(height: 4),
          Text(
            'Occupied versus vacant active units.',
            style: GoogleFonts.dmSans(fontSize: 12, color: AppTheme.mutedText),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              // Donut chart representation
              SizedBox(
                width: 140,
                height: 140,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 140,
                      height: 140,
                      child: CircularProgressIndicator(
                        value: 0.63,
                        strokeWidth: 20,
                        backgroundColor: AppTheme.border.withOpacity(0.3),
                        valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.navy),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Text(
                      '63%',
                      style: GoogleFonts.bricolageGrotesque(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.navy,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 32),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLegendItem(AppTheme.navy, 'Occupied units', '5'),
                    const SizedBox(height: 16),
                    _buildLegendItem(AppTheme.border, 'Vacant units', '3'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label, String value) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.dmSans(fontSize: 13, color: AppTheme.mutedText),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.navy),
        ),
      ],
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
            'Add a new record',
            style: GoogleFonts.dmSans(fontSize: 12, color: AppTheme.mutedText),
          ),
          const SizedBox(height: 20),
          _buildActionRow(Icons.add_home_outlined, 'Add Property', () => setState(() => _selectedNav = 'properties')),
          _buildActionRow(Icons.door_sliding_outlined, 'Add Unit', () => setState(() => _selectedNav = 'units')),
          _buildActionRow(Icons.person_add_outlined, 'Add Tenant', () => setState(() => _selectedNav = 'tenants')),
          _buildActionRow(Icons.description_outlined, 'Create Lease', () => setState(() => _selectedNav = 'leases')),
          _buildActionRow(Icons.build_outlined, 'Add Maintenance Request', () => setState(() => _selectedNav = 'maintenance')),
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
              color: AppTheme.teal.withOpacity(0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(icon, size: 40, color: AppTheme.teal),
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
