import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../services/accounting_service.dart';
import '../../../models/accounting_models.dart';

class ChartOfAccountsTab extends StatefulWidget {
  const ChartOfAccountsTab({super.key});

  @override
  State<ChartOfAccountsTab> createState() => _ChartOfAccountsTabState();
}

class _ChartOfAccountsTabState extends State<ChartOfAccountsTab> {
  final _accounting = AccountingService();
  List<AccountModel> _accounts = [];
  bool _loading = true;
  String? _error;
  String _selectedType = 'ALL';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _accounting.getAccounts(
        type: _selectedType == 'ALL' ? null : _selectedType,
      );
      if (mounted) setState(() => _accounts = list);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showAddAccountDialog() {
    final codeCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String type = 'ASSET';
    String normalBalance = 'DEBIT';
    String category = 'CURRENT_ASSET';
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Add New Account', style: GoogleFonts.bricolageGrotesque(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.navy)),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 440,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: 'Account Code (e.g. 1050)', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Account Name', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: type,
                    decoration: const InputDecoration(labelText: 'Account Type', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'ASSET', child: Text('ASSET')),
                      DropdownMenuItem(value: 'LIABILITY', child: Text('LIABILITY')),
                      DropdownMenuItem(value: 'EQUITY', child: Text('EQUITY')),
                      DropdownMenuItem(value: 'REVENUE', child: Text('REVENUE')),
                      DropdownMenuItem(value: 'EXPENSE', child: Text('EXPENSE')),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        setDlgState(() {
                          type = v;
                          normalBalance = (v == 'ASSET' || v == 'EXPENSE') ? 'DEBIT' : 'CREDIT';
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: normalBalance,
                    decoration: const InputDecoration(labelText: 'Normal Balance', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'DEBIT', child: Text('DEBIT')),
                      DropdownMenuItem(value: 'CREDIT', child: Text('CREDIT')),
                    ],
                    onChanged: (v) => setDlgState(() => normalBalance = v ?? 'DEBIT'),
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: descCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Description (Optional)', border: OutlineInputBorder())),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: saving ? null : () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: AppTheme.actionButtonStyle,
              onPressed: saving
                  ? null
                  : () async {
                      if (codeCtrl.text.trim().isEmpty || nameCtrl.text.trim().isEmpty) return;
                      setDlgState(() => saving = true);
                      final nav = Navigator.of(ctx);
                      final messenger = ScaffoldMessenger.of(context);
                      try {
                        await _accounting.createAccount({
                          'account_code': codeCtrl.text.trim(),
                          'account_name': nameCtrl.text.trim(),
                          'account_type': type,
                          'normal_balance': normalBalance,
                          'category': category,
                          'description': descCtrl.text.trim(),
                        });
                        if (!mounted) return;
                        nav.pop();
                        _loadAccounts();
                      } catch (e) {
                        if (!mounted) return;
                        messenger.showSnackBar(SnackBar(backgroundColor: Colors.red, content: Text('Error: $e')));
                        setDlgState(() => saving = false);
                      }
                    },
              child: saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Create Account'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _accounts.where((a) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return a.accountCode.toLowerCase().contains(q) || a.accountName.toLowerCase().contains(q) || a.category.toLowerCase().contains(q);
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Chart of Accounts (${filtered.length})', style: GoogleFonts.bricolageGrotesque(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.navy)),
              ElevatedButton.icon(
                onPressed: _showAddAccountDialog,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('New Account'),
                style: AppTheme.actionButtonStyle,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Filter Chips & Search
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: TextField(
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'Search code or name...',
                      prefixIcon: const Icon(Icons.search, size: 18),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppTheme.border)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['ALL', 'ASSET', 'LIABILITY', 'EQUITY', 'REVENUE', 'EXPENSE'].map((t) {
                    final isSel = _selectedType == t;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(t, style: GoogleFonts.dmSans(fontSize: 12, fontWeight: isSel ? FontWeight.w700 : FontWeight.w500, color: isSel ? Colors.white : AppTheme.navy)),
                        selected: isSel,
                        selectedColor: AppTheme.navy,
                        backgroundColor: Colors.white,
                        onSelected: (_) {
                          setState(() => _selectedType = t);
                          _loadAccounts();
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.teal))
                : _error != null
                    ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
                    : Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: ListView.separated(
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => const Divider(height: 1, color: AppTheme.border),
                            itemBuilder: (ctx, idx) {
                              final acc = filtered[idx];
                              return ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(color: AppTheme.bgGreyGreen, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppTheme.border)),
                                  child: Text(acc.accountCode, style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.navy)),
                                ),
                                title: Text(acc.accountName, style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.navy)),
                                subtitle: Text('${acc.accountType} • ${acc.category} • Normal: ${acc.normalBalance}', style: GoogleFonts.dmSans(fontSize: 12, color: AppTheme.mutedText)),
                                trailing: acc.isSystem
                                    ? Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(color: AppTheme.teal.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                                        child: Text('SYSTEM', style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.teal)),
                                      )
                                    : null,
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
