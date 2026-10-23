import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

class TenantPaymentDialog extends StatefulWidget {
  final Map<String, dynamic> invoice;
  final VoidCallback onPaymentCompleted;

  const TenantPaymentDialog({
    super.key,
    required this.invoice,
    required this.onPaymentCompleted,
  });

  static Future<void> show(
    BuildContext context, {
    required Map<String, dynamic> invoice,
    required VoidCallback onPaymentCompleted,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => TenantPaymentDialog(
        invoice: invoice,
        onPaymentCompleted: onPaymentCompleted,
      ),
    );
  }

  @override
  State<TenantPaymentDialog> createState() => _TenantPaymentDialogState();
}

class _TenantPaymentDialogState extends State<TenantPaymentDialog> {
  final _api = ApiService();

  // Mode: 'MPESA' or 'BANK'
  String _paymentChannel = 'MPESA';

  // M-Pesa State
  final _phoneController = TextEditingController(text: '07');
  bool _isSubmittingMpesa = false;

  // Bank State
  List<dynamic> _bankAccounts = [];
  Map<String, dynamic>? _selectedBank;
  bool _isLoadingGateways = true;
  bool _showSubmitProofForm = false;
  final _bankRefController = TextEditingController();
  final _bankNotesController = TextEditingController();
  bool _isSubmittingBankProof = false;

  double get _outstandingBalance {
    final total = double.tryParse(widget.invoice['amount']?.toString() ?? '0') ?? 0.0;
    final paid = double.tryParse(widget.invoice['amount_paid']?.toString() ?? '0') ?? 0.0;
    final bal = total - paid;
    return bal > 0 ? bal : total;
  }

  @override
  void initState() {
    super.initState();
    _fetchGateways();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _bankRefController.dispose();
    _bankNotesController.dispose();
    super.dispose();
  }

  Future<void> _fetchGateways() async {
    try {
      final res = await _api.getPaymentGateways(invoiceId: widget.invoice['id']);
      if (res['data'] != null && mounted) {
        final bankData = res['data']['bank'];
        final accounts = bankData != null && bankData['accounts'] != null
            ? List<dynamic>.from(bankData['accounts'])
            : [];

        setState(() {
          _bankAccounts = accounts;
          if (_bankAccounts.isNotEmpty) {
            _selectedBank = _bankAccounts.first;
          }
          _isLoadingGateways = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingGateways = false);
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard: $text'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Future<void> _handleMpesaPay() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty || phone.length < 9) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid M-Pesa phone number')),
      );
      return;
    }

    setState(() => _isSubmittingMpesa = true);

    try {
      await _api.initiateMpesaPayment(
        widget.invoice['id'],
        phone,
        _outstandingBalance,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('M-Pesa STK push prompt sent to your phone. Enter PIN to complete.'),
            backgroundColor: Color(0xFF0F6B4F),
            duration: Duration(seconds: 5),
          ),
        );
        widget.onPaymentCompleted();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('M-Pesa initiation failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmittingMpesa = false);
    }
  }

  Future<void> _handleBankProofSubmit() async {
    final ref = _bankRefController.text.trim();
    if (ref.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the bank transaction reference / code')),
      );
      return;
    }

    setState(() => _isSubmittingBankProof = true);

    try {
      await _api.submitBankPaymentProof(
        invoiceId: widget.invoice['id'],
        amount: _outstandingBalance,
        reference: ref,
        bankAccountId: _selectedBank?['id'],
        notes: _bankNotesController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bank deposit proof submitted! It will be verified against the bank statement.'),
            backgroundColor: Color(0xFF0F6B4F),
            duration: Duration(seconds: 5),
          ),
        );
        widget.onPaymentCompleted();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Submission failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmittingBankProof = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final invoiceId = widget.invoice['id'];
    final reqRef = 'INV-$invoiceId';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 720),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pay Invoice #$invoiceId',
                        style: GoogleFonts.bricolageGrotesque(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.navy,
                        ),
                      ),
                      Text(
                        'Outstanding: KSh ${_outstandingBalance.toStringAsFixed(2)}',
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F6B4F),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Channel Selector Pills (M-Pesa vs Bank)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildChannelTab(
                        'MPESA',
                        'M-Pesa Express',
                        Icons.phonelink_ring_outlined,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: _buildChannelTab(
                        'BANK',
                        'Bank Transfer / Deposit',
                        Icons.account_balance_outlined,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Channel Content
              if (_paymentChannel == 'MPESA')
                _buildMpesaChannel()
              else
                _buildBankChannel(reqRef),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChannelTab(String channel, String label, IconData icon) {
    final isSelected = _paymentChannel == channel;
    return GestureDetector(
      onTap: () => setState(() {
        _paymentChannel = channel;
        _showSubmitProofForm = false;
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? const Color(0xFF0F6B4F) : const Color(0xFF6B7280),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? const Color(0xFF0F6B4F) : const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMpesaChannel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF0F6B4F).withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF0F6B4F).withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Color(0xFF0F6B4F), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Enter your Safaricom phone number. A PIN prompt will pop up automatically on your phone.',
                  style: GoogleFonts.dmSans(fontSize: 12, color: const Color(0xFF0F6B4F)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'M-Pesa Phone Number',
          style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.navy),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.phone_android, size: 20, color: Color(0xFF0F6B4F)),
            hintText: 'e.g. 0712345678 or 254712345678',
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0F6B4F), width: 1.8)),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: _isSubmittingMpesa ? null : _handleMpesaPay,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F6B4F),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: _isSubmittingMpesa
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                      SizedBox(width: 12),
                      Text('SENDING STK PROMPT...'),
                    ],
                  )
                : Text(
                    'PAY KSh ${_outstandingBalance.toStringAsFixed(2)} VIA M-PESA',
                    style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.8),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildBankChannel(String reqRef) {
    if (_isLoadingGateways) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(color: Color(0xFF0F6B4F)),
        ),
      );
    }

    if (_bankAccounts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFF59E0B)),
        ),
        child: Column(
          children: [
            const Icon(Icons.account_balance, color: Color(0xFFD97706), size: 32),
            const SizedBox(height: 10),
            Text(
              'No Direct Bank Accounts Configured',
              style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, color: const Color(0xFF92400E)),
            ),
            const SizedBox(height: 4),
            Text(
              'Your property management has not yet published an agency bank account. Please pay via M-Pesa or contact management.',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(fontSize: 12, color: const Color(0xFF92400E)),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Bank Selection Dropdown (if multiple accounts)
        if (_bankAccounts.length > 1) ...[
          Text(
            'Select Destination Bank',
            style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.navy),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<dynamic>(
            initialValue: _selectedBank,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
            ),
            items: _bankAccounts.map((acc) {
              return DropdownMenuItem<dynamic>(
                value: acc,
                child: Text(
                  '${acc['bank_name']} - ${acc['account_number']}',
                  style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              );
            }).toList(),
            onChanged: (val) => setState(() => _selectedBank = val),
          ),
          const SizedBox(height: 14),
        ],

        // Selected Bank Details Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F6B4F).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.account_balance, color: Color(0xFF0F6B4F), size: 20),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedBank?['bank_name'] ?? 'Bank Account',
                        style: GoogleFonts.bricolageGrotesque(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.navy),
                      ),
                      Text(
                        _selectedBank?['account_name'] ?? 'Collection Account',
                        style: GoogleFonts.dmSans(fontSize: 12, color: const Color(0xFF6B7280)),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // Account Number with Copy Button
              _buildCopyableRow(
                label: 'Account Number',
                value: _selectedBank?['account_number'] ?? '',
              ),
              if (_selectedBank?['paybill_number'] != null && _selectedBank!['paybill_number'].toString().isNotEmpty) ...[
                const SizedBox(height: 10),
                _buildCopyableRow(
                  label: 'Bank Paybill (if via M-Pesa)',
                  value: _selectedBank!['paybill_number'].toString(),
                ),
              ],
              if (_selectedBank?['branch_name'] != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Branch: ${_selectedBank!['branch_name']}',
                  style: GoogleFonts.dmSans(fontSize: 12, color: const Color(0xFF6B7280)),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),

        // CRITICAL INVOICE REFERENCE BANNER
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFE8A317).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE8A317).withValues(alpha: 0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.star, color: Color(0xFFB45309), size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'CRITICAL PAYMENT NARRATION',
                    style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFFB45309), letterSpacing: 0.8),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'When transferring via bank app, PesaLink or bank slip, put this exact reference in the narration/remarks so your receipt is generated instantly:',
                style: GoogleFonts.dmSans(fontSize: 12, color: const Color(0xFF92400E)),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE8A317)),
                    ),
                    child: Text(
                      reqRef,
                      style: GoogleFonts.bricolageGrotesque(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF92400E)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: () => _copyToClipboard(reqRef, 'Narration Reference'),
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('COPY REF'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB45309),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      textStyle: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Toggle Proof Form
        if (!_showSubmitProofForm)
          OutlinedButton.icon(
            onPressed: () => setState(() => _showSubmitProofForm = true),
            icon: const Icon(Icons.receipt_long, color: Color(0xFF0F6B4F)),
            label: const Text('I Have Made The Transfer • Submit Reference'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF0F6B4F),
              side: const BorderSide(color: Color(0xFF0F6B4F)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          )
        else ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Submit Bank Transfer Proof',
                  style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.navy),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _bankRefController,
                  decoration: InputDecoration(
                    labelText: 'Bank Transaction Code / Ref',
                    hintText: 'e.g. EQ8891023 or FT2601923',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _bankNotesController,
                  decoration: InputDecoration(
                    labelText: 'Additional Notes (Optional)',
                    hintText: 'e.g. Paid via Equity Mobile App',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    onPressed: _isSubmittingBankProof ? null : _handleBankProofSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F6B4F),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: _isSubmittingBankProof
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('CONFIRM & SUBMIT TO MANAGEMENT'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCopyableRow({required String label, required String value}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.dmSans(fontSize: 11, color: const Color(0xFF6B7280))),
            const SizedBox(height: 2),
            Text(value, style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.navy)),
          ],
        ),
        InkWell(
          onTap: () => _copyToClipboard(value, label),
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFD1D5DB)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.copy, size: 14, color: Color(0xFF4B5563)),
                const SizedBox(width: 4),
                Text('COPY', style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF4B5563))),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
