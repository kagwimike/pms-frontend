import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart' as http;
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../config.dart';
import '../widgets/dashboard_sidebar.dart';
import 'maintenance_screen.dart';
import 'notifications_screen.dart';
import 'payments_screen.dart';
import 'inspections_screen.dart';
import 'documents_screen.dart';

class TenantDashboard extends StatefulWidget {
  const TenantDashboard({super.key});

  @override
  State<TenantDashboard> createState() => _TenantDashboardState();
}

class _TenantDashboardState extends State<TenantDashboard> {
  String _selectedNav = 'dashboard';
  final _auth = AuthService();
  final _api = ApiService();

  // Live data
  List<dynamic> _myLeases = [];
  Map<String, dynamic>? _myActiveLease;
  Map<String, dynamic>? _myUnit;
  List<dynamic> _myInvoices = [];
  List<dynamic> _myPayments = [];
  List<dynamic> _myMaintenance = [];
  bool _isLoading = true;

  static const _navItems = [
    SidebarItem(icon: Icons.dashboard_outlined, label: 'Dashboard', key: 'dashboard'),
    SidebarItem(icon: Icons.home_outlined, label: 'My Home', key: 'home'),
    SidebarItem(icon: Icons.description_outlined, label: 'My Lease', key: 'lease'),
    SidebarItem(icon: Icons.receipt_long_outlined, label: 'Rent & Invoices', key: 'invoices'),
    SidebarItem(icon: Icons.account_balance_wallet_outlined, label: 'Payment History', key: 'payments'),
    SidebarItem(icon: Icons.build_outlined, label: 'Maintenance', key: 'maintenance'),
    SidebarItem(icon: Icons.fact_check_outlined, label: 'Inspections', key: 'inspections'),
    SidebarItem(icon: Icons.folder_outlined, label: 'Documents', key: 'documents'),
    SidebarItem(icon: Icons.settings_outlined, label: 'Settings', key: 'settings'),
  ];

  @override
  void initState() {
    super.initState();
    _loadTenantData();
  }

  Future<void> _loadTenantData() async {
    try {
      // Backend already filters by tenant_id for TENANT roles
      final leaseRes = await _api.getLeases(limit: 100);
      final tenantLeases = ApiService.extractList(leaseRes);

      // Find the tenant's active lease for the main dashboard display
      Map<String, dynamic>? activeLease;
      for (final l in tenantLeases) {
        if (l['status'] == 'ACTIVE' || l['status'] == 'PENDING') {
          activeLease = l;
          break;
        }
      }

      // Fetch unit details if active lease has a unit
      Map<String, dynamic>? unitData;
      if (activeLease != null) {
        final unitId = activeLease['unit_id'] ?? activeLease['unit']?['id'];
        if (unitId != null) {
          try {
            final unitRes = await _api.getUnits(limit: 200);
            final allUnits = ApiService.extractList(unitRes);
            unitData = allUnits.firstWhere(
              (u) => u['id']?.toString() == unitId.toString(),
              orElse: () => activeLease!['unit'] ?? {},
            );
          } catch (_) {
            unitData = activeLease['unit'];
          }
        }
      }

      // Fetch invoices
      final invoiceRes = await _api.getInvoices(limit: 100);
      final allInvoices = ApiService.extractList(invoiceRes);

      // Fetch payments
      final paymentRes = await _api.getPayments(limit: 100);
      final allPayments = ApiService.extractList(paymentRes);

      // Fetch maintenance
      final maintRes = await _api.getMaintenanceRequests(limit: 100);
      final allMaint = ApiService.extractList(maintRes);

      if (mounted) {
        setState(() {
          _myLeases = tenantLeases;
          _myActiveLease = activeLease;
          _myUnit = unitData;
          _myInvoices = allInvoices;
          _myPayments = allPayments;
          _myMaintenance = allMaint;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
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
          Text(
            _selectedNav[0].toUpperCase() + _selectedNav.substring(1),
            style: GoogleFonts.bricolageGrotesque(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.navy),
          ),
          const Spacer(),
          Text(dateStr, style: GoogleFonts.dmSans(fontSize: 13, color: AppTheme.mutedText)),
          const SizedBox(width: 16),
          InkWell(
            onTap: () => setState(() => _selectedNav = 'notifications'),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppTheme.bgGreyGreen, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.notifications_outlined, size: 20, color: AppTheme.navy),
            ),
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
        return _buildMyHome();
      case 'lease':
        return _buildMyLease();
      case 'invoices':
        return _buildInvoices();
      case 'payments':
        return const PaymentsScreen(isOwner: false);
      case 'maintenance':
        return const MaintenanceScreen(isOwner: false);
      case 'inspections':
        return const InspectionsScreen(isOwner: false);
      case 'documents':
        return const DocumentsScreen(isOwner: false);
      case 'notifications':
        return NotificationsScreen(isOwner: false);
      case 'settings':
        return _buildPlaceholder('Settings', Icons.settings_outlined, 'Manage your account and preferences');
      default:
        return _buildDashboardHome();
    }
  }

  // ── Dashboard Home ──
  Widget _buildDashboardHome() {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: AppTheme.teal));

    final username = _auth.user?.username ?? 'Tenant';
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good morning' : (hour < 17 ? 'Good afternoon' : 'Good evening');

    final unitNumber = _myUnit?['unit_number'] ?? '—';
    final leaseStatus = _myActiveLease?['status'] ?? 'No Lease';
    final rentAmount = double.tryParse(_myActiveLease?['rent_amount']?.toString() ?? '0') ?? 0;
    final openMaint = _myMaintenance.where((m) => m['status'] == 'PENDING' || m['status'] == 'IN_PROGRESS').length;
    final unpaidInvoices = _myInvoices.where((i) => i['status'] == 'UNPAID' || i['status'] == 'PARTIAL').toList();
    final nextInvoice = unpaidInvoices.isNotEmpty ? unpaidInvoices.first : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$greeting, $username', style: GoogleFonts.bricolageGrotesque(fontSize: 26, fontWeight: FontWeight.w700, color: AppTheme.navy)),
          const SizedBox(height: 4),
          Text('Here is the current status of your rental.', style: GoogleFonts.dmSans(fontSize: 14, color: AppTheme.mutedText)),
          const SizedBox(height: 28),

          // Stat cards
          LayoutBuilder(builder: (ctx, c) {
            final cards = [
              _StatCard(icon: Icons.home_outlined, iconBg: AppTheme.teal.withValues(alpha: 0.1), iconColor: AppTheme.teal, value: unitNumber, label: 'My Unit', sublabel: _myUnit?['property']?['name'] ?? ''),
              _StatCard(icon: Icons.description_outlined, iconBg: AppTheme.navy.withValues(alpha: 0.08), iconColor: AppTheme.navy, value: leaseStatus, label: 'Lease Status', sublabel: _myActiveLease != null ? 'Until ${_myActiveLease!['end_date']}' : 'No active lease'),
              _StatCard(icon: Icons.account_balance_wallet_outlined, iconBg: AppTheme.brass.withValues(alpha: 0.12), iconColor: AppTheme.brass, value: 'KSh ${rentAmount.toStringAsFixed(0)}', label: 'Monthly Rent', sublabel: 'Due on 5th of every month'),
              _StatCard(icon: Icons.build_outlined, iconBg: Colors.orange.withValues(alpha: 0.1), iconColor: Colors.orange.shade700, value: '$openMaint', label: 'Open Maintenance', sublabel: 'Active requests'),
            ];
            if (c.maxWidth < 600) {
              return Wrap(spacing: 16, runSpacing: 16, children: cards.map((card) => SizedBox(width: c.maxWidth, child: card)).toList());
            }
            return Row(children: cards.map((card) => Expanded(child: Padding(padding: const EdgeInsets.only(right: 16), child: card))).toList());
          }).animate().fadeIn(duration: 500.ms).slideY(begin: 0.05),
          const SizedBox(height: 28),

          // Next Payment + Quick Actions
          LayoutBuilder(builder: (ctx, c) {
            if (c.maxWidth < 700) {
              return Column(children: [
                _buildNextPaymentCard(nextInvoice, rentAmount),
                const SizedBox(height: 16),
                _buildQuickActionsCard(),
              ]);
            }
            return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(flex: 3, child: _buildNextPaymentCard(nextInvoice, rentAmount)),
              const SizedBox(width: 16),
              Expanded(flex: 2, child: _buildQuickActionsCard()),
            ]);
          }).animate().fadeIn(duration: 500.ms, delay: 200.ms).slideY(begin: 0.05),
        ],
      ),
    );
  }

  Widget _buildNextPaymentCard(Map<String, dynamic>? invoice, double fallbackRent) {
    final hasInvoice = invoice != null;
    final amount = hasInvoice ? (double.tryParse(invoice['amount']?.toString() ?? '0') ?? 0) : fallbackRent;
    final dueDate = hasInvoice ? invoice['due_date'] ?? 'N/A' : 'N/A';
    final status = hasInvoice ? (invoice['status'] ?? 'UNPAID') : 'NO INVOICE';

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
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Next Payment', style: GoogleFonts.bricolageGrotesque(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.navy)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: status == 'PAID' ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(status, style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w700, color: status == 'PAID' ? Colors.green.shade700 : Colors.red.shade700)),
            ),
          ]),
          const SizedBox(height: 24),
          Row(children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppTheme.bgGreyGreen, borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.receipt_long_outlined, size: 32, color: AppTheme.navy),
            ),
            const SizedBox(width: 20),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(hasInvoice ? 'Invoice #${invoice['id']}' : 'No invoice yet', style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.navy)),
              const SizedBox(height: 4),
              Text('Due: $dueDate', style: GoogleFonts.dmSans(fontSize: 14, color: AppTheme.mutedText)),
            ])),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text('KSh ${amount.toStringAsFixed(0)}', style: GoogleFonts.bricolageGrotesque(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.navy)),
              ),
            ),
          ]),
          if (hasInvoice && status != 'PAID') ...[
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _makePayment(invoice),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.teal, foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('PAY NOW WITH M-PESA', style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _makePayment(Map<String, dynamic> invoice) async {
    final amount = double.tryParse(invoice['amount']?.toString() ?? '0') ?? 0;
    final paid = double.tryParse(invoice['amount_paid']?.toString() ?? '0') ?? 0;
    final remaining = amount - paid;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Confirm Payment', style: GoogleFonts.bricolageGrotesque(fontWeight: FontWeight.w700, color: AppTheme.navy)),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Amount: KSh ${remaining.toStringAsFixed(0)}', style: GoogleFonts.dmSans(fontSize: 16)),
          const SizedBox(height: 8),
          Text('Method: M-PESA', style: GoogleFonts.dmSans(fontSize: 14, color: AppTheme.mutedText)),
          const SizedBox(height: 8),
          Text('This will record a payment against Invoice #${invoice['id']}.', style: GoogleFonts.dmSans(fontSize: 13, color: AppTheme.mutedText)),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.teal, foregroundColor: Colors.white),
            child: const Text('Confirm Payment'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _api.initiateMpesaPayment(
        invoice['id'],
        '254712345678', // Hardcoded or should prompt user
        remaining,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment initiated! Check your phone for STK Push.'), backgroundColor: Colors.green),
        );
        _loadTenantData(); // Refresh
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
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
          Text('Quick Actions', style: GoogleFonts.bricolageGrotesque(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.navy)),
          const SizedBox(height: 4),
          Text('What do you need to do?', style: GoogleFonts.dmSans(fontSize: 12, color: AppTheme.mutedText)),
          const SizedBox(height: 20),
          _actionRow(Icons.build_outlined, 'Report Maintenance', () => setState(() => _selectedNav = 'maintenance')),
          _actionRow(Icons.description_outlined, 'View Lease', () => setState(() => _selectedNav = 'lease')),
          _actionRow(Icons.account_balance_wallet_outlined, 'Payment History', () => setState(() => _selectedNav = 'payments')),
        ],
      ),
    );
  }

  Widget _actionRow(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(children: [
          Icon(icon, size: 20, color: AppTheme.navy),
          const SizedBox(width: 12),
          Text(label, style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.navy)),
          const Spacer(),
          const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.mutedText),
        ]),
      ),
    );
  }

  // ── My Home ──
  Widget _buildMyHome() {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: AppTheme.teal));
    if (_myUnit == null) return _buildPlaceholder('My Home', Icons.home_outlined, 'No unit assigned to your account yet.');

    final property = _myUnit!['property'] ?? {};
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('My Home', style: GoogleFonts.bricolageGrotesque(fontSize: 26, fontWeight: FontWeight.w700, color: AppTheme.navy)),
          const SizedBox(height: 24),
          _infoCard('Property', [
            _infoRow('Name', property['name'] ?? 'Unknown'),
            _infoRow('Address', property['address'] ?? ''),
            _infoRow('City', property['city'] ?? ''),
            _infoRow('Type', property['property_type'] ?? ''),
          ]),
          const SizedBox(height: 16),
          _infoCard('Unit Details', [
            _infoRow('Unit Number', _myUnit!['unit_number'] ?? ''),
            _infoRow('Floor', _myUnit!['floor']?.toString() ?? ''),
            _infoRow('Bedrooms', _myUnit!['bedrooms']?.toString() ?? ''),
            _infoRow('Rent', 'KSh ${_myUnit!['rent_price'] ?? 0}'),
            _infoRow('Status', _myUnit!['status'] ?? ''),
          ]),
        ],
      ),
    );
  }

  // ── My Leases ──
  Widget _buildMyLease() {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: AppTheme.teal));
    if (_myLeases.isEmpty) return _buildPlaceholder('My Leases', Icons.description_outlined, 'No leases found for your account.');

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('My Leases', style: GoogleFonts.bricolageGrotesque(fontSize: 26, fontWeight: FontWeight.w700, color: AppTheme.navy)),
          const SizedBox(height: 4),
          Text('View your current and past lease agreements', style: GoogleFonts.dmSans(fontSize: 14, color: AppTheme.mutedText)),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              itemCount: _myLeases.length,
              itemBuilder: (ctx, i) {
                final lease = _myLeases[i];
                final status = lease['status'] ?? 'UNKNOWN';
                Color statusColor = Colors.grey;
                if (status == 'ACTIVE') statusColor = Colors.green;
                if (status == 'PENDING') statusColor = Colors.orange;
                if (status == 'TERMINATED') statusColor = Colors.red;

                final unit = lease['unit'] ?? {};
                final property = unit['property'] ?? {};
                final unitName = unit['unit_number'] != null ? 'Unit ${unit['unit_number']}' : 'Unknown Unit';
                final propName = property['name'] != null ? ' • ${property['name']}' : '';

                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 16),
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: AppTheme.border.withValues(alpha: 0.5)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text('$unitName$propName', style: GoogleFonts.bricolageGrotesque(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.navy)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                              child: Text(status, style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w700, color: statusColor)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _infoRow('Start Date', lease['start_date'] ?? ''),
                        _infoRow('End Date', lease['end_date'] ?? ''),
                        _infoRow('Monthly Rent', 'KSh ${lease['rent_amount'] ?? 0}'),
                        _infoRow('Security Deposit', 'KSh ${lease['deposit_amount'] ?? 0}'),
                        if (lease['notes'] != null && (lease['notes'] as String).isNotEmpty)
                          _infoRow('Notes', lease['notes']),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Invoices ──
  Widget _buildInvoices() {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: AppTheme.teal));

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Rent & Invoices', style: GoogleFonts.bricolageGrotesque(fontSize: 26, fontWeight: FontWeight.w700, color: AppTheme.navy)),
          const SizedBox(height: 4),
          Text('View and pay your rent invoices', style: GoogleFonts.dmSans(fontSize: 14, color: AppTheme.mutedText)),
          const SizedBox(height: 24),
          Expanded(
            child: _myInvoices.isEmpty
                ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.receipt_long_outlined, size: 64, color: AppTheme.mutedText.withValues(alpha: 0.3)),
                    const SizedBox(height: 16),
                    Text('No invoices yet', style: GoogleFonts.bricolageGrotesque(fontSize: 20, color: AppTheme.navy)),
                  ]))
                : ListView.builder(
                    itemCount: _myInvoices.length,
                    itemBuilder: (ctx, i) {
                      final inv = _myInvoices[i];
                      final status = inv['status'] ?? 'UNKNOWN';
                      Color statusColor = Colors.grey;
                      if (status == 'PAID') statusColor = Colors.green;
                      if (status == 'UNPAID') statusColor = Colors.red;
                      if (status == 'PARTIAL') statusColor = Colors.orange;

                      return Card(
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 12),
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: AppTheme.border.withValues(alpha: 0.5)),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          leading: Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.receipt_long_outlined, color: statusColor),
                          ),
                          title: Text('Invoice #${inv['id']}', style: GoogleFonts.dmSans(fontWeight: FontWeight.w600, color: AppTheme.navy)),
                          subtitle: Text('Due: ${inv['due_date'] ?? 'N/A'}', style: GoogleFonts.dmSans(fontSize: 13, color: AppTheme.mutedText)),
                          trailing: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('KSh ${inv['amount'] ?? 0}', style: GoogleFonts.bricolageGrotesque(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.navy)),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                                child: Text(status, style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w700, color: statusColor)),
                              ),
                            ],
                          ),
                          onTap: status != 'PAID' ? () => _makePayment(inv) : null,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ── Payment History ──
  Widget _buildPaymentHistory() {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: AppTheme.teal));

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Payment History', style: GoogleFonts.bricolageGrotesque(fontSize: 26, fontWeight: FontWeight.w700, color: AppTheme.navy)),
          const SizedBox(height: 4),
          Text('Your past payments and transactions', style: GoogleFonts.dmSans(fontSize: 14, color: AppTheme.mutedText)),
          const SizedBox(height: 24),
          Expanded(
            child: _myPayments.isEmpty
                ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.account_balance_wallet_outlined, size: 64, color: AppTheme.mutedText.withValues(alpha: 0.3)),
                    const SizedBox(height: 16),
                    Text('No payments recorded', style: GoogleFonts.bricolageGrotesque(fontSize: 20, color: AppTheme.navy)),
                  ]))
                : ListView.builder(
                    itemCount: _myPayments.length,
                    itemBuilder: (ctx, i) {
                      final pay = _myPayments[i];
                      final confirmed = pay['is_confirmed'] == true;
                      return Card(
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 12),
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: AppTheme.border.withValues(alpha: 0.5)),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          leading: Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(
                              color: confirmed ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(confirmed ? Icons.check_circle_outline : Icons.schedule, color: confirmed ? Colors.green : Colors.orange),
                          ),
                          title: Text('KSh ${pay['amount'] ?? 0}', style: GoogleFonts.bricolageGrotesque(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.navy)),
                          subtitle: Text('${pay['payment_method'] ?? 'MPESA'} • ${pay['transaction_reference'] ?? 'N/A'}', style: GoogleFonts.dmSans(fontSize: 13, color: AppTheme.mutedText)),
                          trailing: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: confirmed ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(confirmed ? 'CONFIRMED' : 'PENDING', style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w700, color: confirmed ? Colors.green.shade700 : Colors.orange.shade700)),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ── Reusable helpers ──
  Widget _infoCard(String title, List<Widget> rows) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.bricolageGrotesque(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.navy)),
          const SizedBox(height: 16),
          ...rows,
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: GoogleFonts.dmSans(fontSize: 14, color: AppTheme.mutedText, fontWeight: FontWeight.w500)),
          ),
          Expanded(child: Text(value, style: GoogleFonts.dmSans(fontSize: 14, color: AppTheme.navy, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(String title, IconData icon, String description) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(color: AppTheme.brass.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(24)),
            child: Icon(icon, size: 40, color: AppTheme.brass),
          ),
          const SizedBox(height: 24),
          Text(title, style: GoogleFonts.bricolageGrotesque(fontSize: 24, fontWeight: FontWeight.w700, color: AppTheme.navy)),
          const SizedBox(height: 8),
          Text(description, style: GoogleFonts.dmSans(fontSize: 14, color: AppTheme.mutedText), textAlign: TextAlign.center),
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

  const _StatCard({required this.icon, required this.iconBg, required this.iconColor, required this.value, required this.label, required this.sublabel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(label, style: GoogleFonts.dmSans(fontSize: 13, color: AppTheme.mutedText, fontWeight: FontWeight.w500)),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 18, color: iconColor),
            ),
          ]),
          const SizedBox(height: 12),
          Text(value, style: GoogleFonts.bricolageGrotesque(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.navy)),
          const SizedBox(height: 6),
          Text(sublabel, style: GoogleFonts.dmSans(fontSize: 11, color: AppTheme.mutedText.withValues(alpha: 0.7))),
        ],
      ),
    );
  }
}
