import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({super.key});

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<dynamic> _invoices = [];
  String? _error;
  String _statusFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  Future<void> _loadInvoices() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final status = _statusFilter == 'ALL' ? null : _statusFilter;
      final response = await _apiService.getInvoices(status: status);
      if (response.containsKey('data') && response['data'] is List) {
         _invoices = response['data'];
      } else if (response.containsKey('results') && response['results'] is List) {
         _invoices = response['results'];
      } else if (response.containsKey('invoices') && response['invoices'] is List) {
         _invoices = response['invoices'];
      } else {
          _invoices = response.values.firstWhere((v) => v is List, orElse: () => []);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAddInvoiceDialog() {
    showDialog(
      context: context,
      builder: (context) => const AddInvoiceDialog(),
    ).then((result) {
      if (result == true) _loadInvoices();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = screenWidth < 400;
    final pad = isSmall ? 16.0 : 28.0;

    return Padding(
      padding: EdgeInsets.all(pad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isSmall ? 'Rent & Invoices' : 'Rent Collection & Invoices',
                    style: GoogleFonts.bricolageGrotesque(fontSize: isSmall ? 20 : 26, fontWeight: FontWeight.w700, color: AppTheme.navy),
                  ),
                  const SizedBox(height: 4),
                  Text('Track invoices and payments', style: GoogleFonts.dmSans(fontSize: isSmall ? 12 : 14, color: AppTheme.mutedText)),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _showAddInvoiceDialog,
                icon: const Icon(Icons.add, size: 18),
                label: Text(isSmall ? 'Create' : 'Create Invoice'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.teal, foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: isSmall ? 12 : 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          SizedBox(height: isSmall ? 16 : 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFilterChip('ALL', 'All'),
              _buildFilterChip('UNPAID', 'Unpaid'),
              _buildFilterChip('PARTIAL', 'Partial'),
              _buildFilterChip('PAID', 'Paid'),
            ],
          ),
          SizedBox(height: isSmall ? 16 : 24),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.teal))
                : _error != null
                    ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.error_outline, color: Colors.red.shade300, size: 48),
                        const SizedBox(height: 16),
                        Text(_error!, style: TextStyle(color: Colors.red.shade700), textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(onPressed: _loadInvoices, child: const Text('Retry')),
                      ]))
                    : _invoices.isEmpty
                        ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Icon(Icons.receipt_long_outlined, size: 64, color: AppTheme.mutedText.withValues(alpha: 0.3)),
                            const SizedBox(height: 16),
                            Text('No invoices found', style: GoogleFonts.bricolageGrotesque(fontSize: 20, color: AppTheme.navy)),
                            const SizedBox(height: 8),
                            Text('Try changing the filter or creating a new invoice.', style: GoogleFonts.dmSans(color: AppTheme.mutedText), textAlign: TextAlign.center),
                          ]))
                        : ListView.builder(
                            itemCount: _invoices.length,
                            itemBuilder: (context, index) => _InvoiceListItem(invoice: _invoices[index]),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _statusFilter == value;
    return FilterChip(
      selected: isSelected,
      label: Text(label),
      labelStyle: GoogleFonts.dmSans(color: isSelected ? Colors.white : AppTheme.navy, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400, fontSize: 13),
      backgroundColor: Colors.white,
      selectedColor: AppTheme.navy,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? AppTheme.navy : AppTheme.border)),
      onSelected: (selected) { if (selected) { setState(() => _statusFilter = value); _loadInvoices(); } },
    );
  }
}

class _InvoiceListItem extends StatelessWidget {
  final Map<String, dynamic> invoice;
  const _InvoiceListItem({required this.invoice});

  @override
  Widget build(BuildContext context) {
    final status = invoice['status'] ?? 'UNKNOWN';
    Color statusColor = Colors.grey;
    if (status == 'PAID') statusColor = Colors.green;
    if (status == 'UNPAID') statusColor = Colors.red;
    if (status == 'PARTIAL') statusColor = Colors.orange;

    final lease = invoice['lease'] ?? {};
    final tenant = lease['tenant'] ?? {};
    final unit = lease['unit'] ?? {};
    final isSmall = MediaQuery.of(context).size.width < 400;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.01), blurRadius: 5, offset: const Offset(0, 2))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {},
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: isSmall ? 12 : 20, vertical: isSmall ? 12 : 16),
            child: Row(
              children: [
                Container(
                  width: isSmall ? 40 : 48, height: isSmall ? 40 : 48,
                  decoration: BoxDecoration(
                    color: status == 'UNPAID' ? Colors.red.withValues(alpha: 0.1) : AppTheme.bgGreyGreen,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(child: Icon(Icons.receipt_long_outlined, color: status == 'UNPAID' ? Colors.red : AppTheme.navy, size: 20)),
                ),
                SizedBox(width: isSmall ? 10 : 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'INV-${invoice['id'].toString().padLeft(4, '0')} • ${tenant['username'] ?? '?'}',
                        style: GoogleFonts.dmSans(fontSize: isSmall ? 13 : 16, fontWeight: FontWeight.w600, color: AppTheme.navy),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.door_sliding_outlined, size: 12, color: AppTheme.mutedText),
                          const SizedBox(width: 3),
                          Text('Unit ${unit['unit_number'] ?? '?'}', style: GoogleFonts.dmSans(fontSize: 11, color: AppTheme.mutedText)),
                          const SizedBox(width: 8),
                          const Icon(Icons.calendar_today_outlined, size: 12, color: AppTheme.mutedText),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text('Due: ${invoice['due_date']}', style: GoogleFonts.dmSans(fontSize: 11, color: status == 'UNPAID' ? Colors.red : AppTheme.mutedText), overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('KSh ${invoice['amount'] ?? 0}', style: GoogleFonts.bricolageGrotesque(fontSize: isSmall ? 13 : 16, fontWeight: FontWeight.w700, color: AppTheme.navy)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                      child: Text(status, style: GoogleFonts.dmSans(fontSize: 9, fontWeight: FontWeight.w700, color: statusColor)),
                    ),
                  ],
                ),
                if (!isSmall) ...[
                  const SizedBox(width: 12),
                  Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.mutedText.withValues(alpha: 0.5)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AddInvoiceDialog extends StatefulWidget {
  const AddInvoiceDialog({super.key});

  @override
  State<AddInvoiceDialog> createState() => _AddInvoiceDialogState();
}

class _AddInvoiceDialogState extends State<AddInvoiceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _dueDateController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  final ApiService _apiService = ApiService();
  List<dynamic> _leases = [];
  int? _selectedLeaseId;
  String _invoiceType = 'RENT';
  
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() { super.initState(); _loadData(); }

  Future<void> _loadData() async {
    try {
      final leaseRes = await _apiService.getLeases(limit: 100, status: 'ACTIVE');
      List<dynamic> l = [];
      if (leaseRes.containsKey('data')) l = leaseRes['data'];
      else if (leaseRes.containsKey('results')) l = leaseRes['results'];
      else l = leaseRes.values.firstWhere((v) => v is List, orElse: () => []);
      setState(() { _leases = l; if (_leases.isNotEmpty) _selectedLeaseId = _leases[0]['id']; _isLoading = false; });
    } catch (e) {
      setState(() { _error = "Failed to load active leases."; _isLoading = false; });
    }
  }

  @override
  void dispose() { _amountController.dispose(); _dueDateController.dispose(); _descriptionController.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedLeaseId == null) { setState(() => _error = "Please select an active lease"); return; }
    setState(() { _isSubmitting = true; _error = null; });
    try {
      await _apiService.createInvoice({
        'lease_id': _selectedLeaseId,
        'amount': double.parse(_amountController.text),
        'due_date': _dueDateController.text,
        'status': 'UNPAID',
        'type': _invoiceType,
        'description': _descriptionController.text,
      });
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = screenWidth < 400;
    final dialogPad = isSmall ? 16.0 : 28.0;

    if (_isLoading) return const Dialog(child: SizedBox(width: 100, height: 100, child: Center(child: CircularProgressIndicator())));

    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: isSmall ? 12 : 40, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Padding(
          padding: EdgeInsets.all(dialogPad),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(child: Text('Create Invoice', style: GoogleFonts.bricolageGrotesque(fontSize: isSmall ? 18 : 22, fontWeight: FontWeight.w700, color: AppTheme.navy))),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (_error != null)
                    Container(
                      padding: const EdgeInsets.all(12), margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                      child: Text(_error!, style: TextStyle(color: Colors.red.shade700, fontSize: 13)),
                    ),
                  if (_leases.isEmpty)
                   const Text("You need active leases to create an invoice.", style: TextStyle(color: Colors.red, fontSize: 13)),
                  if (_leases.isNotEmpty) ...[
                    DropdownButtonFormField<int>(
                      value: _selectedLeaseId,
                      decoration: _inputDecoration('Select Active Lease'),
                      isExpanded: true,
                      items: _leases.map((l) {
                        final unit = l['unit'] ?? {};
                        final tenant = l['tenant'] ?? {};
                        return DropdownMenuItem<int>(value: l['id'], child: Text('Unit ${unit['unit_number']} - ${tenant['username']}', overflow: TextOverflow.ellipsis));
                      }).toList(),
                      onChanged: (v) => setState(() => _selectedLeaseId = v),
                    ),
                    const SizedBox(height: 12),
                    if (isSmall) ...[
                      DropdownButtonFormField<String>(
                        value: _invoiceType,
                        decoration: _inputDecoration('Invoice Type'),
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(value: 'RENT', child: Text('Rent')),
                          DropdownMenuItem(value: 'DEPOSIT', child: Text('Deposit')),
                          DropdownMenuItem(value: 'MAINTENANCE', child: Text('Maintenance Fee')),
                          DropdownMenuItem(value: 'LATE_FEE', child: Text('Late Fee')),
                        ],
                        onChanged: (v) => setState(() => _invoiceType = v!),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(controller: _amountController, decoration: _inputDecoration('Amount (KSh)'), keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'Required' : null),
                    ] else
                      Row(children: [
                        Expanded(child: DropdownButtonFormField<String>(
                          value: _invoiceType,
                          decoration: _inputDecoration('Invoice Type'),
                          isExpanded: true,
                          items: const [
                            DropdownMenuItem(value: 'RENT', child: Text('Rent')),
                            DropdownMenuItem(value: 'DEPOSIT', child: Text('Deposit')),
                            DropdownMenuItem(value: 'MAINTENANCE', child: Text('Maintenance Fee')),
                            DropdownMenuItem(value: 'LATE_FEE', child: Text('Late Fee')),
                          ],
                          onChanged: (v) => setState(() => _invoiceType = v!),
                        )),
                        const SizedBox(width: 12),
                        Expanded(child: TextFormField(controller: _amountController, decoration: _inputDecoration('Amount (KSh)'), keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'Required' : null)),
                      ]),
                    const SizedBox(height: 12),
                    TextFormField(controller: _dueDateController, decoration: _inputDecoration('Due Date (YYYY-MM-DD)'), validator: (v) => v!.isEmpty ? 'Required' : null),
                    const SizedBox(height: 12),
                    TextFormField(controller: _descriptionController, decoration: _inputDecoration('Description'), maxLines: 2),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submit,
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.teal, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                        child: _isSubmitting
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('CREATE INVOICE', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) => InputDecoration(
    labelText: label, isDense: true,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.border)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.border)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.teal, width: 2)),
    filled: true, fillColor: Colors.grey.shade50,
  );
}
