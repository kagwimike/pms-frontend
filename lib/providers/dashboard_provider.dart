import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../models/property_model.dart';

class DashboardChartPoint {
  final String label;
  final double collected;
  final double target;

  const DashboardChartPoint({
    required this.label,
    required this.collected,
    required this.target,
  });
}

class DashboardTenant {
  final String name;
  final String unit;
  final String property;
  final String phone;

  const DashboardTenant({
    required this.name,
    required this.unit,
    required this.property,
    this.phone = '',
  });
}

class DashboardReminder {
  final String title;
  final String subtitle;
  final int count;
  final String route;
  final IconData icon;
  final Color color;

  const DashboardReminder({
    required this.title,
    required this.subtitle,
    required this.count,
    required this.route,
    required this.icon,
    required this.color,
  });
}

class DashboardSnapshot {
  final int newTenants;
  final double grossCollected;
  final int activeUnits;
  final int leasesClosed;
  final PropertyModel? spotlight;
  final int spotlightUnits;
  final int spotlightOccupied;
  final int spotlightInquiries;
  final List<DashboardChartPoint> chart;
  final List<DashboardTenant> tenants;
  final List<DashboardReminder> reminders;
  final Set<DateTime> eventDates;

  const DashboardSnapshot({
    required this.newTenants,
    required this.grossCollected,
    required this.activeUnits,
    required this.leasesClosed,
    required this.spotlight,
    required this.spotlightUnits,
    required this.spotlightOccupied,
    required this.spotlightInquiries,
    required this.chart,
    required this.tenants,
    required this.reminders,
    required this.eventDates,
  });

  factory DashboardSnapshot.empty() => const DashboardSnapshot(
    newTenants: 0,
    grossCollected: 0,
    activeUnits: 0,
    leasesClosed: 0,
    spotlight: null,
    spotlightUnits: 0,
    spotlightOccupied: 0,
    spotlightInquiries: 0,
    chart: [],
    tenants: [],
    reminders: [],
    eventDates: {},
  );
}

class DashboardProvider with ChangeNotifier {
  DashboardSnapshot _snapshot = DashboardSnapshot.empty();
  bool _isLoading = false;
  String? _errorMessage;

  DashboardSnapshot get snapshot => _snapshot;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadDashboard({bool refresh = false}) async {
    if (_isLoading) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final responses = await Future.wait([
        ApiClient.get(ApiEndpoints.properties, queryParameters: {'limit': 100}),
        ApiClient.get(ApiEndpoints.units, queryParameters: {'limit': 100}),
        ApiClient.get(ApiEndpoints.leases, queryParameters: {'limit': 100}),
        ApiClient.get(ApiEndpoints.invoices, queryParameters: {'limit': 100}),
        ApiClient.get(ApiEndpoints.payments, queryParameters: {'limit': 100}),
        ApiClient.get(
          ApiEndpoints.inspections,
          queryParameters: {'limit': 100},
        ),
      ]);

      final properties = _items(responses[0]);
      final units = _items(responses[1]);
      final leases = _items(responses[2]);
      final invoices = _items(responses[3]);
      final payments = _items(responses[4]);
      final inspections = _items(responses[5]);
      _snapshot = _buildSnapshot(
        properties,
        units,
        leases,
        invoices,
        payments,
        inspections,
      );
    } catch (error) {
      _errorMessage = 'Unable to load dashboard data. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  DashboardSnapshot _buildSnapshot(
    List<Map<String, dynamic>> properties,
    List<Map<String, dynamic>> units,
    List<Map<String, dynamic>> leases,
    List<Map<String, dynamic>> invoices,
    List<Map<String, dynamic>> payments,
    List<Map<String, dynamic>> inspections,
  ) {
    final now = DateTime.now();
    final periodStart = DateTime(now.year, now.month);
    final activeUnits = units.where((unit) {
      final status = _value(unit, 'status').toUpperCase();
      return status != 'INACTIVE' && status != 'DELETED';
    }).length;
    final currentPayments = payments.where(
      (payment) =>
          _date(
            payment,
            'paid_at',
          )?.isAfter(periodStart.subtract(const Duration(seconds: 1))) ??
          false,
    );
    final currentLeases = leases.where(
      (lease) =>
          _date(
            lease,
            'created_at',
          )?.isAfter(periodStart.subtract(const Duration(seconds: 1))) ??
          false,
    );
    final currentInvoices = invoices
        .where(
          (invoice) =>
              _date(
                invoice,
                'due_date',
              )?.isAfter(periodStart.subtract(const Duration(seconds: 1))) ??
              false,
        )
        .toList();
    final grossCollected = currentPayments.fold<double>(
      0,
      (sum, payment) => sum + _number(payment, 'amount'),
    );
    final spotlight = properties.isEmpty
        ? null
        : PropertyModel.fromJson(properties.first);
    final spotlightId = spotlight?.id?.toString();
    final spotlightUnits = units
        .where(
          (unit) => _relationId(unit, 'property_id', 'property') == spotlightId,
        )
        .toList();
    final spotlightOccupied = spotlightUnits
        .where((unit) => _value(unit, 'status').toUpperCase() == 'OCCUPIED')
        .length;
    final tenants = <DashboardTenant>[];
    final seenTenants = <String>{};
    for (final lease in leases) {
      final tenant = _map(lease['tenant']);
      final tenantName = tenant == null
          ? _value(lease, 'tenant_name', fallback: 'Tenant')
          : _displayName(tenant);
      final tenantId = _relationId(lease, 'tenant_id', 'tenant') ?? tenantName;
      if (seenTenants.add(tenantId)) {
        final unit = _map(lease['unit']);
        tenants.add(
          DashboardTenant(
            name: tenantName,
            unit: _value(unit, 'unit_number', fallback: 'Unit pending'),
            property: _value(
              lease,
              'property_name',
              fallback: spotlight?.name ?? 'Property',
            ),
            phone: tenant == null ? '' : _value(tenant, 'phone'),
          ),
        );
      }
    }

    final eventDates = <DateTime>{};
    for (final inspection in inspections) {
      final date = _date(inspection, 'date');
      if (date != null) eventDates.add(_day(date));
    }
    for (final lease in leases) {
      final date = _date(lease, 'end_date');
      if (date != null) eventDates.add(_day(date));
    }

    return DashboardSnapshot(
      newTenants: currentLeases
          .map((lease) => _relationId(lease, 'tenant_id', 'tenant'))
          .whereType<String>()
          .toSet()
          .length,
      grossCollected: grossCollected,
      activeUnits: activeUnits,
      leasesClosed: currentLeases
          .where(
            (lease) => {
              'ACTIVE',
              'RENEWED',
            }.contains(_value(lease, 'status').toUpperCase()),
          )
          .length,
      spotlight: spotlight,
      spotlightUnits: spotlightUnits.isEmpty
          ? (spotlight?.totalUnits ?? 0)
          : spotlightUnits.length,
      spotlightOccupied: spotlightOccupied,
      spotlightInquiries: _number(
        spotlight == null ? null : properties.first,
        'inquiries',
      ).round(),
      chart: _chart(payments, currentInvoices, now),
      tenants: tenants,
      reminders: [
        DashboardReminder(
          title: 'Follow-Ups',
          subtitle: 'Overdue invoices need attention',
          count: invoices
              .where(
                (invoice) =>
                    _value(invoice, 'status').toUpperCase() == 'OVERDUE',
              )
              .length,
          route: '/invoices',
          icon: Icons.priority_high_rounded,
          color: const Color(0xFFE76F51),
        ),
        DashboardReminder(
          title: 'Inspections Due',
          subtitle: 'Scheduled property inspections',
          count: inspections
              .where(
                (inspection) =>
                    _date(inspection, 'date')?.isAfter(now) ?? false,
              )
              .length,
          route: '/inspections',
          icon: Icons.fact_check_outlined,
          color: const Color(0xFF2A9D8F),
        ),
        DashboardReminder(
          title: 'Leases Expiring',
          subtitle: 'Renewals to review soon',
          count: leases.where((lease) {
            final date = _date(lease, 'end_date');
            return date != null &&
                date.isAfter(now) &&
                date.isBefore(now.add(const Duration(days: 60)));
          }).length,
          route: '/leases',
          icon: Icons.event_repeat_outlined,
          color: const Color(0xFFE9C46A),
        ),
      ],
      eventDates: eventDates,
    );
  }

  List<DashboardChartPoint> _chart(
    List<Map<String, dynamic>> payments,
    List<Map<String, dynamic>> invoices,
    DateTime now,
  ) {
    return List.generate(6, (index) {
      final month = DateTime(now.year, now.month - 5 + index);
      final collected = payments
          .where((payment) {
            final date = _date(payment, 'paid_at');
            return date?.year == month.year && date?.month == month.month;
          })
          .fold<double>(0, (sum, payment) => sum + _number(payment, 'amount'));
      final target = invoices
          .where((invoice) {
            final date = _date(invoice, 'due_date');
            return date?.year == month.year && date?.month == month.month;
          })
          .fold<double>(0, (sum, invoice) => sum + _number(invoice, 'amount'));
      return DashboardChartPoint(
        label: _monthLabel(month),
        collected: collected,
        target: target,
      );
    });
  }

  List<Map<String, dynamic>> _items(ApiResponse<dynamic> response) {
    if (!response.success) return [];
    final data = response.data;
    if (data is List)
      return data
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    if (data is Map && data['rows'] is List) {
      return (data['rows'] as List)
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
    return [];
  }

  Map<String, dynamic>? _map(dynamic value) =>
      value is Map ? Map<String, dynamic>.from(value) : null;

  String _value(
    Map<String, dynamic>? map,
    String key, {
    String fallback = '',
  }) => map?[key]?.toString() ?? fallback;

  String _displayName(Map<String, dynamic> user) =>
      [
        _value(user, 'first_name'),
        _value(user, 'last_name'),
      ].where((part) => part.isNotEmpty).join(' ').trim().isEmpty
      ? _value(user, 'username', fallback: 'Tenant')
      : [
          _value(user, 'first_name'),
          _value(user, 'last_name'),
        ].where((part) => part.isNotEmpty).join(' ');

  String? _relationId(
    Map<String, dynamic>? map,
    String idKey,
    String relationKey,
  ) {
    final direct = map?[idKey];
    if (direct != null) return direct.toString();
    final relation = _map(map?[relationKey]);
    return relation?['id']?.toString();
  }

  double _number(Map<String, dynamic>? map, String key) =>
      double.tryParse(map?[key]?.toString() ?? '') ?? 0;

  DateTime? _date(Map<String, dynamic> map, String key) =>
      DateTime.tryParse(_value(map, key));

  DateTime _day(DateTime date) => DateTime(date.year, date.month, date.day);

  String _monthLabel(DateTime date) => const [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ][date.month - 1];
}
