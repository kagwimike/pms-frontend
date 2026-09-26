
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
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF2A9D8F),
        ),
      );
    }

    if (provider.errorMessage != null &&
        provider.snapshot.spotlight == null) {
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
            24,
            compact ? 18 : 34,
            40,
          ),
          children: [
            const _Greeting(),

            const SizedBox(height: 24),

            _StatsRow(
              snapshot: snapshot,
              compact: compact,
            ),

            const SizedBox(height: 22),

            if (compact)
              Column(
                children: [
                  _PropertyOverview(
                    property: snapshot.spotlight,
                    snapshot: snapshot,
                  ),
                  const SizedBox(height: 18),
                  _RentCollectionPanel(
                    chart: snapshot.chart,
                  ),
                ],
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 5,
                    child: _PropertyOverview(
                      property: snapshot.spotlight,
                      snapshot: snapshot,
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    flex: 7,
                    child: _RentCollectionPanel(
                      chart: snapshot.chart,
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 22),

            if (compact)
              Column(
                children: [
                  _TenantPanel(
                    tenants: snapshot.tenants,
                  ),
                  const SizedBox(height: 18),
                  _RemindersPanel(
                    reminders: snapshot.reminders,
                  ),
                  const SizedBox(height: 18),
                  _CalendarPanel(
                    eventDates: snapshot.eventDates,
                  ),
                ],
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _TenantPanel(
                      tenants: snapshot.tenants,
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: _RemindersPanel(
                      reminders: snapshot.reminders,
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: _CalendarPanel(
                      eventDates: snapshot.eventDates,
                    ),
                  ),
                ],
              ),
          ],
        );
      },
    );
  }
}

/* -------------------------------------------------------------------------- */
/* GREETING                                                                   */
/* -------------------------------------------------------------------------- */

class _Greeting extends StatelessWidget {
  const _Greeting();

  String _greeting() {
    final hour = DateTime.now().hour;

    if (hour < 12) {
      return 'Good morning';
    }

    if (hour < 17) {
      return 'Good afternoon';
    }

    return 'Good evening';
  }

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
          '${_greeting()}, $name',
          style: const TextStyle(
            fontSize: 29,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1C2E27),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Here is an overview of your property portfolio.',
          style: TextStyle(
            color: Color(0xFF77847D),
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

/* -------------------------------------------------------------------------- */
/* SUMMARY CARDS                                                              */
/* -------------------------------------------------------------------------- */

class _StatsRow extends StatelessWidget {
  final DashboardSnapshot snapshot;
  final bool compact;

  const _StatsRow({
    required this.snapshot,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final stats = [
      _DashboardStat(
        title: 'New Tenants',
        value: '${snapshot.newTenants}',
        icon: Icons.person_add_alt_1_rounded,
        iconColor: const Color(0xFF2A9D8F),
      ),
      _DashboardStat(
        title: 'Rent Collected',
        value: _money(snapshot.grossCollected),
        icon: Icons.payments_outlined,
        iconColor: const Color(0xFFE9A23B),
      ),
      _DashboardStat(
        title: 'Total Units',
        value: '${snapshot.activeUnits}',
        icon: Icons.apartment_rounded,
        iconColor: const Color(0xFF5A7DCE),
      ),
      _DashboardStat(
        title: 'Active Leases',
        value: '${snapshot.leasesClosed}',
        icon: Icons.description_outlined,
        iconColor: const Color(0xFF9A6DD7),
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
        childAspectRatio: compact ? 1.55 : 2.05,
      ),
      itemBuilder: (context, index) {
        return _DashboardStatCard(
          stat: stats[index],
        );
      },
    );
  }
}

class _DashboardStat {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;

  const _DashboardStat({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
  });
}

class _DashboardStatCard extends StatelessWidget {
  final _DashboardStat stat;

  const _DashboardStatCard({
    required this.stat,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: stat.iconColor.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              stat.icon,
              size: 19,
              color: stat.iconColor,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            stat.title,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF84918A),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            stat.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 21,
              color: Color(0xFF1C2E27),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/* PROPERTY OVERVIEW                                                          */
/* -------------------------------------------------------------------------- */

class _PropertyOverview extends StatelessWidget {
  final PropertyModel? property;
  final DashboardSnapshot snapshot;

  const _PropertyOverview({
    required this.property,
    required this.snapshot,
  });

  @override
  Widget build(BuildContext context) {
    final totalUnits = snapshot.spotlightUnits;
    final occupiedUnits = snapshot.spotlightOccupied;
    final vacantUnits = math.max(0, totalUnits - occupiedUnits);

    final occupancy = totalUnits > 0
        ? (occupiedUnits / totalUnits * 100).clamp(0, 100)
        : 0.0;

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
                _PropertyImage(
                  property: property,
                ),
                Positioned(
                  left: 15,
                  top: 15,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .94),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$vacantUnits vacant',
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
            padding: const EdgeInsets.fromLTRB(
              18,
              16,
              18,
              19,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  property?.name ?? 'Property overview',
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1C2E27),
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  property == null
                      ? 'No property selected'
                      : '${property!.propertyType.isEmpty ? 'Property' : property!.propertyType} • ${property!.city}',
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
                      value: '$totalUnits',
                    ),
                    _QuickStat(
                      label: 'Occupied',
                      value: '$occupiedUnits',
                    ),
                    _QuickStat(
                      label: 'Vacant',
                      value: '$vacantUnits',
                    ),
                    _QuickStat(
                      label: 'Occupancy',
                      value: '${occupancy.round()}%',
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: LinearProgressIndicator(
                    minHeight: 7,
                    value: occupancy / 100,
                    backgroundColor: const Color(0xFFE5ECE8),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF2A9D8F),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/* PROPERTY IMAGE                                                             */
/* -------------------------------------------------------------------------- */

class _PropertyImage extends StatelessWidget {
  final PropertyModel? property;

  const _PropertyImage({
    required this.property,
  });

  @override
  Widget build(BuildContext context) {
    final path = property?.images.isNotEmpty == true
        ? ApiEndpoints.resolveMediaUrl(property!.images.first)
        : '';

    if (path.isEmpty) {
      return _PropertyImagePlaceholder();
    }

    return Image.network(
      path,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) {
        return _PropertyImagePlaceholder();
      },
    );
  }
}

class _PropertyImagePlaceholder extends StatelessWidget {
  const _PropertyImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFDCEBE2),
      child: const Icon(
        Icons.home_work_outlined,
        size: 54,
        color: Color(0xFF54836D),
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/* RENT COLLECTION                                                            */
/* -------------------------------------------------------------------------- */

class _RentCollectionPanel extends StatelessWidget {
  final List<DashboardChartPoint> chart;

  const _RentCollectionPanel({
    required this.chart,
  });

  @override
  Widget build(BuildContext context) {
    final current = chart.isEmpty
        ? const DashboardChartPoint(
            label: 'Current',
            collected: 0,
            target: 0,
          )
        : chart.last;

    final maxValue = chart.fold<double>(
      1,
      (max, item) => math.max(
        max,
        math.max(
          item.collected,
          item.target,
        ),
      ),
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(
        20,
        20,
        20,
        17,
      ),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rent Collection',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1C2E27),
            ),
          ),

          const SizedBox(height: 4),

          const Text(
            'Collected rent compared with the expected target.',
            style: TextStyle(
              fontSize: 11,
              color: Color(0xFF87948D),
            ),
          ),

          const SizedBox(height: 14),

          const Row(
            children: [
              _Legend(
                color: Color(0xFF2A9D8F),
                label: 'Collected',
              ),
              SizedBox(width: 18),
              _Legend(
                color: Color(0xFFD9E5DE),
                label: 'Target',
              ),
            ],
          ),

          const SizedBox(height: 14),

          SizedBox(
            height: 168,
            child: chart.isEmpty
                ? const Center(
                    child: Text(
                      'No payment history available.',
                      style: TextStyle(
                        color: Color(0xFF87948D),
                        fontSize: 12,
                      ),
                    ),
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: chart.map((item) {
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Expanded(
                                child: Align(
                                  alignment: Alignment.bottomCenter,
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.end,
                                    children: [
                                      _Bar(
                                        height:
                                            item.collected /
                                                maxValue *
                                                115,
                                        color: const Color(0xFF2A9D8F),
                                      ),
                                      const SizedBox(width: 4),
                                      _Bar(
                                        height:
                                            item.target /
                                                maxValue *
                                                115,
                                        color: const Color(0xFFD9E5DE),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 7),
                              Text(
                                item.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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
                _CollectionSummary(
                  label: 'Collected',
                  value: _money(current.collected),
                  valueColor: const Color(0xFF1C5A48),
                ),
                _CollectionSummary(
                  label: 'Target',
                  value: _money(current.target),
                  valueColor: const Color(0xFF1C2E27),
                  alignEnd: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CollectionSummary extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final bool alignEnd;

  const _CollectionSummary({
    required this.label,
    required this.value,
    required this.valueColor,
    this.alignEnd = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF738279),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

/* -------------------------------------------------------------------------- */
/* TENANTS                                                                    */
/* -------------------------------------------------------------------------- */

class _TenantPanel extends StatelessWidget {
  final List<DashboardTenant> tenants;

  const _TenantPanel({
    required this.tenants,
  });

  @override
  Widget build(BuildContext context) {
    final child = tenants.isEmpty
        ? const _EmptyPanelText(
            text: 'No active tenant records available.',
          )
        : Column(
            children: tenants.take(4).map((tenant) {
              final name = tenant.name.trim();
              final initial = name.isEmpty
                  ? '?'
                  : name.substring(0, 1).toUpperCase();

              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFFE3F0E7),
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: Color(0xFF28624D),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                title: Text(
                  tenant.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                subtitle: Text(
                  '${tenant.unit} • ${tenant.property}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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

    return _Panel(
      title: 'Recent tenants',
      action: 'View all',
      onAction: () => context.go('/leases'),
      child: child,
    );
  }
}

/* -------------------------------------------------------------------------- */
/* REMINDERS                                                                  */
/* -------------------------------------------------------------------------- */

class _RemindersPanel extends StatelessWidget {
  final List<DashboardReminder> reminders;

  const _RemindersPanel({
    required this.reminders,
  });

  @override
  Widget build(BuildContext context) {
    if (reminders.isEmpty) {
      return const _Panel(
        title: 'Action items',
        child: _EmptyPanelText(
          text: 'There are no outstanding action items.',
        ),
      );
    }

    return _Panel(
      title: 'Action items',
      child: Column(
        children: reminders.map((reminder) {
          return InkWell(
            onTap: () => context.go(reminder.route),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 9,
              ),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: reminder.color.withValues(
                        alpha: .12,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      reminder.icon,
                      size: 17,
                      color: reminder.color,
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
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
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF87948D),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

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

/* -------------------------------------------------------------------------- */
/* CALENDAR                                                                    */
/* -------------------------------------------------------------------------- */

class _CalendarPanel extends StatefulWidget {
  final Set<DateTime> eventDates;

  const _CalendarPanel({
    required this.eventDates,
  });

  @override
  State<_CalendarPanel> createState() => _CalendarPanelState();
}

class _CalendarPanelState extends State<_CalendarPanel> {
  late DateTime month = DateTime(
    DateTime.now().year,
    DateTime.now().month,
  );

  bool _sameDate(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  bool _hasEvent(DateTime date) {
    return widget.eventDates.any(
      (eventDate) => _sameDate(eventDate, date),
    );
  }

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(
      month.year,
      month.month,
      1,
    );

    final daysInMonth = DateTime(
      month.year,
      month.month + 1,
      0,
    ).day;

    final leadingDays = firstDay.weekday - 1;
    final today = DateTime.now();

    final cells = <Widget>[];

    for (var index = 0;
        index < leadingDays + daysInMonth;
        index++) {
      if (index < leadingDays) {
        cells.add(const SizedBox());
        continue;
      }

      final date = DateTime(
        month.year,
        month.month,
        index - leadingDays + 1,
      );

      final selected = _sameDate(date, today);
      final event = _hasEvent(date);

      cells.add(
        Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFF2A9D8F)
                : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(
                '${date.day}',
                style: TextStyle(
                  fontSize: 11,
                  color: selected
                      ? Colors.white
                      : const Color(0xFF536159),
                  fontWeight: selected
                      ? FontWeight.w800
                      : FontWeight.w500,
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
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                tooltip: 'Previous month',
                onPressed: () {
                  setState(() {
                    month = DateTime(
                      month.year,
                      month.month - 1,
                    );
                  });
                },
                icon: const Icon(
                  Icons.chevron_left_rounded,
                  size: 19,
                ),
              ),

              Text(
                DateFormat('MMMM yyyy').format(month),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF27362F),
                ),
              ),

              IconButton(
                tooltip: 'Next month',
                onPressed: () {
                  setState(() {
                    month = DateTime(
                      month.year,
                      month.month + 1,
                    );
                  });
                },
                icon: const Icon(
                  Icons.chevron_right_rounded,
                  size: 19,
                ),
              ),
            ],
          ),

          GridView.count(
            shrinkWrap: true,
            physics:
                const NeverScrollableScrollPhysics(),
            crossAxisCount: 7,
            children: [
              for (final label in [
                'M',
                'T',
                'W',
                'T',
                'F',
                'S',
                'S',
              ])
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

/* -------------------------------------------------------------------------- */
/* SHARED PANEL                                                               */
/* -------------------------------------------------------------------------- */

class _Panel extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  final Widget child;

  const _Panel({
    required this.title,
    required this.child,
    this.action,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        18,
        17,
        18,
        13,
      ),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
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
                InkWell(
                  onTap: onAction,
                  borderRadius:
                      BorderRadius.circular(6),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    child: Text(
                      action!,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF2A9D8F),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
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

/* -------------------------------------------------------------------------- */
/* QUICK STAT                                                                 */
/* -------------------------------------------------------------------------- */

class _QuickStat extends StatelessWidget {
  final String label;
  final String value;

  const _QuickStat({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
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
          style: const TextStyle(
            fontSize: 10,
            color: Color(0xFF87948D),
          ),
        ),
      ],
    );
  }
}

/* -------------------------------------------------------------------------- */
/* CHART LEGEND                                                               */
/* -------------------------------------------------------------------------- */

class _Legend extends StatelessWidget {
  final Color color;
  final String label;

  const _Legend({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF77847D),
          ),
        ),
      ],
    );
  }
}

/* -------------------------------------------------------------------------- */
/* CHART BAR                                                                  */
/* -------------------------------------------------------------------------- */

class _Bar extends StatelessWidget {
  final double height;
  final Color color;

  const _Bar({
    required this.height,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 9,
      height: math.max(3, height),
      decoration: BoxDecoration(
        color: color,
        borderRadius:
            const BorderRadius.vertical(
          top: Radius.circular(4),
        ),
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/* EMPTY STATE                                                                */
/* -------------------------------------------------------------------------- */

class _EmptyPanelText extends StatelessWidget {
  final String text;

  const _EmptyPanelText({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 20,
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF87948D),
        ),
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/* ERROR STATE                                                                */
/* -------------------------------------------------------------------------- */

class _MessageState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _MessageState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics:
          const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height:
              MediaQuery.sizeOf(context).height * .30,
        ),

        const Icon(
          Icons.cloud_off_outlined,
          size: 42,
          color: Color(0xFF8A9790),
        ),

        const SizedBox(height: 14),

        Center(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 24,
            ),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF68766F),
              ),
            ),
          ),
        ),

        const SizedBox(height: 8),

        Center(
          child: TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Try again'),
          ),
        ),
      ],
    );
  }
}

/* -------------------------------------------------------------------------- */
/* ACCESS DENIED                                                              */
/* -------------------------------------------------------------------------- */

class _AccessDenied extends StatelessWidget {
  const _AccessDenied();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF6F8F7),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lock_outline_rounded,
                size: 42,
                color: Color(0xFF7B8982),
              ),
              SizedBox(height: 14),
              Text(
                'Access restricted',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1C2E27),
                ),
              ),
              SizedBox(height: 6),
              Text(
                'This dashboard is available to property owners and administrators.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF77847D),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/* PANEL DECORATION                                                           */
/* -------------------------------------------------------------------------- */

BoxDecoration _panelDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(
      color: const Color(0xFFE7ECE8),
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(
          alpha: .025,
        ),
        blurRadius: 18,
        offset: const Offset(0, 5),
      ),
    ],
  );
}

/* -------------------------------------------------------------------------- */
/* MONEY FORMAT                                                               */
/* -------------------------------------------------------------------------- */

String _money(double amount) {
  return NumberFormat.currency(
    locale: 'en_KE',
    symbol: 'KES ',
    decimalDigits: 0,
  ).format(amount);
}

