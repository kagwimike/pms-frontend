import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_theme.dart';
import '../../../services/accounting_service.dart';

class FinancialReportsTab extends StatefulWidget {
  const FinancialReportsTab({super.key});

  @override
  State<FinancialReportsTab> createState() => _FinancialReportsTabState();
}

class _FinancialReportsTabState extends State<FinancialReportsTab> {
  final _accounting = AccountingService();
  final _currency = NumberFormat.currency(symbol: 'KSh ', decimalDigits: 2);

  int _selectedReport = 0; // 0: Trial Balance, 1: P&L, 2: Balance Sheet, 3: Cash Flow
  bool _loading = false;
  String? _error;
  Map<String, dynamic>? _reportData;
  String _searchFilter = '';

  @override
  void initState() {
    super.initState();
    _fetchReport();
  }

  Future<void> _fetchReport() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      Map<String, dynamic> data;
      switch (_selectedReport) {
        case 0:
          data = await _accounting.getTrialBalance();
          break;
        case 1:
          data = await _accounting.getProfitAndLoss();
          break;
        case 2:
          data = await _accounting.getBalanceSheet();
          break;
        case 3:
        default:
          data = await _accounting.getCashFlow();
          break;
      }
      if (mounted) setState(() => _reportData = data);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<dynamic> _extractList(dynamic value) {
    if (value == null) return [];
    if (value is List) return value;
    if (value is Map && value['accounts'] is List) return value['accounts'] as List;
    return [];
  }

  double _extractDouble(dynamic value, [double fallback = 0.0]) {
    if (value == null) return fallback;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? fallback;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Report Type Selector Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _reportButton('Trial Balance', 0),
                    const SizedBox(width: 8),
                    _reportButton('Profit & Loss (P&L)', 1),
                    const SizedBox(width: 8),
                    _reportButton('Balance Sheet', 2),
                    const SizedBox(width: 8),
                    _reportButton('Cash Flow', 3),
                  ],
                ),
              ),
              IconButton(
                onPressed: _fetchReport,
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh Report',
                color: AppTheme.navy,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.teal))
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
                            const SizedBox(height: 12),
                            Text('Failed to generate report', style: GoogleFonts.bricolageGrotesque(fontSize: 18, color: AppTheme.navy)),
                            const SizedBox(height: 6),
                            Text(_error!, style: GoogleFonts.dmSans(fontSize: 13, color: AppTheme.mutedText)),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _fetchReport,
                              icon: const Icon(Icons.refresh, size: 16),
                              label: const Text('Try Again'),
                              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.navy, foregroundColor: Colors.white),
                            ),
                          ],
                        ),
                      )
                    : _buildCurrentReport(),
          ),
        ],
      ),
    );
  }

  Widget _reportButton(String label, int index) {
    final isSel = _selectedReport == index;
    return ChoiceChip(
      label: Text(
        label,
        style: GoogleFonts.dmSans(
          fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
          color: isSel ? Colors.white : AppTheme.navy,
        ),
      ),
      selected: isSel,
      selectedColor: AppTheme.navy,
      backgroundColor: Colors.white,
      onSelected: (_) {
        setState(() {
          _selectedReport = index;
          _searchFilter = '';
        });
        _fetchReport();
      },
    );
  }

  Widget _buildCurrentReport() {
    if (_reportData == null) return const SizedBox.shrink();
    switch (_selectedReport) {
      case 0:
        return _buildTrialBalance();
      case 1:
        return _buildProfitLoss();
      case 2:
        return _buildBalanceSheet();
      case 3:
      default:
        return _buildCashFlow();
    }
  }

  // ══════════════════════════════════════════════════════════════════════
  // 1. TRIAL BALANCE
  // ══════════════════════════════════════════════════════════════════════
  Widget _buildTrialBalance() {
    final rawRows = _extractList(_reportData!['accounts'] ?? _reportData!['rows']);
    final totalDebits = _extractDouble(_reportData!['total_debit'] ?? _reportData!['total_debits']);
    final totalCredits = _extractDouble(_reportData!['total_credit'] ?? _reportData!['total_credits']);
    final difference = _extractDouble(_reportData!['difference'], (totalDebits - totalCredits).abs());
    final isBalanced = _reportData!['is_balanced'] == true || difference < 0.01;

    final filtered = rawRows.where((r) {
      if (_searchFilter.isEmpty) return true;
      if (r is! Map) return true;
      final code = (r['account_code']?.toString() ?? '').toLowerCase();
      final name = (r['account_name']?.toString() ?? '').toLowerCase();
      final q = _searchFilter.toLowerCase();
      return code.contains(q) || name.contains(q);
    }).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          // Status & Summary Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: isBalanced ? Colors.green.shade50 : Colors.red.shade50,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              border: Border(bottom: BorderSide(color: isBalanced ? Colors.green.shade200 : Colors.red.shade200)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isBalanced ? Icons.check_circle : Icons.warning_rounded,
                      color: isBalanced ? Colors.green.shade800 : Colors.red.shade800,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isBalanced ? 'Trial Balance: EQUAL & BALANCED' : 'Trial Balance: DISCREPANCY DETECTED',
                      style: GoogleFonts.dmSans(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isBalanced ? Colors.green.shade900 : Colors.red.shade900,
                      ),
                    ),
                    if (!isBalanced) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(4)),
                        child: Text(
                          'Difference: ${_currency.format(difference)}',
                          style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 12, color: Colors.red.shade900),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  'Debits: ${_currency.format(totalDebits)}   |   Credits: ${_currency.format(totalCredits)}',
                  style: GoogleFonts.bricolageGrotesque(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppTheme.navy,
                  ),
                ),
              ],
            ),
          ),

          // Search and filter bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'Search account code or name...',
                      prefixIcon: const Icon(Icons.search, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppTheme.border)),
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    onChanged: (val) => setState(() => _searchFilter = val),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${filtered.length} Accounts',
                  style: GoogleFonts.dmSans(fontSize: 12, color: AppTheme.mutedText, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Table Content
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      rawRows.isEmpty ? 'No accounts or balances recorded yet.' : 'No accounts matching "$_searchFilter"',
                      style: GoogleFonts.dmSans(color: AppTheme.mutedText),
                    ),
                  )
                : SingleChildScrollView(
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(AppTheme.bgGreyGreen),
                      columns: const [
                        DataColumn(label: Text('Code', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Account Name', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Type', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Debit', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                        DataColumn(label: Text('Credit', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                      ],
                      rows: [
                        ...filtered.map<DataRow>((r) {
                          final map = r is Map ? r : {};
                          final d = _extractDouble(map['balance_debit'] ?? map['debit_balance'] ?? map['total_debit']);
                          final c = _extractDouble(map['balance_credit'] ?? map['credit_balance'] ?? map['total_credit']);
                          final code = map['account_code']?.toString() ?? '';
                          final name = map['account_name']?.toString() ?? '';
                          final type = map['account_type']?.toString() ?? map['category']?.toString() ?? '';

                          return DataRow(cells: [
                            DataCell(Text(code, style: const TextStyle(fontWeight: FontWeight.w600))),
                            DataCell(Text(name)),
                            DataCell(Text(type, style: const TextStyle(fontSize: 11, color: AppTheme.mutedText))),
                            DataCell(Text(
                              d > 0 ? _currency.format(d) : '-',
                              style: TextStyle(fontWeight: d > 0 ? FontWeight.w600 : FontWeight.normal, color: d > 0 ? AppTheme.teal : null),
                            )),
                            DataCell(Text(
                              c > 0 ? _currency.format(c) : '-',
                              style: TextStyle(fontWeight: c > 0 ? FontWeight.w600 : FontWeight.normal, color: c > 0 ? Colors.orange.shade800 : null),
                            )),
                          ]);
                        }),
                        // Grand Total Summary Row
                        DataRow(
                          color: WidgetStateProperty.all(AppTheme.bgGreyGreen.withValues(alpha: 0.5)),
                          cells: [
                            const DataCell(Text('TOTAL', style: TextStyle(fontWeight: FontWeight.w800))),
                            const DataCell(Text('Grand Totals', style: TextStyle(fontWeight: FontWeight.w800))),
                            const DataCell(Text('')),
                            DataCell(Text(_currency.format(totalDebits), style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.teal))),
                            DataCell(Text(_currency.format(totalCredits), style: TextStyle(fontWeight: FontWeight.w800, color: Colors.orange.shade800))),
                          ],
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // 2. PROFIT & LOSS (P&L) STATEMENT
  // ══════════════════════════════════════════════════════════════════════
  Widget _buildProfitLoss() {
    List<dynamic> revAccounts = [];
    double totalRev = _extractDouble(_reportData!['total_revenue'] ?? _reportData!['total_rev']);
    final rawRev = _reportData!['revenues'] ?? _reportData!['revenue'];
    if (rawRev is List) {
      revAccounts = rawRev;
      if (totalRev == 0.0) {
        for (final item in rawRev) {
          if (item is Map) totalRev += _extractDouble(item['amount'] ?? item['balance']);
        }
      }
    } else if (rawRev is Map) {
      if (rawRev['accounts'] is List) revAccounts = rawRev['accounts'] as List;
      if (rawRev['total'] != null) totalRev = _extractDouble(rawRev['total'], totalRev);
    }

    List<dynamic> expAccounts = [];
    double totalExp = _extractDouble(_reportData!['total_expense'] ?? _reportData!['total_expenses']);
    final rawExp = _reportData!['expenses'] ?? _reportData!['expense'];
    if (rawExp is List) {
      expAccounts = rawExp;
      if (totalExp == 0.0) {
        for (final item in rawExp) {
          if (item is Map) totalExp += _extractDouble(item['amount'] ?? item['balance']);
        }
      }
    } else if (rawExp is Map) {
      if (rawExp['accounts'] is List) expAccounts = rawExp['accounts'] as List;
      if (rawExp['total'] != null) totalExp = _extractDouble(rawExp['total'], totalExp);
    }

    final netIncome = _extractDouble(
      _reportData!['net_operating_income'] ?? _reportData!['net_income'],
      totalRev - totalExp,
    );

    final profitMargin = totalRev > 0 ? (netIncome / totalRev) * 100 : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // KPI Metric Header Cards
          Row(
            children: [
              Expanded(
                child: _kpiCard(
                  title: 'Operating Revenue',
                  value: _currency.format(totalRev),
                  subtitle: '${revAccounts.length} Income Accounts',
                  icon: Icons.trending_up,
                  color: AppTheme.teal,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _kpiCard(
                  title: 'Operating Expenses',
                  value: _currency.format(totalExp),
                  subtitle: '${expAccounts.length} Expense Categories',
                  icon: Icons.trending_down,
                  color: Colors.orange.shade800,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _kpiCard(
                  title: 'Net Operating Income (NOI)',
                  value: _currency.format(netIncome),
                  subtitle: 'Margin: ${profitMargin.toStringAsFixed(1)}%',
                  icon: Icons.account_balance_wallet,
                  color: netIncome >= 0 ? AppTheme.primaryGreen : Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // ── Operating Revenue Section ──
          Text(
            'Operating Revenues (4000s)',
            style: GoogleFonts.bricolageGrotesque(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.teal),
          ),
          const SizedBox(height: 8),
          if (revAccounts.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('No revenue accounts or transactions recorded for this period.', style: GoogleFonts.dmSans(color: AppTheme.mutedText)),
            )
          else
            ...revAccounts.map((a) {
              final map = a is Map ? a : {};
              final code = map['account_code']?.toString() ?? '';
              final name = map['account_name']?.toString() ?? '';
              final amt = _extractDouble(map['amount'] ?? map['balance']);
              return ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                title: Text('$code  $name', style: GoogleFonts.dmSans(fontWeight: FontWeight.w500)),
                trailing: Text(_currency.format(amt), style: GoogleFonts.dmSans(fontWeight: FontWeight.w600, color: AppTheme.navy)),
              );
            }),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppTheme.border), bottom: BorderSide(color: AppTheme.border)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total Operating Revenue', style: GoogleFonts.dmSans(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(_currency.format(totalRev), style: GoogleFonts.bricolageGrotesque(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.teal)),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // ── Operating Expenses Section ──
          Text(
            'Operating Expenses (5000s)',
            style: GoogleFonts.bricolageGrotesque(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange.shade800),
          ),
          const SizedBox(height: 8),
          if (expAccounts.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('No operating expense accounts recorded for this period.', style: GoogleFonts.dmSans(color: AppTheme.mutedText)),
            )
          else
            ...expAccounts.map((a) {
              final map = a is Map ? a : {};
              final code = map['account_code']?.toString() ?? '';
              final name = map['account_name']?.toString() ?? '';
              final amt = _extractDouble(map['amount'] ?? map['balance']);
              return ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                title: Text('$code  $name', style: GoogleFonts.dmSans(fontWeight: FontWeight.w500)),
                trailing: Text(_currency.format(amt), style: GoogleFonts.dmSans(fontWeight: FontWeight.w600, color: AppTheme.navy)),
              );
            }),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppTheme.border), bottom: BorderSide(color: AppTheme.border)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total Operating Expenses', style: GoogleFonts.dmSans(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(_currency.format(totalExp), style: GoogleFonts.bricolageGrotesque(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.orange.shade800)),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // ── Bottom NOI Card ──
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.bgGreyGreen,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Net Operating Income (NOI)', style: GoogleFonts.bricolageGrotesque(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.navy)),
                    Text('Total Revenues minus Total Operating Expenses', style: GoogleFonts.dmSans(fontSize: 12, color: AppTheme.mutedText)),
                  ],
                ),
                Text(
                  _currency.format(netIncome),
                  style: GoogleFonts.bricolageGrotesque(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: netIncome >= 0 ? AppTheme.primaryGreen : Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // 3. BALANCE SHEET
  // ══════════════════════════════════════════════════════════════════════
  Widget _buildBalanceSheet() {
    // 1. Assets
    List<dynamic> assetAccounts = [];
    double assets = _extractDouble(_reportData!['total_assets']);
    final rawAssets = _reportData!['assets'];
    if (rawAssets is List) {
      assetAccounts = rawAssets;
      if (assets == 0.0) {
        for (final item in rawAssets) {
          if (item is Map) assets += _extractDouble(item['balance'] ?? item['amount']);
        }
      }
    } else if (rawAssets is Map) {
      if (rawAssets['accounts'] is List) assetAccounts = rawAssets['accounts'] as List;
      if (rawAssets['total'] != null) assets = _extractDouble(rawAssets['total'], assets);
    }

    // 2. Liabilities
    List<dynamic> liabilityAccounts = [];
    double liabilities = _extractDouble(_reportData!['total_liabilities']);
    final rawLiab = _reportData!['liabilities'];
    if (rawLiab is List) {
      liabilityAccounts = rawLiab;
      if (liabilities == 0.0) {
        for (final item in rawLiab) {
          if (item is Map) liabilities += _extractDouble(item['balance'] ?? item['amount']);
        }
      }
    } else if (rawLiab is Map) {
      if (rawLiab['accounts'] is List) liabilityAccounts = rawLiab['accounts'] as List;
      if (rawLiab['total'] != null) liabilities = _extractDouble(rawLiab['total'], liabilities);
    }

    // 3. Equity
    List<dynamic> equityAccounts = [];
    double equity = _extractDouble(_reportData!['total_equity']);
    final rawEquity = _reportData!['equity'];
    if (rawEquity is List) {
      equityAccounts = rawEquity;
      if (equity == 0.0) {
        for (final item in rawEquity) {
          if (item is Map) equity += _extractDouble(item['balance'] ?? item['amount']);
        }
      }
    } else if (rawEquity is Map) {
      if (rawEquity['accounts'] is List) equityAccounts = rawEquity['accounts'] as List;
      if (rawEquity['total'] != null) equity = _extractDouble(rawEquity['total'], equity);
    }

    final totalLiabEquity = _extractDouble(
      _reportData!['total_liabilities_and_equity'],
      liabilities + equity,
    );
    final discrepancy = (assets - totalLiabEquity).abs();
    final isBalanced = _reportData!['is_balanced'] == true || discrepancy < 0.01;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Equation Verification Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isBalanced ? Colors.green.shade50 : Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isBalanced ? Colors.green.shade200 : Colors.red.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(isBalanced ? Icons.verified : Icons.warning_amber_rounded, color: isBalanced ? Colors.green.shade800 : Colors.red),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Fundamental Accounting Equation: Assets = Liabilities + Equity',
                          style: GoogleFonts.dmSans(fontWeight: FontWeight.bold, fontSize: 13, color: isBalanced ? Colors.green.shade900 : Colors.red.shade900),
                        ),
                        Text(
                          isBalanced
                              ? 'Statement is completely balanced and verified against posted ledgers.'
                              : 'Discrepancy of ${_currency.format(discrepancy)}. Review unposted entries.',
                          style: GoogleFonts.dmSans(fontSize: 12, color: AppTheme.mutedText),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isBalanced ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isBalanced ? 'BALANCED' : 'DISCREPANCY',
                    style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 11, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Assets Section ──
          _statementSectionHeader('1. ASSETS (1000s)', AppTheme.teal),
          if (assetAccounts.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('No asset accounts with balances recorded.', style: GoogleFonts.dmSans(color: AppTheme.mutedText)),
            )
          else
            ...assetAccounts.map((a) => _statementAccountRow(a)),
          _sectionSubtotalRow('Total Assets', assets, AppTheme.teal),
          const SizedBox(height: 28),

          // ── Liabilities Section ──
          _statementSectionHeader('2. LIABILITIES (2000s)', Colors.orange.shade800),
          if (liabilityAccounts.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('No liability accounts with balances recorded.', style: GoogleFonts.dmSans(color: AppTheme.mutedText)),
            )
          else
            ...liabilityAccounts.map((a) => _statementAccountRow(a)),
          _sectionSubtotalRow('Total Liabilities', liabilities, Colors.orange.shade800),
          const SizedBox(height: 28),

          // ── Equity Section ──
          _statementSectionHeader('3. OWNER EQUITY & RETAINED EARNINGS (3000s)', AppTheme.navy),
          if (equityAccounts.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('No equity accounts recorded.', style: GoogleFonts.dmSans(color: AppTheme.mutedText)),
            )
          else
            ...equityAccounts.map((a) => _statementAccountRow(a)),
          _sectionSubtotalRow('Total Equity', equity, AppTheme.navy),
          const SizedBox(height: 32),

          // ── Total Liabilities & Equity Summary ──
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.bgGreyGreen,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total Liabilities & Equity', style: GoogleFonts.bricolageGrotesque(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.navy)),
                Text(_currency.format(totalLiabEquity), style: GoogleFonts.bricolageGrotesque(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.navy)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // 4. CASH FLOW STATEMENT
  // ══════════════════════════════════════════════════════════════════════
  Widget _buildCashFlow() {
    final netCash = _extractDouble(_reportData!['net_cash_flow'] ?? _reportData!['net_cash']);
    final netOperating = _extractDouble(_reportData!['net_operating_cash_flow'] ?? _reportData!['net_operating']);
    final netFinancing = _extractDouble(_reportData!['net_financing_cash_flow'] ?? _reportData!['net_financing']);
    final operatingInflows = _extractDouble(_reportData!['operating_inflows']);
    final operatingOutflows = _extractDouble(_reportData!['operating_outflows']);

    final operatingActivities = _extractList(_reportData!['operating_activities']);
    final financingActivities = _extractList(_reportData!['financing_activities']);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Cash Flow KPI Cards
          Row(
            children: [
              Expanded(
                child: _kpiCard(
                  title: 'Net Cash Flow',
                  value: _currency.format(netCash),
                  subtitle: 'Overall Change in Bank/Cash',
                  icon: Icons.account_balance,
                  color: netCash >= 0 ? AppTheme.teal : Colors.red,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _kpiCard(
                  title: 'Operating Cash Flow',
                  value: _currency.format(netOperating),
                  subtitle: 'In: ${_currency.format(operatingInflows)} | Out: ${_currency.format(operatingOutflows)}',
                  icon: Icons.sync_alt,
                  color: AppTheme.primaryGreen,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _kpiCard(
                  title: 'Financing & Equity Flow',
                  value: _currency.format(netFinancing),
                  subtitle: '${financingActivities.length} Capital Movements',
                  icon: Icons.payments,
                  color: AppTheme.navy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Operating Activities
          Text(
            'Operating Cash Activities',
            style: GoogleFonts.bricolageGrotesque(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.navy),
          ),
          const SizedBox(height: 12),
          if (operatingActivities.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('No operating cash flow entries recorded.', style: GoogleFonts.dmSans(color: AppTheme.mutedText)),
            )
          else
            ...operatingActivities.map((act) {
              final map = act is Map ? act : {};
              final date = map['date']?.toString() ?? '';
              final ref = map['reference']?.toString() ?? '';
              final desc = map['description']?.toString() ?? 'Operating activity';
              final inflow = _extractDouble(map['inflow']);
              final outflow = _extractDouble(map['outflow']);
              final net = _extractDouble(map['net'], inflow - outflow);

              return ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                title: Text(desc, style: GoogleFonts.dmSans(fontWeight: FontWeight.w500)),
                subtitle: Text('$date   Ref: $ref', style: GoogleFonts.dmSans(fontSize: 11, color: AppTheme.mutedText)),
                trailing: Text(
                  _currency.format(net),
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.bold,
                    color: net >= 0 ? AppTheme.teal : Colors.red,
                  ),
                ),
              );
            }),
          const SizedBox(height: 24),

          // Financing Activities
          if (financingActivities.isNotEmpty) ...[
            Text(
              'Financing & Capital Activities',
              style: GoogleFonts.bricolageGrotesque(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.navy),
            ),
            const SizedBox(height: 12),
            ...financingActivities.map((act) {
              final map = act is Map ? act : {};
              final date = map['date']?.toString() ?? '';
              final desc = map['description']?.toString() ?? 'Financing activity';
              final net = _extractDouble(map['net']);
              return ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                title: Text(desc, style: GoogleFonts.dmSans(fontWeight: FontWeight.w500)),
                subtitle: Text(date, style: GoogleFonts.dmSans(fontSize: 11, color: AppTheme.mutedText)),
                trailing: Text(
                  _currency.format(net),
                  style: GoogleFonts.dmSans(fontWeight: FontWeight.bold, color: net >= 0 ? AppTheme.navy : Colors.red),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // HELPER WIDGETS
  // ══════════════════════════════════════════════════════════════════════
  Widget _kpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
              Icon(icon, size: 18, color: color),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: GoogleFonts.bricolageGrotesque(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.navy)),
          const SizedBox(height: 4),
          Text(subtitle, style: GoogleFonts.dmSans(fontSize: 11, color: AppTheme.mutedText)),
        ],
      ),
    );
  }

  Widget _statementSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        title,
        style: GoogleFonts.bricolageGrotesque(fontSize: 15, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  Widget _statementAccountRow(dynamic a) {
    final map = a is Map ? a : {};
    final code = map['account_code']?.toString() ?? '';
    final name = map['account_name']?.toString() ?? '';
    final bal = _extractDouble(map['balance'] ?? map['amount']);

    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      title: Text('$code  $name', style: GoogleFonts.dmSans(fontWeight: FontWeight.w500)),
      trailing: Text(_currency.format(bal), style: GoogleFonts.dmSans(fontWeight: FontWeight.w600, color: AppTheme.navy)),
    );
  }

  Widget _sectionSubtotalRow(String label, double amount, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppTheme.border), bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.dmSans(fontWeight: FontWeight.bold, fontSize: 13)),
          Text(_currency.format(amount), style: GoogleFonts.bricolageGrotesque(fontWeight: FontWeight.bold, fontSize: 15, color: color)),
        ],
      ),
    );
  }
}
