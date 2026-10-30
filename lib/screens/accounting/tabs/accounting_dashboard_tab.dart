import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_theme.dart';
import '../../../ui/widgets/responsive_helper.dart';
import '../../../services/accounting_service.dart';
import '../../../models/accounting_models.dart';

class AccountingDashboardTab extends StatefulWidget {
  final VoidCallback onNavigateToJournals;
  final VoidCallback onNavigateToReports;

  const AccountingDashboardTab({
    super.key,
    required this.onNavigateToJournals,
    required this.onNavigateToReports,
  });

  @override
  State<AccountingDashboardTab> createState() => _AccountingDashboardTabState();
}

class _AccountingDashboardTabState extends State<AccountingDashboardTab> {
  final _accounting = AccountingService();
  final _currencyFmt = NumberFormat.currency(symbol: 'KSh ', decimalDigits: 2);

  AccountingDashboardSummary? _summary;
  bool _loading = true;
  String? _error;
  bool _migrating = false;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final summary = await _accounting.getDashboardSummary();
      if (mounted) {
        setState(() {
          _summary = summary;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _bootstrapHistory() async {
    setState(() => _migrating = true);
    try {
      final res = await _accounting.migrateHistoricalPostings();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.primaryGreen,
            content: Text(
              'Bootstrap Completed: ${res['invoices_posted']} invoices, ${res['payments_posted']} payments, ${res['refunds_posted']} refunds posted.',
            ),
          ),
        );
        _loadSummary();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.red.shade700, content: Text('Bootstrap failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _migrating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.teal));
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
            const SizedBox(height: 12),
            Text('Failed to load accounting data', style: GoogleFonts.bricolageGrotesque(fontSize: 18, color: AppTheme.navy)),
            const SizedBox(height: 6),
            Text(_error!, style: GoogleFonts.dmSans(fontSize: 13, color: AppTheme.mutedText)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadSummary, style: AppTheme.actionButtonStyle, child: const Text('Retry')),
          ],
        ),
      );
    }

    final s = _summary!;
    final noi = s.netOperatingIncome;

    final isMobile = AppBreakpoints.isMobile(context);

    return RefreshIndicator(
      onRefresh: _loadSummary,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Executive Bar
            if (isMobile)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Financial Performance & General Ledger', style: GoogleFonts.bricolageGrotesque(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.navy)),
                  const SizedBox(height: 4),
                  Text('Live double-entry balances reconciling general ledger and subledgers', style: GoogleFonts.dmSans(fontSize: 12, color: AppTheme.mutedText)),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _migrating ? null : _bootstrapHistory,
                      icon: _migrating
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.sync_alt, size: 16),
                      label: Text(_migrating ? 'Posting...' : 'Sync History to Ledger'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.navy,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Financial Performance & General Ledger', style: GoogleFonts.bricolageGrotesque(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.navy)),
                        const SizedBox(height: 4),
                        Text('Live double-entry balances reconciling general ledger and subledgers', style: GoogleFonts.dmSans(fontSize: 13, color: AppTheme.mutedText)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: _migrating ? null : _bootstrapHistory,
                    icon: _migrating
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.sync_alt, size: 16),
                    label: Text(_migrating ? 'Posting...' : 'Sync History to Ledger'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.navy,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 24),

            // KPI Grid
            LayoutBuilder(
              builder: (context, constraints) {
                final double cardWidth = constraints.maxWidth < 600
                    ? constraints.maxWidth
                    : (constraints.maxWidth < 950 ? (constraints.maxWidth - 16) / 2 : (constraints.maxWidth - 32) / 3);
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _kpiCard('Net Operating Income (NOI)', _currencyFmt.format(noi), noi >= 0 ? Colors.green.shade700 : Colors.red.shade700, Icons.trending_up, width: cardWidth),
                    _kpiCard('Rental Revenue Recognized', _currencyFmt.format(s.totalRentalRevenue), AppTheme.teal, Icons.receipt_long_outlined, width: cardWidth),
                    _kpiCard('Total Operating Expenses', _currencyFmt.format(s.totalOperatingExpenses), Colors.orange.shade800, Icons.build_circle_outlined, width: cardWidth),
                    _kpiCard('Tenant Receivables (AR)', _currencyFmt.format(s.tenantArOutstanding), Colors.blueGrey.shade800, Icons.people_outline, width: cardWidth),
                    _kpiCard('Cash & Bank Balances', _currencyFmt.format(s.cashAndBankTotal), AppTheme.primaryGreen, Icons.account_balance_outlined, width: cardWidth),
                    _kpiCard('Owner Funds Payable', _currencyFmt.format(s.ownerFundsPayable), Colors.purple.shade700, Icons.real_estate_agent_outlined, width: cardWidth),
                  ],
                );
              },
            ),
            const SizedBox(height: 32),

            // Quick Navigation & Verification Card
            LayoutBuilder(
              builder: (context, cardConstraints) {
                final isCompactCard = cardConstraints.maxWidth < 720;
                final isSuperCompact = cardConstraints.maxWidth < 400;

                if (isCompactCard) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppTheme.teal.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.verified_outlined, color: AppTheme.teal, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Double-Entry Integrity Active',
                                    style: GoogleFonts.bricolageGrotesque(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.navy,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Total debits strictly equal total credits. ${s.postedJournalsCount.toInt()} posted journal entries.',
                                    style: GoogleFonts.dmSans(fontSize: 12, color: AppTheme.mutedText),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        if (isSuperCompact)
                          Column(
                            children: [
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: widget.onNavigateToJournals,
                                  icon: const Icon(Icons.list_alt, size: 16),
                                  label: const Text('Inspect Journals'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppTheme.navy,
                                    side: const BorderSide(color: AppTheme.border),
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: widget.onNavigateToReports,
                                  icon: const Icon(Icons.analytics_outlined, size: 16),
                                  label: const Text('View Reports'),
                                  style: AppTheme.actionButtonStyle.copyWith(
                                    padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 10)),
                                  ),
                                ),
                              ),
                            ],
                          )
                        else
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: widget.onNavigateToJournals,
                                  icon: const Icon(Icons.list_alt, size: 16),
                                  label: const Text('Inspect Journals'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppTheme.navy,
                                    side: const BorderSide(color: AppTheme.border),
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: widget.onNavigateToReports,
                                  icon: const Icon(Icons.analytics_outlined, size: 16),
                                  label: const Text('View Reports'),
                                  style: AppTheme.actionButtonStyle.copyWith(
                                    padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 10)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  );
                }

                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: AppTheme.teal.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.verified_outlined, color: AppTheme.teal, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Double-Entry Integrity Active', style: GoogleFonts.bricolageGrotesque(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.navy)),
                            const SizedBox(height: 2),
                            Text('Total debits strictly equal total credits. ${s.postedJournalsCount.toInt()} posted journal entries.', style: GoogleFonts.dmSans(fontSize: 12, color: AppTheme.mutedText)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      OutlinedButton.icon(
                        onPressed: widget.onNavigateToJournals,
                        icon: const Icon(Icons.list_alt, size: 16),
                        label: const Text('Inspect Journals'),
                        style: OutlinedButton.styleFrom(foregroundColor: AppTheme.navy, side: const BorderSide(color: AppTheme.border)),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: widget.onNavigateToReports,
                        icon: const Icon(Icons.analytics_outlined, size: 16),
                        label: const Text('View Reports'),
                        style: AppTheme.actionButtonStyle,
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _kpiCard(String title, String value, Color color, IconData icon, {required double width}) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.mutedText)),
              Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Icon(icon, size: 16, color: color)),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: GoogleFonts.bricolageGrotesque(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.navy)),
        ],
      ),
    );
  }
}
