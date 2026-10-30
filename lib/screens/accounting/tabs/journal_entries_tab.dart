import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_theme.dart';
import '../../../ui/widgets/responsive_helper.dart';
import '../../../services/accounting_service.dart';
import '../../../models/accounting_models.dart';

class JournalEntriesTab extends StatefulWidget {
  const JournalEntriesTab({super.key});

  @override
  State<JournalEntriesTab> createState() => _JournalEntriesTabState();
}

class _JournalEntriesTabState extends State<JournalEntriesTab> {
  final _accounting = AccountingService();
  final _currency = NumberFormat.currency(symbol: 'KSh ', decimalDigits: 2);

  List<JournalEntryModel> _entries = [];
  bool _loading = true;
  String? _error;
  String _selectedStatus = 'ALL';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadJournals();
  }

  Future<void> _loadJournals() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _accounting.getJournalEntries(
        status: _selectedStatus == 'ALL' ? null : _selectedStatus,
        search: _searchQuery.isEmpty ? null : _searchQuery,
      );
      if (mounted) {
        setState(() {
          _entries = res['entries'] as List<JournalEntryModel>;
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

  void _showCreateJournalModal() async {
    final accounts = await _accounting.getAccounts(active: true);
    if (!mounted || accounts.isEmpty) return;

    final descCtrl = TextEditingController();
    final refCtrl = TextEditingController();
    final List<Map<String, dynamic>> lines = [
      {'account_id': accounts.first.id, 'debit': TextEditingController(), 'credit': TextEditingController()},
      {'account_id': accounts.length > 1 ? accounts[1].id : accounts.first.id, 'debit': TextEditingController(), 'credit': TextEditingController()},
    ];

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) {
          double totalDebit = 0;
          double totalCredit = 0;
          for (final l in lines) {
            totalDebit += double.tryParse((l['debit'] as TextEditingController).text.trim()) ?? 0;
            totalCredit += double.tryParse((l['credit'] as TextEditingController).text.trim()) ?? 0;
          }
          final isBalanced = (totalDebit - totalCredit).abs() < 0.01 && totalDebit > 0;

          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text('New Manual Journal Entry', style: GoogleFonts.bricolageGrotesque(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.navy)),
            content: SizedBox(
              width: 600,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(child: TextField(controller: refCtrl, decoration: const InputDecoration(labelText: 'Reference # (Optional)', border: OutlineInputBorder()))),
                        const SizedBox(width: 12),
                        Expanded(child: TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description / Memo', border: OutlineInputBorder()))),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ...lines.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final line = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: DropdownButtonFormField<int>(
                                initialValue: line['account_id'],
                                items: accounts.map((a) => DropdownMenuItem(value: a.id, child: Text('${a.accountCode} ${a.accountName}', overflow: TextOverflow.ellipsis))).toList(),
                                onChanged: (v) => setDlg(() => line['account_id'] = v),
                                decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8), border: OutlineInputBorder()),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 2,
                              child: TextField(
                                controller: line['debit'],
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(labelText: 'Debit', contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8), border: OutlineInputBorder()),
                                onChanged: (_) => setDlg(() {}),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 2,
                              child: TextField(
                                controller: line['credit'],
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(labelText: 'Credit', contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8), border: OutlineInputBorder()),
                                onChanged: (_) => setDlg(() {}),
                              ),
                            ),
                            if (lines.length > 2)
                              IconButton(icon: const Icon(Icons.remove_circle, color: Colors.red), onPressed: () => setDlg(() => lines.removeAt(idx))),
                          ],
                        ),
                      );
                    }),
                    TextButton.icon(
                      onPressed: () => setDlg(() => lines.add({'account_id': accounts.first.id, 'debit': TextEditingController(), 'credit': TextEditingController()})),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add Line'),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: isBalanced ? Colors.green.shade50 : Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Debits: ${_currency.format(totalDebit)}', style: GoogleFonts.dmSans(fontWeight: FontWeight.w600, color: Colors.green.shade800)),
                          Text('Credits: ${_currency.format(totalCredit)}', style: GoogleFonts.dmSans(fontWeight: FontWeight.w600, color: Colors.orange.shade800)),
                          Text(isBalanced ? 'BALANCED' : 'OUT BY ${_currency.format((totalDebit - totalCredit).abs())}', style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, color: isBalanced ? Colors.green : Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                style: AppTheme.actionButtonStyle,
                onPressed: !isBalanced
                    ? null
                    : () async {
                        final nav = Navigator.of(ctx);
                        final messenger = ScaffoldMessenger.of(context);
                        try {
                          final payloadLines = lines.map((l) {
                            return {
                              'account_id': l['account_id'],
                              'debit': double.tryParse((l['debit'] as TextEditingController).text.trim()) ?? 0,
                              'credit': double.tryParse((l['credit'] as TextEditingController).text.trim()) ?? 0,
                            };
                          }).toList();
                          await _accounting.createManualJournalEntry({
                            'reference': refCtrl.text.trim(),
                            'description': descCtrl.text.trim().isEmpty ? 'Manual Journal Entry' : descCtrl.text.trim(),
                            'lines': payloadLines,
                          });
                          if (!mounted) return;
                          nav.pop();
                          _loadJournals();
                        } catch (e) {
                          if (!mounted) return;
                          messenger.showSnackBar(SnackBar(backgroundColor: Colors.red, content: Text('Error: $e')));
                        }
                      },
                child: const Text('Post Journal'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showReversalDialog(JournalEntryModel entry) {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Reverse Journal ${entry.entryNumber}', style: GoogleFonts.bricolageGrotesque(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.navy)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('This will post an exact balanced mirror reversing entry and mark this transaction as REVERSED.', style: GoogleFonts.dmSans(fontSize: 13, color: AppTheme.mutedText)),
            const SizedBox(height: 16),
            TextField(controller: reasonCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Audit Reversal Reason (Required)', border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, foregroundColor: Colors.white),
            onPressed: () async {
              if (reasonCtrl.text.trim().isEmpty) return;
              final nav = Navigator.of(ctx);
              final messenger = ScaffoldMessenger.of(context);
              try {
                await _accounting.reverseJournalEntry(entry.id, reasonCtrl.text.trim());
                if (!mounted) return;
                nav.pop();
                _loadJournals();
              } catch (e) {
                if (!mounted) return;
                messenger.showSnackBar(SnackBar(backgroundColor: Colors.red, content: Text('Error: $e')));
              }
            },
            child: const Text('Confirm Reversal'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);

    return Padding(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Journal Entries (${_entries.length})',
                  style: GoogleFonts.bricolageGrotesque(
                    fontSize: isMobile ? 16 : 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.navy,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _showCreateJournalModal,
                icon: const Icon(Icons.add, size: 16),
                label: Text(isMobile ? 'New' : 'New Manual Journal'),
                style: AppTheme.actionButtonStyle,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (isMobile) ...[
            SizedBox(
              height: 40,
              child: TextField(
                onChanged: (v) {
                  _searchQuery = v;
                  _loadJournals();
                },
                decoration: InputDecoration(
                  hintText: 'Search entry # or description...',
                  prefixIcon: const Icon(Icons.search, size: 18),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['ALL', 'POSTED', 'REVERSED'].map((st) {
                  final isSel = _selectedStatus == st;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(st),
                      selected: isSel,
                      onSelected: (_) {
                        setState(() => _selectedStatus = st);
                        _loadJournals();
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ] else
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: TextField(
                      onChanged: (v) {
                        _searchQuery = v;
                        _loadJournals();
                      },
                      decoration: InputDecoration(
                        hintText: 'Search entry # or description...',
                        prefixIcon: const Icon(Icons.search, size: 18),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ...['ALL', 'POSTED', 'REVERSED'].map((st) {
                  final isSel = _selectedStatus == st;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(st),
                      selected: isSel,
                      onSelected: (_) {
                        setState(() => _selectedStatus = st);
                        _loadJournals();
                      },
                    ),
                  );
                }),
              ],
            ),
          const SizedBox(height: 20),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.teal))
                : _error != null
                    ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
                    : Container(
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.border)),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: ListView.separated(
                            itemCount: _entries.length,
                            separatorBuilder: (_, __) => const Divider(height: 1, color: AppTheme.border),
                            itemBuilder: (ctx, idx) {
                              final item = _entries[idx];
                              final isPosted = item.status == 'POSTED';
                              return ExpansionTile(
                                leading: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isPosted ? AppTheme.teal.withValues(alpha: 0.1) : Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(item.status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isPosted ? AppTheme.teal : Colors.red)),
                                ),
                                title: Text('${item.entryNumber} • ${item.sourceType}', style: GoogleFonts.dmSans(fontWeight: FontWeight.bold, color: AppTheme.navy)),
                                subtitle: Text('${item.postingDate} • ${item.description ?? "No description"}', style: GoogleFonts.dmSans(fontSize: 12, color: AppTheme.mutedText)),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(_currency.format(item.totalDebit), style: GoogleFonts.bricolageGrotesque(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.navy)),
                                    if (isPosted)
                                      IconButton(
                                        icon: const Icon(Icons.undo, size: 18, color: Colors.red),
                                        tooltip: 'Reverse Entry',
                                        onPressed: () => _showReversalDialog(item),
                                      ),
                                  ],
                                ),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                                    child: Table(
                                      columnWidths: const {0: FlexColumnWidth(4), 1: FlexColumnWidth(2), 2: FlexColumnWidth(2)},
                                      children: [
                                        TableRow(children: [
                                          Text('Account', style: GoogleFonts.dmSans(fontWeight: FontWeight.bold, fontSize: 12)),
                                          Text('Debit', style: GoogleFonts.dmSans(fontWeight: FontWeight.bold, fontSize: 12)),
                                          Text('Credit', style: GoogleFonts.dmSans(fontWeight: FontWeight.bold, fontSize: 12)),
                                        ]),
                                        ...item.lines.map((l) => TableRow(children: [
                                              Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Text('${l.accountCode} ${l.accountName}', style: const TextStyle(fontSize: 12))),
                                              Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Text(l.debit > 0 ? _currency.format(l.debit) : '-', style: TextStyle(fontSize: 12, color: l.debit > 0 ? AppTheme.teal : null))),
                                              Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Text(l.credit > 0 ? _currency.format(l.credit) : '-', style: TextStyle(fontSize: 12, color: l.credit > 0 ? Colors.orange.shade800 : null))),
                                            ])),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
