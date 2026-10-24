import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../services/accounting_service.dart';
import '../../../models/accounting_models.dart';

class AccountingPeriodsTab extends StatefulWidget {
  const AccountingPeriodsTab({super.key});

  @override
  State<AccountingPeriodsTab> createState() => _AccountingPeriodsTabState();
}

class _AccountingPeriodsTabState extends State<AccountingPeriodsTab> {
  final _accounting = AccountingService();
  List<AccountingPeriodModel> _periods = [];
  bool _loading = true;
  String? _error;
  int _selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _loadPeriods();
  }

  Future<void> _loadPeriods() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _accounting.getPeriods(fiscalYear: _selectedYear);
      if (mounted) setState(() => _periods = list);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showClosePeriodDialog(AccountingPeriodModel p) {
    final notesCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Close Period: ${p.periodName}', style: GoogleFonts.bricolageGrotesque(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.navy)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('The accounting engine will verify Trial Balance integrity (Debits == Credits) prior to locking transactions in this period.', style: GoogleFonts.dmSans(fontSize: 13, color: AppTheme.mutedText)),
            const SizedBox(height: 16),
            TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Closing Audit Notes (Optional)', border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: AppTheme.actionButtonStyle,
            onPressed: () async {
              final nav = Navigator.of(ctx);
              final messenger = ScaffoldMessenger.of(context);
              try {
                await _accounting.closePeriod(p.id, notes: notesCtrl.text.trim());
                if (!mounted) return;
                nav.pop();
                _loadPeriods();
                messenger.showSnackBar(SnackBar(backgroundColor: AppTheme.primaryGreen, content: Text('${p.periodName} closed successfully.')));
              } catch (e) {
                if (!mounted) return;
                messenger.showSnackBar(SnackBar(backgroundColor: Colors.red, content: Text('Cannot close period: $e')));
              }
            },
            child: const Text('Verify & Close'),
          ),
        ],
      ),
    );
  }

  void _showReopenDialog(AccountingPeriodModel p) {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Reopen Period: ${p.periodName}', style: GoogleFonts.bricolageGrotesque(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.navy)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reopening a closed period permits historical adjustments. You must record an audit reason.', style: GoogleFonts.dmSans(fontSize: 13, color: AppTheme.mutedText)),
            const SizedBox(height: 16),
            TextField(controller: reasonCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Audit Justification Reason (Required)', border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade800, foregroundColor: Colors.white),
            onPressed: () async {
              if (reasonCtrl.text.trim().isEmpty) return;
              final nav = Navigator.of(ctx);
              final messenger = ScaffoldMessenger.of(context);
              try {
                await _accounting.reopenPeriod(p.id, reason: reasonCtrl.text.trim());
                if (!mounted) return;
                nav.pop();
                _loadPeriods();
                messenger.showSnackBar(SnackBar(backgroundColor: AppTheme.primaryGreen, content: Text('${p.periodName} reopened.')));
              } catch (e) {
                if (!mounted) return;
                messenger.showSnackBar(SnackBar(backgroundColor: Colors.red, content: Text('Error: $e')));
              }
            },
            child: const Text('Confirm Reopening'),
          ),
        ],
      ),
    );
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
              Text('Fiscal Accounting Periods', style: GoogleFonts.bricolageGrotesque(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.navy)),
              DropdownButton<int>(
                value: _selectedYear,
                items: [DateTime.now().year - 1, DateTime.now().year, DateTime.now().year + 1].map((y) => DropdownMenuItem(value: y, child: Text('Fiscal Year $y'))).toList(),
                onChanged: (y) {
                  if (y != null) {
                    setState(() => _selectedYear = y);
                    _loadPeriods();
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
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
                            itemCount: _periods.length,
                            separatorBuilder: (_, __) => const Divider(height: 1, color: AppTheme.border),
                            itemBuilder: (ctx, idx) {
                              final p = _periods[idx];
                              final isOpen = p.status == 'OPEN';
                              return ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(color: isOpen ? Colors.green.shade50 : Colors.grey.shade100, borderRadius: BorderRadius.circular(6)),
                                  child: Text(p.status, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: isOpen ? Colors.green.shade800 : Colors.grey.shade700)),
                                ),
                                title: Text(p.periodName, style: GoogleFonts.dmSans(fontWeight: FontWeight.bold, color: AppTheme.navy)),
                                subtitle: Text('${p.startDate} to ${p.endDate}${p.closeNotes != null ? " • Note: ${p.closeNotes}" : ""}', style: GoogleFonts.dmSans(fontSize: 12, color: AppTheme.mutedText)),
                                trailing: isOpen
                                    ? OutlinedButton(
                                        style: OutlinedButton.styleFrom(foregroundColor: AppTheme.navy, side: const BorderSide(color: AppTheme.border)),
                                        onPressed: () => _showClosePeriodDialog(p),
                                        child: const Text('Close Period'),
                                      )
                                    : TextButton(
                                        onPressed: () => _showReopenDialog(p),
                                        child: const Text('Reopen Period', style: TextStyle(color: Colors.orange)),
                                      ),
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
