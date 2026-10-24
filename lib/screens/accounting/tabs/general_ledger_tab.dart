import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_theme.dart';
import '../../../services/accounting_service.dart';
import '../../../models/accounting_models.dart';

class GeneralLedgerTab extends StatefulWidget {
  const GeneralLedgerTab({super.key});

  @override
  State<GeneralLedgerTab> createState() => _GeneralLedgerTabState();
}

class _GeneralLedgerTabState extends State<GeneralLedgerTab> {
  final _accounting = AccountingService();
  final _currency = NumberFormat.currency(symbol: 'KSh ', decimalDigits: 2);

  List<AccountModel> _accounts = [];
  int? _selectedAccountId;
  bool _loadingAccounts = true;
  bool _loadingLedger = false;
  String? _error;

  Map<String, dynamic>? _ledgerData;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    try {
      final accs = await _accounting.getAccounts(active: true);
      if (mounted) {
        setState(() {
          _accounts = accs;
          _loadingAccounts = false;
          if (accs.isNotEmpty) {
            _selectedAccountId = accs.first.id;
            _loadLedger();
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingAccounts = false);
    }
  }

  Future<void> _loadLedger() async {
    if (_selectedAccountId == null) return;
    setState(() {
      _loadingLedger = true;
      _error = null;
    });
    try {
      final res = await _accounting.getGeneralLedger(accountId: _selectedAccountId);
      if (mounted) {
        setState(() {
          _ledgerData = res;
          _loadingLedger = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loadingLedger = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingAccounts) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.teal));
    }

    final accountMap = _ledgerData?['account'] as Map<String, dynamic>?;
    final openingBalance = double.tryParse(_ledgerData?['opening_balance']?.toString() ?? '0') ?? 0.0;
    final closingBalance = double.tryParse(_ledgerData?['closing_balance']?.toString() ?? '0') ?? 0.0;
    final totalDebits = double.tryParse(_ledgerData?['total_debits']?.toString() ?? '0') ?? 0.0;
    final totalCredits = double.tryParse(_ledgerData?['total_credits']?.toString() ?? '0') ?? 0.0;
    final transactions = (_ledgerData?['transactions'] as List<dynamic>? ?? []);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Bar
          Row(
            children: [
              Expanded(
                flex: 3,
                child: DropdownButtonFormField<int>(
                  initialValue: _selectedAccountId,
                  decoration: InputDecoration(
                    labelText: 'Select General Ledger Account',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: _accounts.map((a) {
                    return DropdownMenuItem<int>(
                      value: a.id,
                      child: Text('${a.accountCode} — ${a.accountName} (${a.accountType})', overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (id) {
                    setState(() => _selectedAccountId = id);
                    _loadLedger();
                  },
                ),
              ),
              const SizedBox(width: 16),
              IconButton(onPressed: _loadLedger, icon: const Icon(Icons.refresh), tooltip: 'Refresh Ledger'),
            ],
          ),
          const SizedBox(height: 20),

          // Ledger Header Summary Cards
          if (accountMap != null)
            Row(
              children: [
                _summaryBox('Opening Balance', _currency.format(openingBalance), AppTheme.navy),
                const SizedBox(width: 12),
                _summaryBox('Period Debits', _currency.format(totalDebits), AppTheme.teal),
                const SizedBox(width: 12),
                _summaryBox('Period Credits', _currency.format(totalCredits), Colors.orange.shade800),
                const SizedBox(width: 12),
                _summaryBox('Closing Balance', _currency.format(closingBalance), closingBalance >= 0 ? AppTheme.primaryGreen : Colors.red.shade700),
              ],
            ),
          const SizedBox(height: 20),

          // Transactions Table
          Expanded(
            child: _loadingLedger
                ? const Center(child: CircularProgressIndicator(color: AppTheme.teal))
                : _error != null
                    ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
                    : transactions.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.receipt_outlined, size: 48, color: Colors.grey.shade400),
                                const SizedBox(height: 12),
                                Text('No posted journal transactions found for this account.', style: GoogleFonts.dmSans(fontSize: 14, color: AppTheme.mutedText)),
                              ],
                            ),
                          )
                        : Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppTheme.border),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: SingleChildScrollView(
                                  child: DataTable(
                                    headingRowColor: WidgetStateProperty.all(AppTheme.bgGreyGreen),
                                    columns: const [
                                      DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('Journal #', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('Source', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('Description', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('Debit', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                                      DataColumn(label: Text('Credit', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                                      DataColumn(label: Text('Running Balance', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                                    ],
                                    rows: transactions.map<DataRow>((tx) {
                                      final d = double.tryParse(tx['debit']?.toString() ?? '0') ?? 0.0;
                                      final c = double.tryParse(tx['credit']?.toString() ?? '0') ?? 0.0;
                                      final bal = double.tryParse(tx['running_balance']?.toString() ?? '0') ?? 0.0;

                                      return DataRow(cells: [
                                        DataCell(Text(tx['posting_date']?.toString() ?? '')),
                                        DataCell(Text(tx['entry_number']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.bold))),
                                        DataCell(Text(tx['source_type']?.toString() ?? '')),
                                        DataCell(Text(tx['description']?.toString() ?? '', overflow: TextOverflow.ellipsis)),
                                        DataCell(Text(d > 0 ? _currency.format(d) : '-', style: TextStyle(color: d > 0 ? AppTheme.teal : null))),
                                        DataCell(Text(c > 0 ? _currency.format(c) : '-', style: TextStyle(color: c > 0 ? Colors.orange.shade800 : null))),
                                        DataCell(Text(_currency.format(bal), style: TextStyle(fontWeight: FontWeight.bold, color: bal >= 0 ? AppTheme.navy : Colors.red))),
                                      ]);
                                    }).toList(),
                                  ),
                                ),
                              ),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _summaryBox(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.border)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.dmSans(fontSize: 11, color: AppTheme.mutedText)),
            const SizedBox(height: 4),
            Text(value, style: GoogleFonts.bricolageGrotesque(fontSize: 16, fontWeight: FontWeight.w700, color: color)),
          ],
        ),
      ),
    );
  }
}
