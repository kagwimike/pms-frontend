import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../services/dashboard_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/dashboard_sidebar.dart';
import 'vendor_jobs_screen.dart';
import '../../ui/widgets/top_nav_bar.dart';
import '../../screens/notifications_screen.dart';
class VendorDashboardScreen extends StatefulWidget {
  const VendorDashboardScreen({super.key});

  @override
  State<VendorDashboardScreen> createState() => _VendorDashboardScreenState();
}

class _VendorDashboardScreenState extends State<VendorDashboardScreen> {
  String _selectedNav = 'dashboard';
  final _authService = AuthService();

  final List<SidebarItem> _navItems = [
    const SidebarItem(key: 'dashboard', label: 'Dashboard', icon: Icons.dashboard_outlined),
    const SidebarItem(key: 'jobs', label: 'My Jobs', icon: Icons.handyman_outlined),
    const SidebarItem(key: 'messages', label: 'Messages', icon: Icons.chat_bubble_outline),
    const SidebarItem(key: 'notifications', label: 'Alerts', icon: Icons.notifications_none),
    const SidebarItem(key: 'settings', label: 'Settings', icon: Icons.settings_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgGreyGreen,
      drawer: MediaQuery.of(context).size.width < 900
          ? Drawer(
              child: DashboardSidebar(
                items: _navItems,
                selectedKey: _selectedNav,
                onItemSelected: (key) {
                  setState(() => _selectedNav = key);
                  Navigator.pop(context);
                },
                roleBadge: 'VENDOR',
                roleBadgeColor: AppTheme.teal,
              ),
            )
          : null,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 900;

          if (isMobile) {
            return Column(
              children: [
                _buildTopBar(isMobile: true),
                Expanded(child: _buildContent()),
              ],
            );
          }

          return Row(
            children: [
              DashboardSidebar(
                items: _navItems,
                selectedKey: _selectedNav,
                onItemSelected: (key) => setState(() => _selectedNav = key),
                roleBadge: 'VENDOR',
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
        return const _VendorHomeView();
      case 'jobs':
        return const VendorJobsScreen();
      case 'messages':
        return const Center(child: Text('Messages Placeholder'));
      case 'notifications':
        return const NotificationsScreen(isOwner: false);
      default:
        return const Center(child: Text('Coming Soon'));
    }
  }
}

class _VendorHomeView extends StatefulWidget {
  const _VendorHomeView();

  @override
  State<_VendorHomeView> createState() => _VendorHomeViewState();
}

class _VendorHomeViewState extends State<_VendorHomeView> {
  final _dashboardService = DashboardService();
  final _authService = AuthService();
  late Future<Map<String, dynamic>> _dashboardFuture;

  @override
  void initState() {
    super.initState();
    _dashboardFuture = _dashboardService.getVendorDashboard();
  }

  void _refresh() {
    setState(() {
      _dashboardFuture = _dashboardService.getVendorDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _dashboardFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.teal));
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text('Error loading dashboard: ${snapshot.error}'),
                TextButton(onPressed: _refresh, child: const Text('Retry')),
              ],
            ),
          );
        }

        final data = snapshot.data ?? {};
        final jobs = data['jobs'] ?? {};

        return RefreshIndicator(
          onRefresh: () async {
            _refresh();
            await _dashboardFuture;
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildGreeting(),
                const SizedBox(height: 32),
                _buildKPIGrid(jobs),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGreeting() {
    final user = _authService.user;
    final firstName = user?.username ?? 'Vendor';
    final date = DateFormat('EEEE, MMMM d').format(DateTime.now());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Good morning, $firstName',
          style: GoogleFonts.bricolageGrotesque(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: AppTheme.navy,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          date,
          style: GoogleFonts.dmSans(
            fontSize: 16,
            color: AppTheme.mutedText,
          ),
        ),
      ],
    );
  }

  Widget _buildKPIGrid(Map<String, dynamic> jobs) {
    return GridView.count(
      crossAxisCount: MediaQuery.of(context).size.width > 800 ? 3 : 1,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.0,
      children: [
        _buildKPICard('Assigned', jobs['assigned']?.toString() ?? '0', Icons.assignment_outlined, AppTheme.teal),
        _buildKPICard('In Progress', jobs['inProgress']?.toString() ?? '0', Icons.autorenew_rounded, AppTheme.brass),
        _buildKPICard('Completed', jobs['completed']?.toString() ?? '0', Icons.check_circle_outline, AppTheme.navy),
      ],
    );
  }

  Widget _buildKPICard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    color: AppTheme.mutedText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: AppTheme.navy,
            ),
          ),
        ],
      ),
    );
  }
}
