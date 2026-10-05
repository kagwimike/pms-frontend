import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'package:intl/intl.dart';

class InspectionsScreen extends StatefulWidget {
  final bool isOwner;
  const InspectionsScreen({super.key, required this.isOwner});

  @override
  State<InspectionsScreen> createState() => _InspectionsScreenState();
}

class _InspectionsScreenState extends State<InspectionsScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<dynamic> _inspections = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadInspections();
  }

  Future<void> _loadInspections() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final response = await _apiService.getInspections();
      setState(() {
        _inspections = ApiService.extractList(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'SCHEDULED': return Colors.orange;
      case 'COMPLETED': return AppTheme.teal;
      case 'CANCELLED': return Colors.red;
      default: return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text('Inspections', style: GoogleFonts.inter(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (widget.isOwner)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: ElevatedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => const AddInspectionDialog(),
                  ).then((val) {
                    if (val == true) _loadInspections();
                  });
                },
                icon: const Icon(Icons.add),
                label: const Text('Schedule Inspection'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.teal,
                  foregroundColor: Colors.white,
                ),
              ),
            )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error', style: const TextStyle(color: Colors.red)))
              : _inspections.isEmpty
                  ? const Center(child: Text('No inspections scheduled.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _inspections.length,
                      itemBuilder: (context, index) {
                        final insp = _inspections[index];
                        final status = insp['status'] ?? 'SCHEDULED';
                        final date = insp['inspection_date'] != null ? DateTime.tryParse(insp['inspection_date']) : null;
                        
                        return Card(
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey.shade200),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _statusColor(status).withOpacity(0.1),
                              child: Icon(Icons.fact_check, color: _statusColor(status)),
                            ),
                            title: Text(insp['type'] ?? 'General Inspection', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (date != null) Text('Date: ${DateFormat('MMM d, yyyy h:mm a').format(date)}'),
                                Text('Status: $status', style: TextStyle(color: _statusColor(status), fontWeight: FontWeight.bold)),
                              ],
                            ),
                              trailing: IconButton(
                                icon: const Icon(Icons.chevron_right),
                                onPressed: () {},
                              ),
                            ),
                          );
                        },
                      ),
    );
  }
}

class AddInspectionDialog extends StatefulWidget {
  const AddInspectionDialog({super.key});

  @override
  State<AddInspectionDialog> createState() => _AddInspectionDialogState();
}

class _AddInspectionDialogState extends State<AddInspectionDialog> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  
  String _type = 'ROUTINE';
  DateTime? _selectedDate;
  String? _selectedLeaseId;
  List<dynamic> _leases = [];
  bool _isLoadingLeases = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadLeases();
  }

  Future<void> _loadLeases() async {
    try {
      final res = await _apiService.getLeases(status: 'ACTIVE');
      setState(() {
        _leases = ApiService.extractList(res);
        _isLoadingLeases = false;
      });
    } catch (e) {
      setState(() => _isLoadingLeases = false);
    }
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedDate == null || _selectedLeaseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields.')));
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await _apiService.createInspection({
        'lease_id': int.parse(_selectedLeaseId!),
        'type': _type,
        'inspection_date': _selectedDate!.toIso8601String(),
        'status': 'SCHEDULED',
      });
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Schedule Inspection'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isLoadingLeases)
                const CircularProgressIndicator()
              else
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Select Lease (Unit)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: _leases.map((l) => DropdownMenuItem(
                        value: l['id'].toString(),
                        child: Text('Lease #${l['id']} - Unit ${l['unit']?['unit_number'] ?? ''}'),
                      )).toList(),
                  onChanged: (v) => setState(() => _selectedLeaseId = v),
                ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _type,
                decoration: InputDecoration(
                  labelText: 'Inspection Type',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                items: const [
                  DropdownMenuItem(value: 'ROUTINE', child: Text('Routine')),
                  DropdownMenuItem(value: 'MOVE_IN', child: Text('Move-In')),
                  DropdownMenuItem(value: 'MOVE_OUT', child: Text('Move-Out')),
                ],
                onChanged: (v) => setState(() => _type = v!),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(_selectedDate == null ? 'Select Date' : DateFormat('MMM d, yyyy').format(_selectedDate!)),
                trailing: const Icon(Icons.calendar_today),
                onTap: _selectDate,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: const BorderSide(color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.teal, foregroundColor: Colors.white),
          child: _isSubmitting ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Schedule'),
        )
      ],
    );
  }
}

