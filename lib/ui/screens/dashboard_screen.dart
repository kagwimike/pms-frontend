import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_endpoints.dart';
import '../../models/property_model.dart';
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
      context.read<DashboardProvider>().loadDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (user != null && !{'OWNER', 'ADMIN'}.contains(user.role.toUpperCase())) {
      return const _AccessDenied();
    }
    return Consumer<DashboardProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFF6F8F7),
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
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.errorMessage != null && provider.snapshot.spotlight == null) {
      return _MessageState(
        message: provider.errorMessage!,
        onRetry: () => provider.loadDashboard(refresh: true),
      );
    }
    final snapshot = provider.snapshot;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 850;
        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            compact ? 18 : 34,
            22,
            compact ? 18 : 34,
            34,
          ),
          children: [
            _TopNavbar(compact: compact),
            const SizedBox(height: 28),
            _Greeting(),
            const SizedBox(height: 22),
            _StatsRow(snapshot: snapshot, compact: compact),
            const SizedBox(height: 22),
            if (compact)
              Column(
                children: [
                  _SpotlightCard(
                    property: snapshot.spotlight,
                    snapshot: snapshot,
                  ),
                  const SizedBox(height: 18),
                  _PerformancePanel(chart: snapshot.chart),
                ],
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 5,
                    child: _SpotlightCard(
                      property: snapshot.spotlight,
                      snapshot: snapshot,
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    flex: 7,
                    child: _PerformancePanel(chart: snapshot.chart),
                  ),
                ],
              ),
            const SizedBox(height: 22),
            if (compact)
              Column(
                children: [
                  _TenantPanel(tenants: snapshot.tenants),
                  const SizedBox(height: 18),
                  _RemindersPanel(reminders: snapshot.reminders),
                  const SizedBox(height: 18),
                  _CalendarPanel(eventDates: snapshot.eventDates),
                ],
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _TenantPanel(tenants: snapshot.tenants)),
                  const SizedBox(width: 18),
                  Expanded(
                    child: _RemindersPanel(reminders: snapshot.reminders),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: _CalendarPanel(eventDates: snapshot.eventDates),
                  ),
                ],
              ),
          ],
        );
      },
    );
  }
}

class _TopNavbar extends StatelessWidget {
  final bool compact;

  const _TopNavbar({required this.compact});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final name = user?.firstName.isNotEmpty == true
        ? user!.firstName
        : user?.username ?? 'Owner';
    final initials = name.isEmpty ? 'O' : name.substring(0, 1).toUpperCase();
    final tabs = <String, String>{
      'Dashboard': '/dashboard',
      'Properties': '/properties',
      'Tenants': '/leases',
      'Payments': '/payments',
      'Calendar': '/inspections',
    };
    return Row(
      children: [
        Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFF163B36),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(
                Icons.apartment_rounded,
                color: Color(0xFFB8E1CB),
              ),
            ),
            if (!compact) ...[
              const SizedBox(width: 10),
              const Text(
                'PMS Pro',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF163B36),
                ),
              ),
            ],
          ],
        ),
        if (!compact) ...[
          const SizedBox(width: 42),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: tabs.entries.map((entry) {
                final active = entry.key == 'Dashboard';
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 13),
                  child: InkWell(
                    onTap: () => context.go(entry.value),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        entry.key,
                        style: TextStyle(
                          color: active
                              ? const Color(0xFF163B36)
                              : const Color(0xFF728078),
                          fontWeight: active
                              ? FontWeight.w800
                              : FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ] else
          const Spacer(),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.search_rounded, color: Color(0xFF52615A)),
        ),
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              onPressed: () {},
              icon: const Icon(
                Icons.notifications_none_rounded,
                color: Color(0xFF52615A),
              ),
            ),
            Positioned(
              right: 5,
              top: 5,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFFE76F51),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
        if (!compact) ...[
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFFD7EBDD),
            child: Text(
              initials,
              style: const TextStyle(
                color: Color(0xFF27624D),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF25332D),
                ),
              ),
              const Text(
                'Property Owner',
                style: TextStyle(fontSize: 11, color: Color(0xFF87948D)),
              ),
            ],
          ),
          const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Color(0xFF87948D),
          ),
        ],
      ],
    );
  }
}

class _Greeting extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final name = user?.firstName.isNotEmpty == true
        ? user!.firstName
        : user?.username ?? 'Owner';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Good morning, $name',
          style: const TextStyle(
            fontSize: 29,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1C2E27),
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          'Here is what is happening across your properties today.',
          style: TextStyle(color: Color(0xFF77847D), fontSize: 14),
        ),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  final DashboardSnapshot snapshot;
  final bool compact;

  const _StatsRow({required this.snapshot, required this.compact});

  @override
  Widget build(BuildContext context) {
    final stats = [
      (
        'New Tenants',
        '${snapshot.newTenants}',
        '+12.5%',
        Icons.person_add_alt_1_rounded,
        const Color(0xFF2A9D8F),
      ),
      (
        'Gross Rent Collected',
        _money(snapshot.grossCollected),
        '+8.2%',
        Icons.payments_outlined,
        const Color(0xFFE9A23B),
      ),
      (
        'Properties / Units Listed',
        '${snapshot.activeUnits}',
        '+4.8%',
        Icons.domain_rounded,
        const Color(0xFF5A7DCE),
      ),
      (
        'Leases Closed',
        '${snapshot.leasesClosed}',
        '+6.1%',
        Icons.edit_document,
        const Color(0xFF9A6DD7),
      ),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: stats.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: compact ? 2 : 4,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: compact ? 1.65 : 2.05,
      ),
      itemBuilder: (context, index) {
        final item = stats[index];
        return Container(
          padding: const EdgeInsets.all(17),
          decoration: _panelDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: item.$5.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(item.$4, size: 18, color: item.$5),
                  ),
                  _TrendBadge(text: item.$3),
                ],
              ),
              Text(
                item.$1,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF84918A),
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                item.$2,
                style: const TextStyle(
                  fontSize: 22,
                  color: Color(0xFF1C2E27),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SpotlightCard extends StatelessWidget {
  final PropertyModel? property;
  final DashboardSnapshot snapshot;

  const _SpotlightCard({required this.property, required this.snapshot});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _panelDecoration(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 190,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _PropertyImage(property: property),
                Positioned(
                  left: 15,
                  top: 15,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .92),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${math.max(0, snapshot.spotlightUnits - snapshot.spotlightOccupied)} vacant units',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFB45C38),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  property?.name ?? 'Your property spotlight',
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1C2E27),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  property == null
                      ? 'Property data will appear here'
                      : '${property!.propertyType.isEmpty ? 'Property' : property!.propertyType}  •  ${property!.city}',
                  style: const TextStyle(
                    color: Color(0xFF829088),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _QuickStat(
                      label: 'Total units',
                      value: '${snapshot.spotlightUnits}',
                    ),
                    _QuickStat(
                      label: 'Occupied',
                      value: '${snapshot.spotlightOccupied}',
                    ),
                    _QuickStat(
                      label: 'Views / inquiries',
                      value: '${snapshot.spotlightInquiries}',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PropertyImage extends StatelessWidget {
  final PropertyModel? property;

  const _PropertyImage({required this.property});

  @override
  Widget build(BuildContext context) {
    final path = property?.images.isNotEmpty == true
        ? ApiEndpoints.resolveMediaUrl(property!.images.first)
        : '';
    if (path.isEmpty)
      return Container(
        color: const Color(0xFFDCEBE2),
        child: const Icon(
          Icons.home_work_outlined,
          size: 54,
          color: Color(0xFF54836D),
        ),
      );
    return Image.network(
      path,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: const Color(0xFFDCEBE2),
        child: const Icon(
          Icons.home_work_outlined,
          size: 54,
          color: Color(0xFF54836D),
        ),
      ),
    );
  }
}

class _PerformancePanel extends StatefulWidget {
  final List<DashboardChartPoint> chart;

  const _PerformancePanel({required this.chart});

  @override
  State<_PerformancePanel> createState() => _PerformancePanelState();
}

class _PerformancePanelState extends State<_PerformancePanel> {
  String period = 'Monthly';

  @override
  Widget build(BuildContext context) {
    final current = widget.chart.isEmpty
        ? const DashboardChartPoint(label: 'Current', collected: 0, target: 0)
        : widget.chart.last;
    final maxValue = widget.chart.fold<double>(
      1,
      (max, item) => math.max(max, math.max(item.collected, item.target)),
    );
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 17),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Rent Collection Performance',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1C2E27),
                ),
              ),
              DropdownButton<String>(
                value: period,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: 'Monthly', child: Text('Monthly')),
                  DropdownMenuItem(
                    value: 'Quarterly',
                    child: Text('Quarterly'),
                  ),
                  DropdownMenuItem(value: 'Yearly', child: Text('Yearly')),
                ],
                onChanged: (value) => setState(() => period = value ?? period),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const _Legend(color: Color(0xFF2A9D8F), label: 'Collected'),
              const SizedBox(width: 18),
              const _Legend(color: Color(0xFFD9E5DE), label: 'Target'),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 168,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: widget.chart.isEmpty
                  ? [
                      const Expanded(
                        child: Center(
                          child: Text(
                            'No payment history yet',
                            style: TextStyle(color: Color(0xFF87948D)),
                          ),
                        ),
                      ),
                    ]
                  : widget.chart.map((item) {
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Expanded(
                                child: Align(
                                  alignment: Alignment.bottomCenter,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      _Bar(
                                        height: item.collected / maxValue * 115,
                                        color: const Color(0xFF2A9D8F),
                                      ),
                                      const SizedBox(width: 4),
                                      _Bar(
                                        height: item.target / maxValue * 115,
                                        color: const Color(0xFFD9E5DE),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 7),
                              Text(
                                item.label,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF87948D),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F7F2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current period collected',
                      style: TextStyle(fontSize: 11, color: Color(0xFF738279)),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _money(current.collected),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1C5A48),
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Target',
                      style: TextStyle(fontSize: 11, color: Color(0xFF738279)),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _money(current.target),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1C2E27),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TenantPanel extends StatelessWidget {
  final List<DashboardTenant> tenants;

  const _TenantPanel({required this.tenants});

  @override
  Widget build(BuildContext context) {
    final child = tenants.isEmpty
        ? const _EmptyPanelText(
            text: 'Tenant contacts appear from active lease records.',
          )
        : Column(
            children: tenants.take(4).map((tenant) {
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFFE3F0E7),
                  child: Text(
                    tenant.name.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xFF28624D),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                title: Text(
                  tenant.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                subtitle: Text(
                  '${tenant.unit}  •  ${tenant.property}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF84918A),
                  ),
                ),
                trailing: IconButton(
                  onPressed: tenant.phone.isEmpty ? null : () {},
                  icon: Icon(
                    Icons.call_outlined,
                    color: tenant.phone.isEmpty
                        ? const Color(0xFFCBD4CE)
                        : const Color(0xFF2A9D8F),
                    size: 19,
                  ),
                ),
              );
            }).toList(),
          );

    return _Panel(title: 'Tenant contacts', action: 'View all', child: child);
  }
}

class _RemindersPanel extends StatelessWidget {
  final List<DashboardReminder> reminders;

  const _RemindersPanel({required this.reminders});

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Reminders',
      child: Column(
        children: reminders.map((reminder) {
          return InkWell(
            onTap: () => context.go(reminder.route),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 9),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: reminder.color.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(reminder.icon, size: 17, color: reminder.color),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reminder.title,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF27362F),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          reminder.subtitle,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF87948D),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F4F2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${reminder.count}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 3),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF9AA69F),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _CalendarPanel extends StatefulWidget {
  final Set<DateTime> eventDates;

  const _CalendarPanel({required this.eventDates});

  @override
  State<_CalendarPanel> createState() => _CalendarPanelState();
}

class _CalendarPanelState extends State<_CalendarPanel> {
  late DateTime month = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(month.year, month.month, 1);
    final days = DateTime(month.year, month.month + 1, 0).day;
    final leading = firstDay.weekday - 1;
    final today = DateTime.now();
    final cells = <Widget>[];
    for (var index = 0; index < leading + days; index++) {
      if (index < leading) {
        cells.add(const SizedBox());
        continue;
      }
      final date = DateTime(month.year, month.month, index - leading + 1);
      final selected =
          date.year == today.year &&
          date.month == today.month &&
          date.day == today.day;
      final event = widget.eventDates.contains(date);
      cells.add(
        Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF2A9D8F) : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(
                '${date.day}',
                style: TextStyle(
                  fontSize: 11,
                  color: selected ? Colors.white : const Color(0xFF536159),
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                ),
              ),
              if (event && !selected)
                Positioned(
                  bottom: 3,
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE76F51),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }
    return _Panel(
      title: 'Calendar',
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => setState(
                  () => month = DateTime(month.year, month.month - 1),
                ),
                icon: const Icon(Icons.chevron_left_rounded, size: 19),
              ),
              Text(
                DateFormat('MMMM yyyy').format(month),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF27362F),
                ),
              ),
              IconButton(
                onPressed: () => setState(
                  () => month = DateTime(month.year, month.month + 1),
                ),
                icon: const Icon(Icons.chevron_right_rounded, size: 19),
              ),
            ],
          ),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 7,
            children: [
              for (final label in ['M', 'T', 'W', 'T', 'F', 'S', 'S'])
                Center(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF9BA69F),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ...cells,
            ],
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  final String title;
  final String? action;
  final Widget child;

  const _Panel({required this.title, required this.child, this.action});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 17, 18, 13),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1C2E27),
                ),
              ),
              if (action != null)
                Text(
                  action!,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF2A9D8F),
                    fontWeight: FontWeight.w800,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _QuickStat extends StatelessWidget {
  final String label;
  final String value;

  const _QuickStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        value,
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 17,
          color: Color(0xFF1C2E27),
        ),
      ),
      const SizedBox(height: 2),
      Text(
        label,
        style: const TextStyle(fontSize: 10, color: Color(0xFF87948D)),
      ),
    ],
  );
}

class _TrendBadge extends StatelessWidget {
  final String text;

  const _TrendBadge({required this.text});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
    decoration: BoxDecoration(
      color: const Color(0xFFE4F3E9),
      borderRadius: BorderRadius.circular(7),
    ),
    child: Text(
      text,
      style: const TextStyle(
        color: Color(0xFF31815D),
        fontSize: 10,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;

  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 5),
      Text(
        label,
        style: const TextStyle(fontSize: 11, color: Color(0xFF77847D)),
      ),
    ],
  );
}

class _Bar extends StatelessWidget {
  final double height;
  final Color color;

  const _Bar({required this.height, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    width: 9,
    height: math.max(3, height),
    decoration: BoxDecoration(
      color: color,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
    ),
  );
}

class _EmptyPanelText extends StatelessWidget {
  final String text;

  const _EmptyPanelText({required this.text});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 20),
    child: Text(
      text,
      style: const TextStyle(fontSize: 12, color: Color(0xFF87948D)),
    ),
  );
}

class _MessageState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _MessageState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    children: [
      SizedBox(height: MediaQuery.sizeOf(context).height * .35),
      Center(child: Text(message)),
      Center(
        child: TextButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('Retry'),
        ),
      ),
    ],
  );
}

class _AccessDenied extends StatelessWidget {
  const _AccessDenied();

  @override
  Widget build(BuildContext context) => const Center(
    child: Text(
      'This dashboard is available to property owners and administrators.',
    ),
  );
}

BoxDecoration _panelDecoration() => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(16),
  border: Border.all(color: const Color(0xFFE7ECE8)),
  boxShadow: [
    BoxShadow(
      color: Colors.black.withValues(alpha: .025),
      blurRadius: 18,
      offset: const Offset(0, 5),
    ),
  ],
);

String _money(double amount) => NumberFormat.currency(
  locale: 'en_KE',
  symbol: 'KES ',
  decimalDigits: 0,
).format(amount);
