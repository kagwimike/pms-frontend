import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../widgets/dashboard_sidebar.dart';
import '../ui/widgets/top_nav_bar.dart';
import 'properties_screen.dart';
import 'units_screen.dart';
import 'leases_screen.dart';
import 'invoices_screen.dart';
import 'tenants_screen.dart';
import 'maintenance_screen.dart';
import 'vendors_screen.dart';
import 'notifications_screen.dart';
import 'payments_screen.dart';
import 'inspections_screen.dart';
import 'documents_screen.dart';
import 'communication/communication_inbox_screen.dart';

class OwnerDashboard extends StatefulWidget {
  const OwnerDashboard({super.key});

  @override
  State<OwnerDashboard> createState() => _OwnerDashboardState();
}

class _OwnerDashboardState extends State<OwnerDashboard> {
  String _selectedNav = 'dashboard';
  final _auth = AuthService();
  final _api = ApiService();

  // Live dashboard stats
  int _propertyCount = 0;
  int _unitCount = 0;
  int _tenantCount = 0;
  int _maintenanceCount = 0;
  int _invoiceCount = 0;
  int _occupiedUnits = 0;
  int _vacantUnits = 0;
  double _potentialRent = 0;
  double _collectedRent = 0;
  double _outstandingRent = 0;
  bool _statsLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final propRes = await _api.getProperties(limit: 100);
      final unitRes = await _api.getUnits(limit: 200);
      final userRes = await _api.getUsers(limit: 200);
      final invoiceRes = await _api.getInvoices(limit: 200);
      final maintRes = await _api.getMaintenanceRequests(limit: 200);

      final props = ApiService.extractList(propRes);
      final units = ApiService.extractList(unitRes);
      final users = ApiService.extractList(userRes);
      final invoices = ApiService.extractList(invoiceRes);
      final maints = ApiService.extractList(maintRes);

      double potRent = 0;
      for (final u in units) {
        potRent += double.tryParse(u['rent_price']?.toString() ?? '0') ?? 0;
      }

      double collected = 0;
      double outstanding = 0;
      for (final inv in invoices) {
        final amount = double.tryParse(inv['amount']?.toString() ?? '0') ?? 0;
        final paid = double.tryParse(inv['amount_paid']?.toString() ?? '0') ?? 0;
        if (inv['status'] == 'PAID') {
          collected += amount;
        } else {
          outstanding += (amount - paid);
        }
      }

      final openMaint = maints.where((m) => m['status'] == 'PENDING' || m['status'] == 'IN_PROGRESS').length;
      final tenants = users.where((u) => u['role'] == 'TENANT').length;
      final occupied = units.where((u) => u['status'] == 'OCCUPIED').length;
      final vacant = units.where((u) => u['status'] == 'VACANT').length;

      if (mounted) {
        setState(() {
          _propertyCount = props.length;
          _unitCount = units.length;
          _tenantCount = tenants;
          _maintenanceCount = openMaint;
          _invoiceCount = invoices.where((i) => i['status'] == 'UNPAID' || i['status'] == 'PARTIAL').length;
          _occupiedUnits = occupied;
          _vacantUnits = vacant;
          _potentialRent = potRent;
          _collectedRent = collected;
          _outstandingRent = outstanding;
          _statsLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _statsLoading = false);
    }
  }

  static const _navItems = [
    SidebarItem(icon: Icons.dashboard_outlined, label: 'Dashboard', key: 'dashboard'),
    SidebarItem(icon: Icons.home_work_outlined, label: 'Properties', key: 'properties'),
    SidebarItem(icon: Icons.door_sliding_outlined, label: 'Units', key: 'units'),
    SidebarItem(icon: Icons.people_outline, label: 'Tenants', key: 'tenants'),
    SidebarItem(icon: Icons.description_outlined, label: 'Leases', key: 'leases'),
    SidebarItem(icon: Icons.receipt_long_outlined, label: 'Rent Collection', key: 'invoices'),
    SidebarItem(icon: Icons.account_balance_wallet_outlined, label: 'Deposits & Charges', key: 'payments'),
    SidebarItem(icon: Icons.build_outlined, label: 'Maintenance', key: 'maintenance'),
    SidebarItem(icon: Icons.engineering_outlined, label: 'Vendors', key: 'vendors'),
    SidebarItem(icon: Icons.checklist_outlined, label: 'Inspections', key: 'inspections'),
    SidebarItem(icon: Icons.folder_outlined, label: 'Documents', key: 'documents'),
    SidebarItem(icon: Icons.chat_bubble_outline, label: 'Messages', key: 'messages'),
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
    return TopNavBar(
      isCompact: isMobile,
      onNotificationTapped: () => setState(() => _selectedNav = 'notifications'),
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
        return const TenantsScreen();
      case 'leases':
        return const LeasesScreen();
      case 'invoices':
        return const InvoicesScreen();
      case 'payments':
        return const PaymentsScreen(isOwner: true);
      case 'maintenance':
        return const MaintenanceScreen(isOwner: true);
      case 'vendors':
        return const VendorsScreen();
      case 'inspections':
        return const InspectionsScreen(isOwner: true);
      case 'documents':
        return const DocumentsScreen(isOwner: true);
      case 'notifications':
        return const NotificationsScreen(isOwner: true);
      case 'messages':
        return const CommunicationInboxScreen();
      case 'settings':
        return _buildPlaceholder('Settings', Icons.settings_outlined, 'Manage your account and preferences');
      default:
        return _buildDashboardHome();
    }
  }

  String _fmtKsh(double v) {
    if (v >= 1000000) return 'KSh ${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return 'KSh ${(v / 1000).toStringAsFixed(0)}K';
    return 'KSh ${v.toStringAsFixed(0)}';
  }

  Widget _buildDashboardHome() {
    final username = _auth.user?.username ?? 'Owner';
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good morning' : (hour < 17 ? 'Good afternoon' : 'Good evening');

    if (_statsLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.teal));
    }

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
                  iconBg: AppTheme.teal.withValues(alpha: 0.1),
                  iconColor: AppTheme.teal,
                  value: '$_propertyCount',
                  label: 'Properties',
                  sublabel: 'Active managed properties',
                ),
                _StatCard(
                  icon: Icons.door_sliding_outlined,
                  iconBg: AppTheme.navy.withValues(alpha: 0.08),
                  iconColor: AppTheme.navy,
                  value: '$_unitCount',
                  label: 'Total Units',
                  sublabel: 'Available rental units',
                ),
                _StatCard(
                  icon: Icons.people_outline,
                  iconBg: AppTheme.brass.withValues(alpha: 0.12),
                  iconColor: AppTheme.brass,
                  value: '$_tenantCount',
                  label: 'Active Tenants',
                  sublabel: 'Currently active profiles',
                ),
                _StatCard(
                  icon: Icons.account_balance_wallet_outlined,
                  iconBg: Colors.green.withValues(alpha: 0.1),
                  iconColor: Colors.green.shade700,
                  value: _fmtKsh(_potentialRent),
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
                  iconBg: Colors.green.withValues(alpha: 0.1),
                  iconColor: Colors.green.shade700,
                  value: _fmtKsh(_collectedRent),
                  label: 'Collected This Month',
                  sublabel: 'Rent payments received this month',
                ),
                _StatCard(
                  icon: Icons.warning_amber_outlined,
                  iconBg: Colors.orange.withValues(alpha: 0.1),
                  iconColor: Colors.orange.shade700,
                  value: _fmtKsh(_outstandingRent),
                  label: 'Outstanding Rent',
                  sublabel: 'Remaining balances across schedules',
                ),
                _StatCard(
                  icon: Icons.schedule_outlined,
                  iconBg: Colors.red.withValues(alpha: 0.08),
                  iconColor: Colors.red.shade600,
                  value: '$_invoiceCount',
                  label: 'Unpaid Invoices',
                  sublabel: 'Invoices requiring attention',
                ),
                _StatCard(
                  icon: Icons.build_outlined,
                  iconBg: AppTheme.brass.withValues(alpha: 0.12),
                  iconColor: AppTheme.brass,
                  value: '$_maintenanceCount',
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
    final total = _occupiedUnits + _vacantUnits;
    final double occupancyRate = total > 0 ? _occupiedUnits / total : 0.0;
    final occupancyPercent = (occupancyRate * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
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
          LayoutBuilder(
            builder: (context, constraints) {
              final isVerySmall = constraints.maxWidth < 300;
              final content = [
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
                          value: occupancyRate,
                          strokeWidth: 20,
                          backgroundColor: AppTheme.border.withValues(alpha: 0.3),
                          valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.navy),
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                      Text(
                        '$occupancyPercent%',
                        style: GoogleFonts.bricolageGrotesque(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.navy,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isVerySmall) const SizedBox(width: 32) else const SizedBox(height: 24),
                Expanded(
                  flex: isVerySmall ? 0 : 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLegendItem(AppTheme.navy, 'Occupied units', '$_occupiedUnits'),
                      const SizedBox(height: 16),
                      _buildLegendItem(AppTheme.border, 'Vacant units', '$_vacantUnits'),
                    ],
                  ),
                ),
              ];
              
              if (isVerySmall) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: content,
                );
              }
              return Row(
                children: content,
              );
            },
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
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
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
              color: AppTheme.teal.withValues(alpha: 0.1),
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
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.dmSans(fontSize: 13, color: AppTheme.mutedText, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
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
            style: GoogleFonts.dmSans(fontSize: 11, color: AppTheme.mutedText.withValues(alpha: 0.7)),
          ),
        ],
      ),
    );
  }
}
