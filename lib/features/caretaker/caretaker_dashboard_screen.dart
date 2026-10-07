import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../services/dashboard_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/dashboard_sidebar.dart';
import '../../screens/maintenance_screen.dart';
import 'incident_logging_screen.dart';
import 'caretaker_reports_screen.dart';
import '../../ui/widgets/top_nav_bar.dart';
import '../../screens/notifications_screen.dart';

class CaretakerDashboardScreen extends StatefulWidget {
  const CaretakerDashboardScreen({super.key});

  @override
  State<CaretakerDashboardScreen> createState() => _CaretakerDashboardScreenState();
}

class _CaretakerDashboardScreenState extends State<CaretakerDashboardScreen> {
  String _selectedNav = 'dashboard';
  final _authService = AuthService();

  final List<SidebarItem> _navItems = [
    const SidebarItem(key: 'dashboard', label: 'Dashboard', icon: Icons.dashboard_outlined),
    const SidebarItem(key: 'maintenance', label: 'Maintenance', icon: Icons.build_circle_outlined),
    const SidebarItem(key: 'incidents', label: 'Incidents', icon: Icons.report_problem_outlined),
    const SidebarItem(key: 'reports', label: 'Reports & SLAs', icon: Icons.bar_chart_outlined),
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
                roleBadge: 'CARETAKER',
                roleBadgeColor: AppTheme.brass,
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
                roleBadge: 'CARETAKER',
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
    return TopNavBar(
      isCompact: isMobile,
      onNotificationTapped: () => setState(() => _selectedNav = 'notifications'),
    );
  }

  Widget _buildContent() {
    switch (_selectedNav) {
      case 'dashboard':
        return const _CaretakerHomeView();
      case 'maintenance':
        // isOwner: true gives them the management view for assigning vendors and status updates
        return const MaintenanceScreen(isOwner: true);
      case 'incidents':
        return const IncidentLoggingScreen();
      case 'reports':
        return const CaretakerReportsScreen();
      case 'messages':
        return const Center(child: Text('Messages Placeholder'));
      case 'notifications':
        return const NotificationsScreen(isOwner: false);
      default:
        return const Center(child: Text('Coming Soon'));
    }
  }
}

class _CaretakerHomeView extends StatefulWidget {
  const _CaretakerHomeView();

  @override
  State<_CaretakerHomeView> createState() => _CaretakerHomeViewState();
}

class _CaretakerHomeViewState extends State<_CaretakerHomeView> {
  final _dashboardService = DashboardService();
  final _authService = AuthService();
  late Future<Map<String, dynamic>> _dashboardFuture;

  @override
  void initState() {
    super.initState();
    _dashboardFuture = _dashboardService.getCaretakerDashboard();
  }

  void _refresh() {
    setState(() {
      _dashboardFuture = _dashboardService.getCaretakerDashboard();
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
        final maintenance = data['maintenance'] ?? {};
        final vendors = data['vendors'] ?? {};
        final priorities = data['priorities'] as List<dynamic>? ?? [];

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
                _buildKPIGrid(maintenance, vendors),
                const SizedBox(height: 32),
                _buildPrioritiesList(priorities),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGreeting() {
    final user = _authService.user;
    final firstName = user?.username ?? 'Caretaker';
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

  Widget _buildKPIGrid(Map<String, dynamic> maintenance, Map<String, dynamic> vendors) {
    return GridView.count(
      crossAxisCount: MediaQuery.of(context).size.width > 800 ? 4 : 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.5,
      children: [
        _buildKPICard('Urgent', maintenance['urgent']?.toString() ?? '0', Icons.warning_amber_rounded, Colors.red.shade600),
        _buildKPICard('Open Jobs', maintenance['open']?.toString() ?? '0', Icons.build_circle_outlined, AppTheme.teal),
        _buildKPICard('In Progress', maintenance['inProgress']?.toString() ?? '0', Icons.autorenew_rounded, AppTheme.brass),
        _buildKPICard('Active Vendors', vendors['active']?.toString() ?? '0', Icons.handyman_outlined, AppTheme.navy),
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

  Widget _buildPrioritiesList(List<dynamic> priorities) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Today\'s Priorities',
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppTheme.navy,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (priorities.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
            ),
            child: Text(
              'No pressing issues today.',
              style: GoogleFonts.dmSans(color: AppTheme.mutedText),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: priorities.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final job = priorities[index];
              return _buildPriorityItem(job);
            },
          ),
      ],
    );
  }

  Widget _buildPriorityItem(dynamic job) {
    final title = job['title'] ?? 'Unknown Issue';
    final priority = job['priority'] ?? 'MEDIUM';
    final status = job['status'] ?? 'PENDING';
    final property = job['property']?['name'] ?? 'Unknown Property';
    final unit = job['unit']?['unit_number'] ?? '';

    Color priorityColor = AppTheme.teal;
    if (priority == 'URGENT') priorityColor = Colors.red.shade600;
    if (priority == 'HIGH') priorityColor = Colors.orange.shade600;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 48,
            decoration: BoxDecoration(
              color: priorityColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: priorityColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        priority,
                        style: GoogleFonts.dmSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: priorityColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      status,
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: AppTheme.mutedText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: GoogleFonts.dmSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.navy,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 14, color: AppTheme.mutedText),
                    const SizedBox(width: 4),
                    Text(
                      unit.isNotEmpty ? '$property - Unit $unit' : property,
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        color: AppTheme.mutedText,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.navy,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Open'),
          ),
        ],
      ),
    );
  }
}
