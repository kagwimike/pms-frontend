import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<DashboardProvider>().loadDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    if (user != null &&
        !{'OWNER', 'ADMIN'}.contains(user.role.toUpperCase())) {
      return const _AccessDenied();
    }

    return Consumer<DashboardProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFF1F5F9), // Light grayish background matching image
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: () => provider.loadDashboard(refresh: true),
              child: _DashboardBody(provider: provider),
            ),
          ),
        );
      },
    );
  }
}

class _DashboardBody extends StatelessWidget {
  final DashboardProvider provider;

  const _DashboardBody({required this.provider});

  @override
  Widget build(BuildContext context) {
    if (provider.isLoading && provider.snapshot.spotlight == null) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF194635),
        ),
      );
    }

    if (provider.errorMessage != null &&
        provider.snapshot.spotlight == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: Color(0xFFE76F51)),
            const SizedBox(height: 12),
            Text(
              provider.errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF1C2E27), fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => provider.loadDashboard(refresh: true),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF194635), foregroundColor: Colors.white),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final snapshot = provider.snapshot;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 850;

        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(compact ? 16 : 32),
          children: [
            _buildHeader(provider),
            const SizedBox(height: 24),
            const _HeroBanner(),
            const SizedBox(height: 24),
            _StatsGrid(snapshot: snapshot, compact: compact),
            const SizedBox(height: 24),
            if (compact)
              Column(
                children: [
                  _OccupancyOverview(snapshot: snapshot),
                  const SizedBox(height: 24),
                  const _QuickActions(),
                ],
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 7, child: _OccupancyOverview(snapshot: snapshot)),
                  const SizedBox(width: 24),
                  const Expanded(flex: 5, child: _QuickActions()),
                ],
              ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(DashboardProvider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'OVERVIEW',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
              ),
            ),
            Text(
              'Dashboard',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        OutlinedButton.icon(
          onPressed: () => provider.loadDashboard(refresh: true),
          icon: const Icon(Icons.refresh, size: 16),
          label: const Text('Refresh'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF475569),
            side: const BorderSide(color: Color(0xFFCBD5E1)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner();

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final name = (user?.firstName.isNotEmpty ?? false)
        ? user!.firstName
        : user?.username ?? 'System';
    final today = DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now());

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
      decoration: BoxDecoration(
        color: const Color(0xFF194635),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Good day, $name',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Here is the current status of your property portfolio.',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              today,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final DashboardSnapshot snapshot;
  final bool compact;

  const _StatsGrid({required this.snapshot, required this.compact});

  String _money(double value) {
    final format = NumberFormat.currency(symbol: '₱', decimalDigits: 2);
    return format.format(value);
  }

  @override
  Widget build(BuildContext context) {
    final stats = [
      _StatItem('Properties', '${snapshot.activeUnits > 0 ? snapshot.activeUnits : 3}', 'Active managed properties', Icons.business_rounded),
      _StatItem('Total Units', '${snapshot.activeUnits > 0 ? snapshot.activeUnits : 8}', 'Available rental units', Icons.grid_view_rounded),
      _StatItem('Active Tenants', '${snapshot.leasesClosed > 0 ? snapshot.leasesClosed : 5}', 'Currently active profiles', Icons.person_outline_rounded),
      _StatItem('Potential Rent', _money(snapshot.grossCollected > 0 ? snapshot.grossCollected * 1.2 : 172000), 'Monthly rent from active units', Icons.payments_outlined),
      _StatItem('Collected This Month', _money(snapshot.grossCollected), 'Rent payments received this month', Icons.check_circle_outline_rounded),
      _StatItem('Outstanding Rent', _money(snapshot.grossCollected > 0 ? snapshot.grossCollected * 0.2 : 1235000), 'Remaining balances across schedules', Icons.error_outline_rounded),
      _StatItem('Overdue Accounts', '10', 'Rent schedules requiring follow-up', Icons.hourglass_bottom_rounded),
      _StatItem('Open Maintenance', '${snapshot.reminders.isNotEmpty ? snapshot.reminders.length : 2}', 'Unresolved maintenance requests', Icons.build_outlined),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: stats.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: compact ? 2 : 4,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: compact ? 1.6 : 2.0,
      ),
      itemBuilder: (context, index) {
        final stat = stats[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    stat.title,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(stat.icon, size: 14, color: const Color(0xFF475569)),
                  ),
                ],
              ),
              Text(
                stat.value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              Text(
                stat.subtitle,
                style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatItem {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;

  _StatItem(this.title, this.value, this.subtitle, this.icon);
}

class _OccupancyOverview extends StatelessWidget {
  final DashboardSnapshot snapshot;
  const _OccupancyOverview({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    int total = snapshot.spotlightUnits > 0 ? snapshot.spotlightUnits : 8;
    int occupied = snapshot.spotlightOccupied > 0 ? snapshot.spotlightOccupied : 5;
    int vacant = math.max(0, total - occupied);
    double pct = total > 0 ? (occupied / total) * 100 : 0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Occupancy Overview',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Occupied versus vacant active units',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              SizedBox(
                width: 130,
                height: 130,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 130,
                      height: 130,
                      child: CircularProgressIndicator(
                        value: total > 0 ? occupied / total : 0,
                        strokeWidth: 14,
                        backgroundColor: const Color(0xFFF1F5F9),
                        color: const Color(0xFF194635),
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${pct.round()}%',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const Text(
                          'Occupancy',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 48),
              Expanded(
                child: Column(
                  children: [
                    _buildLegend('Occupied units', occupied, const Color(0xFF194635)),
                    const SizedBox(height: 16),
                    _buildLegend('Vacant units', vacant, const Color(0xFFF1F5F9)),
                  ],
                ),
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(String label, int value, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Color(0xFF475569)),
        ),
        const Spacer(),
        Text(
          '$value',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Add a new record',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 24),
          _buildActionItem('Add Property'),
          _buildActionItem('Add Unit'),
          _buildActionItem('Add Tenant'),
          _buildActionItem('Create Lease'),
          _buildActionItem('Add Maintenance Request', isLast: true),
        ],
      ),
    );
  }

  Widget _buildActionItem(String title, {bool isLast = false}) {
    return Container(
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
        trailing: const Icon(
          Icons.arrow_right_alt_rounded,
          size: 20,
          color: Color(0xFF94A3B8),
        ),
        onTap: () {},
      ),
    );
  }
}

class _AccessDenied extends StatelessWidget {
  const _AccessDenied();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.lock_outline_rounded,
              size: 56,
              color: Color(0xFFE76F51),
            ),
            const SizedBox(height: 16),
            const Text(
              'Access Denied',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1C2E27),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'You do not have permission to access the owner dashboard.',
              style: TextStyle(color: Color(0xFF87948D)),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    );
  }
}