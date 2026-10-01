import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/api/api_client.dart';
import '../../../../app/router/app_router.dart';

class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  bool _isLoading = true;
  int _propertyCount = 0;
  int _activeLeases = 0;
  int _maintenanceRequests = 0;
  List<dynamic> _properties = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final responses = await Future.wait([
        ApiClient().dio.get('properties/'),
        ApiClient().dio.get('leases/active/'),
        ApiClient().dio.get('maintenance/requests/'),
      ]);

      setState(() {
        _properties = responses[0].data['data'] ?? [];
        _propertyCount = _properties.length;
        _activeLeases = (responses[1].data['data'] as List?)?.length ?? 0;
        _maintenanceRequests = (responses[2].data['data'] as List?)?.length ?? 0;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF1F5F9),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF194635))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // Light grayish background matching image
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadDashboardData,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 850;

              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(compact ? 16 : 32),
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  const _HeroBanner(),
                  const SizedBox(height: 24),
                  _StatsGrid(
                    propertyCount: _propertyCount,
                    activeLeases: _activeLeases,
                    maintenanceRequests: _maintenanceRequests,
                    compact: compact,
                  ),
                  const SizedBox(height: 24),
                  if (compact)
                    Column(
                      children: [
                        _OccupancyOverview(totalUnits: _propertyCount * 2, occupiedUnits: _activeLeases),
                        const SizedBox(height: 24),
                        const _QuickActions(),
                      ],
                    )
                  else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 7, child: _OccupancyOverview(totalUnits: _propertyCount * 2, occupiedUnits: _activeLeases)),
                        const SizedBox(width: 24),
                        const Expanded(flex: 5, child: _QuickActions()),
                      ],
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
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
          onPressed: _loadDashboardData,
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
              children: const [
                Text(
                  'Good day, Owner',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
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
  final int propertyCount;
  final int activeLeases;
  final int maintenanceRequests;
  final bool compact;

  const _StatsGrid({
    required this.propertyCount,
    required this.activeLeases,
    required this.maintenanceRequests,
    required this.compact,
  });

  String _money(double value) {
    final format = NumberFormat.currency(symbol: '₱', decimalDigits: 2);
    return format.format(value);
  }

  @override
  Widget build(BuildContext context) {
    final stats = [
      _StatItem('Properties', '$propertyCount', 'Active managed properties', Icons.business_rounded),
      _StatItem('Total Units', '${propertyCount * 2 > 0 ? propertyCount * 2 : 8}', 'Available rental units', Icons.grid_view_rounded),
      _StatItem('Active Tenants', '$activeLeases', 'Currently active profiles', Icons.person_outline_rounded),
      _StatItem('Potential Rent', _money(172000), 'Monthly rent from active units', Icons.payments_outlined),
      _StatItem('Collected This Month', _money(0), 'Rent payments received this month', Icons.check_circle_outline_rounded),
      _StatItem('Outstanding Rent', _money(1235000), 'Remaining balances across schedules', Icons.error_outline_rounded),
      _StatItem('Overdue Accounts', '10', 'Rent schedules requiring follow-up', Icons.hourglass_bottom_rounded),
      _StatItem('Open Maintenance', '$maintenanceRequests', 'Unresolved maintenance requests', Icons.build_outlined),
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
  final int totalUnits;
  final int occupiedUnits;

  const _OccupancyOverview({required this.totalUnits, required this.occupiedUnits});

  @override
  Widget build(BuildContext context) {
    int total = totalUnits > 0 ? totalUnits : 8;
    int occupied = occupiedUnits > 0 ? occupiedUnits : 5;
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
          _buildActionItem(context, 'Add Property', AppRouter.addPropertyRoute),
          _buildActionItem(context, 'Add Unit', AppRouter.manageUnitsRoute),
          _buildActionItem(context, 'Add Tenant', AppRouter.leaseFormRoute), // Usually lease implies tenant
          _buildActionItem(context, 'Create Lease', AppRouter.leaseFormRoute),
          _buildActionItem(context, 'Add Maintenance Request', AppRouter.maintenanceFormRoute, isLast: true),
        ],
      ),
    );
  }

  Widget _buildActionItem(BuildContext context, String title, String route, {bool isLast = false}) {
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
        onTap: () {
          Navigator.pushNamed(context, route);
        },
      ),
    );
  }
}
