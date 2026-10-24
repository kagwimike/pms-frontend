import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_theme.dart';
import '../../../services/accounting_service.dart';

class SubledgersTab extends StatefulWidget {
  const SubledgersTab({super.key});

  @override
  State<SubledgersTab> createState() => _SubledgersTabState();
}

class _SubledgersTabState extends State<SubledgersTab> {
  final _accounting = AccountingService();
  final _currency = NumberFormat.currency(symbol: 'KSh ', decimalDigits: 2);

  int _selectedSubledger = 0; // 0: Tenant AR, 1: Owner Payable, 2: AR Aging
  bool _loading = false;
  String? _error;
  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    _fetchSubledger();
  }

  Future<void> _fetchSubledger() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      Map<String, dynamic> res;
      if (_selectedSubledger == 0) {
        res = await _accounting.getTenantSubledger();
      } else if (_selectedSubledger == 1) {
        res = await _accounting.getOwnerSubledger();
      } else {
        res = await _accounting.getARAging();
      }
      if (mounted) setState(() => _data = res);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _subChip('Tenant Subledger (AR)', 0),
                  const SizedBox(width: 8),
                  _subChip('Owner Subledger (Payables)', 1),
                  const SizedBox(width: 8),
                  _subChip('AR Aging Schedule', 2),
                ],
              ),
              IconButton(onPressed: _fetchSubledger, icon: const Icon(Icons.refresh)),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.teal))
                : _error != null
                    ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
                    : _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _subChip(String label, int index) {
    final isSel = _selectedSubledger == index;
    return ChoiceChip(
      label: Text(label, style: GoogleFonts.dmSans(fontWeight: isSel ? FontWeight.w700 : FontWeight.w500, color: isSel ? Colors.white : AppTheme.navy)),
      selected: isSel,
      selectedColor: AppTheme.navy,
      backgroundColor: Colors.white,
      onSelected: (_) {
        setState(() => _selectedSubledger = index);
        _fetchSubledger();
      },
    );
  }

  Widget _buildContent() {
    if (_data == null) return const SizedBox.shrink();
    if (_selectedSubledger == 2) return _buildAgingView();

    final title = _selectedSubledger == 0 ? 'Tenant Control Account (1200 AR)' : 'Owner Control Account (2200 Funds Payable)';
    final controlBalance = double.tryParse(_data!['control_account_balance']?.toString() ?? '0') ?? 0.0;
    final subledgerTotal = double.tryParse(_data!['subledger_total']?.toString() ?? '0') ?? 0.0;
    final isReconciled = _data!['is_reconciled'] == true;
    final records = (_data!['records'] as List<dynamic>? ?? []);

    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.border)),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: isReconciled ? Colors.green.shade50 : Colors.amber.shade50, borderRadius: const BorderRadius.vertical(top: Radius.circular(16))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: GoogleFonts.bricolageGrotesque(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.navy)),
                    const SizedBox(height: 2),
                    Text('General Ledger Control: ${_currency.format(controlBalance)} • Subledger Sum: ${_currency.format(subledgerTotal)}', style: GoogleFonts.dmSans(fontSize: 12, color: AppTheme.mutedText)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: isReconciled ? Colors.green : Colors.amber.shade800, borderRadius: BorderRadius.circular(6)),
                  child: Text(isReconciled ? 'RECONCILED' : 'DISCREPANCY', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                ),
              ],
            ),
          ),
          Expanded(
            child: records.isEmpty
                ? const Center(child: Text('No subledger records found.'))
                : SingleChildScrollView(
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(AppTheme.bgGreyGreen),
                      columns: [
                        DataColumn(label: Text(_selectedSubledger == 0 ? 'Tenant' : 'Owner', style: const TextStyle(fontWeight: FontWeight.bold))),
                        const DataColumn(label: Text('Debits / Charges', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                        const DataColumn(label: Text('Credits / Paid', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                        const DataColumn(label: Text('Net Balance', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                      ],
                      rows: records.map<DataRow>((r) {
                        final d = double.tryParse(r['debits']?.toString() ?? '0') ?? 0.0;
                        final c = double.tryParse(r['credits']?.toString() ?? '0') ?? 0.0;
                        final bal = double.tryParse(r['balance']?.toString() ?? '0') ?? 0.0;

                        return DataRow(cells: [
                          DataCell(Text(r['name']?.toString() ?? 'Unknown')),
                          DataCell(Text(_currency.format(d))),
                          DataCell(Text(_currency.format(c))),
                          DataCell(Text(_currency.format(bal), style: TextStyle(fontWeight: FontWeight.bold, color: bal > 0 ? AppTheme.navy : Colors.grey))),
                        ]);
                      }).toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgingView() {
    final rawBuckets = _data!['aging_buckets'] ?? _data!['buckets'];
    final buckets = rawBuckets is Map ? Map<String, dynamic>.from(rawBuckets) : <String, dynamic>{};
    final total = double.tryParse((_data!['total_outstanding'] ?? _data!['total_ar'])?.toString() ?? '0') ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Accounts Receivable Aging Distribution', style: GoogleFonts.bricolageGrotesque(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.navy)),
          const SizedBox(height: 4),
          Text('Total Overdue & Outstanding Tenant AR: ${_currency.format(total)}', style: GoogleFonts.dmSans(fontSize: 13, color: AppTheme.mutedText)),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.count(
              crossAxisCount: 5,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _agingCard('Current (Not Due)', buckets['current'], Colors.green.shade700),
                _agingCard('1–30 Days Overdue', buckets['1_30_days'] ?? buckets['days_1_30'], Colors.blue.shade700),
                _agingCard('31–60 Days Overdue', buckets['31_60_days'] ?? buckets['days_31_60'], Colors.amber.shade800),
                _agingCard('61–90 Days Overdue', buckets['61_90_days'] ?? buckets['days_61_90'], Colors.orange.shade800),
                _agingCard('90+ Days Overdue', buckets['over_90_days'] ?? buckets['days_90_plus'], Colors.red.shade700),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _agingCard(String label, dynamic val, Color color) {
    final amount = double.tryParse(val?.toString() ?? '0') ?? 0.0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withValues(alpha: 0.3))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 8),
          Text(_currency.format(amount), style: GoogleFonts.bricolageGrotesque(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.navy)),
        ],
      ),
    );
  }
}
