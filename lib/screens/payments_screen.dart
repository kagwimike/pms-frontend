import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'package:intl/intl.dart';

class PaymentsScreen extends StatefulWidget {
  final bool isOwner;
  const PaymentsScreen({super.key, required this.isOwner});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<dynamic> _payments = [];
  String? _error;
  String _statusFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final status = _statusFilter == 'ALL' ? null : _statusFilter;
      final response = await _apiService.getPayments(status: status);
      setState(() {
        _payments = ApiService.extractList(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _fmtKsh(dynamic amount) {
    if (amount == null) return 'KSh 0.00';
    final val = double.tryParse(amount.toString()) ?? 0.0;
    return NumberFormat.currency(symbol: 'KSh ', decimalDigits: 2).format(val);
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'PENDING': return Colors.orange;
      case 'CONFIRMED': return AppTheme.teal;
      case 'FAILED': return Colors.red;
      case 'REVERSED': return Colors.redAccent;
      case 'REFUNDED': return Colors.purple;
      case 'UNMATCHED': return Colors.brown;
      case 'CANCELLED': return Colors.grey;
      default: return Colors.blue;
    }
  }

  Widget _chip(String status, String label) {
    final isSelected = _statusFilter == status;
    return ActionChip(
      label: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.black87)),
      backgroundColor: isSelected ? AppTheme.teal : Colors.grey.shade200,
      onPressed: () {
        setState(() => _statusFilter = status);
        _loadPayments();
      },
    );
  }

  void _showAddPaymentDialog() {
    showDialog(
      context: context,
      builder: (context) => const AddPaymentDialog(),
    ).then((val) {
      if (val == true) _loadPayments();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text('Payments', style: GoogleFonts.inter(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (!widget.isOwner) // Tenants can add payments
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: ElevatedButton.icon(
                onPressed: _showAddPaymentDialog,
                icon: const Icon(Icons.payment),
                label: const Text('Make Payment'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.teal,
                  foregroundColor: Colors.white,
                ),
              ),
            )
        ],
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _chip('ALL', 'All'),
                const SizedBox(width: 8),
                _chip('PENDING', 'Pending'),
                const SizedBox(width: 8),
                _chip('CONFIRMED', 'Confirmed'),
                const SizedBox(width: 8),
                _chip('FAILED', 'Failed'),
                const SizedBox(width: 8),
                _chip('UNMATCHED', 'Unmatched'),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text('Error: $_error', style: const TextStyle(color: Colors.red)))
                    : _payments.isEmpty
                        ? const Center(child: Text('No payments found.'))
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            itemCount: _payments.length,
                            itemBuilder: (context, index) {
                              final p = _payments[index];
                              final status = p['status'] ?? 'PENDING';
                              return Card(
                                elevation: 0,
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(color: Colors.grey.shade200),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(_fmtKsh(p['amount']), style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18)),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: _statusColor(status).withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              status,
                                              style: TextStyle(color: _statusColor(status), fontSize: 12, fontWeight: FontWeight.bold),
                                            ),
                                          )
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text('Ref: ${p['transaction_reference'] ?? 'N/A'}', style: TextStyle(color: Colors.grey.shade700)),
                                      Text('Method: ${p['payment_method'] ?? 'UNKNOWN'}', style: TextStyle(color: Colors.grey.shade700)),
                                      const SizedBox(height: 8),
                                      if (p['invoice'] != null)
                                        Text('Invoice #${p['invoice']['id']} - ${p['invoice']['title'] ?? 'N/A'}', style: const TextStyle(fontWeight: FontWeight.w500)),
                                      if (p['tenant'] != null && widget.isOwner)
                                        Text('Tenant: ${p['tenant']['username'] ?? 'N/A'}', style: const TextStyle(fontStyle: FontStyle.italic)),
                                      if (widget.isOwner) ...[
                                        const Divider(height: 24),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            if (status == 'PENDING' || status == 'UNMATCHED')
                                              TextButton(
                                                onPressed: () => _updatePaymentStatus(p['id'], 'CONFIRMED'),
                                                child: const Text('Confirm', style: TextStyle(color: AppTheme.teal)),
                                              ),
                                            if (status == 'PENDING')
                                              TextButton(
                                                onPressed: () => _updatePaymentStatus(p['id'], 'FAILED'),
                                                child: const Text('Mark Failed', style: TextStyle(color: Colors.red)),
                                              ),
                                          ],
                                        )
                                      ]
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Future<void> _updatePaymentStatus(int id, String newStatus) async {
    try {
      await _apiService.updatePaymentStatus(id, newStatus);
      _loadPayments();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status updated to $newStatus')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }
}

class AddPaymentDialog extends StatefulWidget {
  const AddPaymentDialog({super.key});

  @override
  State<AddPaymentDialog> createState() => _AddPaymentDialogState();
}

class _AddPaymentDialogState extends State<AddPaymentDialog> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  
  final _amountCtrl = TextEditingController();
  final _refCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController(); // For MPESA

  String _paymentMethod = 'MPESA';
  String? _selectedInvoiceId;
  List<dynamic> _invoices = [];
  bool _isLoadingInvoices = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  Future<void> _loadInvoices() async {
    try {
      final res = await _apiService.getInvoices(status: 'PENDING');
      setState(() {
        _invoices = ApiService.extractList(res);
        _isLoadingInvoices = false;
      });
    } catch (e) {
      setState(() => _isLoadingInvoices = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_paymentMethod == 'MPESA' && _selectedInvoiceId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select an invoice for M-Pesa payments.')));
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      if (_paymentMethod == 'MPESA') {
        await _apiService.initiateMpesaPayment(
          int.parse(_selectedInvoiceId!), 
          _phoneCtrl.text, 
          double.parse(_amountCtrl.text)
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('STK Push sent to your phone.')));
          Navigator.pop(context, true);
        }
      } else {
        await _apiService.createPayment({
          'amount': double.parse(_amountCtrl.text),
          'payment_method': _paymentMethod,
          'transaction_reference': _refCtrl.text,
          if (_selectedInvoiceId != null) 'invoice_id': int.parse(_selectedInvoiceId!),
        });
        if (mounted) Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Make a Payment'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isLoadingInvoices)
                  const CircularProgressIndicator()
                else
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Select Invoice (Optional)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('No Invoice / Unmatched')),
                      ..._invoices.map((inv) => DropdownMenuItem(
                            value: inv['id'].toString(),
                            child: Text('Inv #${inv['id']} - KSh ${inv['amount']}'),
                          ))
                    ],
                    onChanged: (v) => setState(() => _selectedInvoiceId = v),
                  ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _paymentMethod,
                  decoration: InputDecoration(
                    labelText: 'Payment Method',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'MPESA', child: Text('M-Pesa')),
                    DropdownMenuItem(value: 'BANK_TRANSFER', child: Text('Bank Transfer')),
                    DropdownMenuItem(value: 'CARD', child: Text('Card')),
                    DropdownMenuItem(value: 'CASH', child: Text('Cash')),
                  ],
                  onChanged: (v) => setState(() => _paymentMethod = v!),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _amountCtrl,
                  decoration: InputDecoration(
                    labelText: 'Amount (KSh)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                if (_paymentMethod != 'MPESA') ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _refCtrl,
                    decoration: InputDecoration(
                      labelText: 'Transaction Reference',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                ],
                if (_paymentMethod == 'MPESA') ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneCtrl,
                    decoration: InputDecoration(
                      labelText: 'M-Pesa Phone Number (254...)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.teal, foregroundColor: Colors.white),
          child: _isSubmitting ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Submit Payment'),
        )
      ],
    );
  }
}
