import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';

class SubscriptionBillingSection extends StatefulWidget {
  final VoidCallback? onSubscriptionChanged;

  const SubscriptionBillingSection({super.key, this.onSubscriptionChanged});

  @override
  State<SubscriptionBillingSection> createState() => _SubscriptionBillingSectionState();
}

class _SubscriptionBillingSectionState extends State<SubscriptionBillingSection> {
  final _api = ApiService();

  bool _isLoading = true;
  String? _errorMessage;
  String? _successMessage;

  Map<String, dynamic> _subData = {};
  List<dynamic> _plans = [];
  List<dynamic> _invoices = [];
  bool _isAnnual = false;

  @override
  void initState() {
    super.initState();
    _loadSubscriptionData();
  }

  Future<void> _loadSubscriptionData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final subRes = await _api.getCurrentSubscription();
      _subData = ApiService.extractMap(subRes);

      final plansRes = await _api.getSubscriptionPlans();
      _plans = ApiService.extractList(plansRes);

      final invRes = await _api.getSubscriptionInvoices();
      _invoices = ApiService.extractList(invRes);

      setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderColor = isDark ? const Color(0xFF27272A) : AppTheme.border;
    final textColor = isDark ? Colors.white : AppTheme.navy;
    final muted = isDark ? AppTheme.darkMutedText : AppTheme.mutedText;

    if (_isLoading) {
      return Container(
        height: 320,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(color: AppTheme.teal),
      );
    }

    final sub = _subData['subscription'] as Map<String, dynamic>? ?? {};
    final usage = _subData['usage'] as Map<String, dynamic>? ?? {};
    final currentPlanCode = sub['plan_code'] ?? 'PRO';
    final status = sub['status'] ?? 'TRIALING';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_successMessage != null)
          _buildBanner(_successMessage!, AppTheme.whatsappGreen, Icons.check_circle_outline),
        if (_errorMessage != null)
          _buildBanner(_errorMessage!, Colors.redAccent, Icons.error_outline),

        // ─── HERO: Current Plan & Quota Usage ───
        _buildActiveSubscriptionHero(cardBg, borderColor, textColor, muted, sub, usage, status, currentPlanCode),
        const SizedBox(height: 32),

        // ─── Billing Cycle Toggle ───
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Available Subscription Plans',
                  style: GoogleFonts.bricolageGrotesque(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Select a plan that matches your property and unit portfolio scale.',
                  style: GoogleFonts.dmSans(fontSize: 13, color: muted),
                ),
              ],
            ),
            _buildBillingCycleToggle(isDark),
          ],
        ),
        const SizedBox(height: 20),

        // ─── 3 Tier Plan Cards ───
        _buildPlanCards(cardBg, borderColor, textColor, muted, currentPlanCode),
        const SizedBox(height: 40),

        // ─── Past Invoices & Receipts ───
        _buildInvoicesSection(cardBg, borderColor, textColor, muted),
      ],
    );
  }

  Widget _buildBanner(String message, Color color, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(message, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13))),
          IconButton(
            icon: Icon(Icons.close, color: color, size: 16),
            onPressed: () => setState(() {
              _successMessage = null;
              _errorMessage = null;
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveSubscriptionHero(
    Color cardBg,
    Color borderColor,
    Color textColor,
    Color muted,
    Map<String, dynamic> sub,
    Map<String, dynamic> usage,
    String status,
    String planCode,
  ) {
    final planName = planCode == 'STARTER'
        ? 'Starter Landlord'
        : planCode == 'PRO'
            ? 'Professional Agency'
            : 'Enterprise Portfolio';

    final daysRemaining = usage['days_remaining'] ?? 14;
    final unitsUsed = usage['units_used'] ?? 0;
    final maxUnits = usage['max_units'] ?? 100;
    final unitsPct = usage['units_percentage'] ?? 0;
    final smsBalance = usage['sms_balance'] ?? 500;

    Color statusColor = AppTheme.whatsappGreen;
    String statusLabel = 'ACTIVE';
    if (status == 'TRIALING') {
      statusColor = AppTheme.teal;
      statusLabel = '14-DAY FREE TRIAL';
    } else if (status == 'GRACE_PERIOD') {
      statusColor = AppTheme.brass;
      statusLabel = 'GRACE PERIOD';
    } else if (status == 'EXPIRED') {
      statusColor = Colors.redAccent;
      statusLabel = 'EXPIRED';
    }

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.teal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.card_membership_rounded, color: AppTheme.teal, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          planName,
                          style: GoogleFonts.bricolageGrotesque(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            statusLabel,
                            style: GoogleFonts.dmSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      status == 'TRIALING'
                          ? '$daysRemaining days remaining in your free trial.'
                          : 'Billed ${sub['billing_cycle'] ?? 'MONTHLY'} • Renews in $daysRemaining days.',
                      style: GoogleFonts.dmSans(fontSize: 13, color: muted),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _openMpesaPaymentModal(planCode, _isAnnual ? 'ANNUAL' : 'MONTHLY'),
                icon: const Icon(Icons.flash_on_rounded, size: 16),
                label: Text(status == 'TRIALING' ? 'Activate via M-Pesa' : 'Renew / Upgrade'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(height: 1),
          const SizedBox(height: 20),

          // ── Quotas Meter ──
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 600;
              final colWidth = isNarrow ? constraints.maxWidth : (constraints.maxWidth - 32) / 3;

              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _buildQuotaCard(
                    width: colWidth,
                    label: 'Rental Units Active',
                    value: '$unitsUsed / $maxUnits Units',
                    percentage: (unitsPct as num).toDouble() / 100.0,
                    icon: Icons.holiday_village_outlined,
                    color: unitsPct > 90 ? Colors.redAccent : AppTheme.teal,
                  ),
                  _buildQuotaCard(
                    width: colWidth,
                    label: 'Caretaker & Staff Seats',
                    value: '${usage['staff_used'] ?? 1} / ${usage['max_staff'] ?? 5} Seats',
                    percentage: ((usage['staff_used'] ?? 1) / (usage['max_staff'] ?? 5)).clamp(0.0, 1.0),
                    icon: Icons.badge_outlined,
                    color: AppTheme.navy,
                  ),
                  _buildQuotaCard(
                    width: colWidth,
                    label: 'SMS Notifications Balance',
                    value: '$smsBalance SMS Credits',
                    percentage: (smsBalance / 1000).clamp(0.0, 1.0),
                    icon: Icons.sms_outlined,
                    color: AppTheme.whatsappGreen,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuotaCard({
    required double width,
    required String label,
    required String value,
    required double percentage,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgGreyGreen.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.mutedText, fontWeight: FontWeight.w600)),
              Icon(icon, size: 16, color: color),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.navy)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage.clamp(0.0, 1.0),
              backgroundColor: Colors.black.withValues(alpha: 0.06),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillingCycleToggle(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF27272A) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () => setState(() => _isAnnual = false),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: !_isAnnual ? (isDark ? const Color(0xFF1E1E1E) : Colors.white) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                boxShadow: !_isAnnual ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)] : [],
              ),
              child: Text(
                'Monthly',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: !_isAnnual ? FontWeight.bold : FontWeight.normal,
                  color: !_isAnnual ? AppTheme.teal : AppTheme.mutedText,
                ),
              ),
            ),
          ),
          InkWell(
            onTap: () => setState(() => _isAnnual = true),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: _isAnnual ? (isDark ? const Color(0xFF1E1E1E) : Colors.white) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                boxShadow: _isAnnual ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)] : [],
              ),
              child: Row(
                children: [
                  Text(
                    'Annual',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: _isAnnual ? FontWeight.bold : FontWeight.normal,
                      color: _isAnnual ? AppTheme.teal : AppTheme.mutedText,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.whatsappGreen,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Save 17%',
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCards(Color cardBg, Color borderColor, Color textColor, Color muted, String currentPlanCode) {
    if (_plans.isEmpty) {
      return const Center(child: Text('No plans loaded'));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 900;
        final cardWidth = isMobile ? constraints.maxWidth : (constraints.maxWidth - 32) / 3;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: _plans.map((p) {
            final planMap = p as Map<String, dynamic>;
            final code = planMap['code'] ?? '';
            final isCurrent = code == currentPlanCode;
            final isPopular = planMap['is_popular'] == true;

            final monthlyPrice = (num.tryParse(planMap['price_monthly_kes']?.toString() ?? '0') ?? 0).toInt();
            final annualPrice = (num.tryParse(planMap['price_annual_kes']?.toString() ?? '0') ?? 0).toInt();

            final displayPrice = _isAnnual ? 'KES ${annualPrice.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}' : 'KES ${monthlyPrice.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
            final displayPeriod = _isAnnual ? '/ year' : '/ month';

            final featuresList = planMap['features'] as List<dynamic>? ?? [];

            return Container(
              width: cardWidth,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: isPopular ? AppTheme.navy : cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isPopular ? AppTheme.teal : borderColor,
                  width: isPopular ? 2 : 1,
                ),
                boxShadow: isPopular
                    ? [
                        BoxShadow(
                          color: AppTheme.teal.withValues(alpha: 0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ]
                    : [],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isPopular)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.teal,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'MOST POPULAR IN KENYA',
                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                      ),
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        planMap['name'] ?? code,
                        style: GoogleFonts.bricolageGrotesque(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isPopular ? Colors.white : textColor,
                        ),
                      ),
                      if (isCurrent)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.teal.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('Current', style: TextStyle(color: AppTheme.teal, fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    planMap['tagline'] ?? '',
                    style: TextStyle(
                      fontSize: 12,
                      color: isPopular ? Colors.white70 : muted,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        displayPrice,
                        style: GoogleFonts.bricolageGrotesque(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: isPopular ? Colors.white : textColor,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        displayPeriod,
                        style: TextStyle(
                          fontSize: 12,
                          color: isPopular ? Colors.white70 : muted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Divider(color: isPopular ? Colors.white12 : borderColor),
                  const SizedBox(height: 14),

                  ...featuresList.map((f) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              size: 16,
                              color: isPopular ? AppTheme.whatsappGreen : AppTheme.teal,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                f.toString(),
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: isPopular ? Colors.white.withValues(alpha: 0.9) : textColor,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),

                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _openMpesaPaymentModal(code, _isAnnual ? 'ANNUAL' : 'MONTHLY'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isPopular ? AppTheme.teal : AppTheme.navy,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      child: Text(
                        isCurrent ? 'Renew via M-Pesa' : 'Upgrade to ${planMap['name'] ?? code}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildInvoicesSection(Color cardBg, Color borderColor, Color textColor, Color muted) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Billing Invoices & M-Pesa Receipts',
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'View past subscription transactions and payment references.',
                    style: GoogleFonts.dmSans(fontSize: 13, color: muted),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                onPressed: _loadSubscriptionData,
                tooltip: 'Refresh Billing Records',
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (_invoices.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 32),
              alignment: Alignment.center,
              child: Text(
                'No past subscription invoices found. Your trial is currently active.',
                style: TextStyle(color: muted, fontSize: 13),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Invoice #', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Plan & Cycle', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Amount (KES)', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('M-Pesa Receipt', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: _invoices.map((inv) {
                  final invMap = inv as Map<String, dynamic>;
                  final isPaid = invMap['status'] == 'PAID';

                  return DataRow(cells: [
                    DataCell(Text(invMap['invoice_number'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600))),
                    DataCell(Text('${invMap['plan_code']} (${invMap['billing_cycle']})')),
                    DataCell(Text('KES ${invMap['amount_kes']}')),
                    DataCell(Text(invMap['transaction_reference'] ?? 'Pending')),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isPaid ? AppTheme.whatsappGreen.withValues(alpha: 0.15) : Colors.orange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          invMap['status'] ?? 'PENDING',
                          style: TextStyle(
                            color: isPaid ? AppTheme.whatsappGreen : Colors.orange,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                    DataCell(Text(invMap['created_at'] != null ? invMap['created_at'].toString().split('T').first : '')),
                  ]);
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  // ─── M-Pesa STK Push Payment Modal ───
  void _openMpesaPaymentModal(String planCode, String cycle) {
    final phoneCtrl = TextEditingController(text: '2547');
    bool isSubmitting = false;
    String? modalError;
    Map<String, dynamic>? initiateResult;

    final planObj = _plans.firstWhere((p) => p['code'] == planCode, orElse: () => null);
    final amount = planObj != null
        ? (cycle == 'ANNUAL' ? planObj['price_annual_kes'] : planObj['price_monthly_kes'])
        : '6,500';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (modalContext, setModalState) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(modalContext).viewInsets.bottom + 24,
              top: 24,
              left: 24,
              right: 24,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppTheme.whatsappGreen.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.phone_android_rounded, color: AppTheme.whatsappGreen, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Lipa na M-Pesa STK Push',
                              style: GoogleFonts.bricolageGrotesque(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.navy),
                            ),
                            Text('$planCode Plan • $cycle Billing', style: const TextStyle(fontSize: 12, color: AppTheme.mutedText)),
                          ],
                        ),
                      ],
                    ),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.bgGreyGreen,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Payable Now:', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.navy)),
                      Text('KES $amount', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.teal)),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                if (modalError != null)
                  Container(
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                    child: Text(modalError!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
                  ),

                if (initiateResult == null) ...[
                  const Text('Enter Safaricom M-Pesa Phone Number:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.navy)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: 'e.g. 0712345678 or 254712345678',
                      prefixIcon: const Icon(Icons.phone_iphone, color: AppTheme.whatsappGreen),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.border)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.teal, width: 2)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              setModalState(() {
                                isSubmitting = true;
                                modalError = null;
                              });

                              try {
                                final res = await _api.initiateMpesaSubscription(
                                  planCode: planCode,
                                  billingCycle: cycle,
                                  phoneNumber: phoneCtrl.text.trim(),
                                );
                                setModalState(() {
                                  isSubmitting = false;
                                  initiateResult = ApiService.extractMap(res);
                                });
                              } catch (e) {
                                setModalState(() {
                                  isSubmitting = false;
                                  modalError = e.toString();
                                });
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.whatsappGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: isSubmitting
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Send M-Pesa Prompt to Phone', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ),
                ] else ...[
                  // ── STK Push Sent Confirmation & Activation ──
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.whatsappGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.phonelink_ring_rounded, size: 40, color: AppTheme.whatsappGreen),
                        const SizedBox(height: 10),
                        Text(
                          initiateResult!['message'] ?? 'Please check your phone and enter your M-Pesa PIN.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.navy),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              setModalState(() => isSubmitting = true);
                              try {
                                final invoiceId = initiateResult!['invoice_id'];
                                await _api.confirmSubscriptionPayment(invoiceId);
                                if (!modalContext.mounted) return;
                                Navigator.pop(modalContext);
                                if (!mounted) return;
                                setState(() {
                                  _successMessage = 'Subscription activated successfully! Your workspace is now live on $planCode.';
                                });
                                _loadSubscriptionData();
                                widget.onSubscriptionChanged?.call();
                              } catch (e) {
                                setModalState(() {
                                  isSubmitting = false;
                                  modalError = e.toString();
                                });
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: isSubmitting
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('I Have Entered My PIN (Complete)', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
