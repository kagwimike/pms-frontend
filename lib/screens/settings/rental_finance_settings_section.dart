import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';

class RentalFinanceSettingsSection extends StatefulWidget {
  final Map<String, dynamic> rentalConfig;
  final Map<String, dynamic> financeConfig;
  final VoidCallback onSaved;

  const RentalFinanceSettingsSection({
    super.key,
    required this.rentalConfig,
    required this.financeConfig,
    required this.onSaved,
  });

  @override
  State<RentalFinanceSettingsSection> createState() => _RentalFinanceSettingsSectionState();
}

class _RentalFinanceSettingsSectionState extends State<RentalFinanceSettingsSection> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _dueDayController;
  late TextEditingController _gracePeriodController;
  late TextEditingController _lateFeeAmountController;
  late TextEditingController _invoicePrefixController;
  late TextEditingController _receiptPrefixController;
  late TextEditingController _minPartialController;

  String _lateFeeType = 'PERCENTAGE';
  String _defaultPaymentMethod = 'MPESA';
  bool _allowPartialPayments = true;
  bool _requireDepositApproval = true;

  bool _isSaving = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    final r = widget.rentalConfig;
    final f = widget.financeConfig;
    _dueDayController = TextEditingController(text: (r['rent_due_day'] ?? 5).toString());
    _gracePeriodController = TextEditingController(text: (r['grace_period_days'] ?? 5).toString());
    _lateFeeAmountController = TextEditingController(text: (r['late_fee_amount'] ?? 5).toString());
    _lateFeeType = r['late_fee_type'] ?? 'PERCENTAGE';

    _invoicePrefixController = TextEditingController(text: f['invoice_prefix'] ?? 'INV-');
    _receiptPrefixController = TextEditingController(text: f['receipt_prefix'] ?? 'RCT-');
    _minPartialController = TextEditingController(text: (f['min_partial_payment'] ?? 100).toString());
    _defaultPaymentMethod = f['default_payment_method'] ?? 'MPESA';
    _allowPartialPayments = f['allow_partial_payments'] ?? true;
    _requireDepositApproval = f['require_deposit_approval'] ?? true;
  }

  @override
  void dispose() {
    _dueDayController.dispose();
    _gracePeriodController.dispose();
    _lateFeeAmountController.dispose();
    _invoicePrefixController.dispose();
    _receiptPrefixController.dispose();
    _minPartialController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSaving = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      // 1. Update Rental configuration
      await ApiService().updateSettings('RENTAL', {
        'scope': 'GLOBAL',
        'value': {
          'rent_due_day': int.tryParse(_dueDayController.text.trim()) ?? 5,
          'grace_period_days': int.tryParse(_gracePeriodController.text.trim()) ?? 5,
          'late_fee_type': _lateFeeType,
          'late_fee_amount': double.tryParse(_lateFeeAmountController.text.trim()) ?? 5.0,
        },
      });

      // 2. Update Finance configuration
      await ApiService().updateSettings('FINANCE', {
        'scope': 'GLOBAL',
        'value': {
          'invoice_prefix': _invoicePrefixController.text.trim(),
          'receipt_prefix': _receiptPrefixController.text.trim(),
          'default_payment_method': _defaultPaymentMethod,
          'allow_partial_payments': _allowPartialPayments,
          'min_partial_payment': double.tryParse(_minPartialController.text.trim()) ?? 100.0,
          'require_deposit_approval': _requireDepositApproval,
        },
      });

      setState(() {
        _isSaving = false;
        _successMessage = 'Rental & Financial policies updated successfully!';
      });
      widget.onSaved();
    } catch (e) {
      setState(() {
        _isSaving = false;
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

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.brass.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.account_balance_wallet_outlined, color: AppTheme.brass, size: 22),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Rental & Financial Policies',
                        style: GoogleFonts.bricolageGrotesque(fontSize: 18, fontWeight: FontWeight.w700, color: textColor)),
                    Text('Rent due cycles, late fees, invoice prefixes, and deposit approval rules',
                        style: GoogleFonts.dmSans(fontSize: 13, color: isDark ? AppTheme.darkMutedText : AppTheme.mutedText)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 16),

            if (_successMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(_successMessage!, style: const TextStyle(color: Colors.green)),
              ),
            if (_errorMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
              ),

            // Rental Policies
            Text('Rental Rules (For New Invoices & Leases)', style: TextStyle(fontWeight: FontWeight.w700, color: textColor)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _dueDayController,
                    decoration: const InputDecoration(labelText: 'Rent Due Day (1-28)', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _gracePeriodController,
                    decoration: const InputDecoration(labelText: 'Grace Period (Days)', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _lateFeeType,
                    decoration: const InputDecoration(labelText: 'Late Fee Model', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'PERCENTAGE', child: Text('Percentage (%)')),
                      DropdownMenuItem(value: 'FIXED', child: Text('Fixed Amount (KES)')),
                    ],
                    onChanged: (v) => setState(() => _lateFeeType = v!),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _lateFeeAmountController,
                    decoration: const InputDecoration(labelText: 'Late Fee Value', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Finance Policies
            Text('Financial & Document Prefixes', style: TextStyle(fontWeight: FontWeight.w700, color: textColor)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _invoicePrefixController,
                    decoration: const InputDecoration(labelText: 'Invoice Number Prefix', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _receiptPrefixController,
                    decoration: const InputDecoration(labelText: 'Receipt Number Prefix', border: OutlineInputBorder()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _defaultPaymentMethod,
                    decoration: const InputDecoration(labelText: 'Default Payment Method', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'MPESA', child: Text('M-Pesa (Daraja)')),
                      DropdownMenuItem(value: 'BANK', child: Text('Bank Transfer / EFT')),
                      DropdownMenuItem(value: 'CASH', child: Text('Manual Cash Voucher')),
                    ],
                    onChanged: (v) => setState(() => _defaultPaymentMethod = v!),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _minPartialController,
                    decoration: const InputDecoration(labelText: 'Minimum Partial Payment', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Allow Partial Rent Payments'),
              subtitle: const Text('Permits tenants to make installment payments towards open invoices'),
              value: _allowPartialPayments,
              activeColor: AppTheme.teal,
              onChanged: (v) => setState(() => _allowPartialPayments = v),
            ),
            SwitchListTile(
              title: const Text('Require Deposit Refund Approval'),
              subtitle: const Text('Move-out deposit refunds require landlord/admin sign-off before payout'),
              value: _requireDepositApproval,
              activeColor: AppTheme.teal,
              onChanged: (v) => setState(() => _requireDepositApproval = v),
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: _isSaving
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.check, size: 18),
                label: Text(_isSaving ? 'Saving...' : 'Save Policies'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
