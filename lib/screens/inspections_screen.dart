import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../ui/widgets/responsive_helper.dart';
import 'package:intl/intl.dart';

import 'communication/inspection_detail_screen.dart';

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
  String _selectedFilter = 'ALL';

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
      case 'IN_PROGRESS': return Colors.blue;
      case 'COMPLETED': return AppTheme.teal;
      case 'CANCELLED': return Colors.red;
      default: return Colors.blueGrey;
    }
  }

  IconData _typeIcon(String? type) {
    switch (type) {
      case 'MOVE_IN':
      case 'CHECKIN':
        return Icons.login;
      case 'MOVE_OUT':
      case 'CHECKOUT':
        return Icons.logout;
      default:
        return Icons.fact_check_outlined;
    }
  }

  Color _typeColor(String? type) {
    switch (type) {
      case 'MOVE_IN':
      case 'CHECKIN':
        return const Color(0xFF0284C7);
      case 'MOVE_OUT':
      case 'CHECKOUT':
        return const Color(0xFFE11D48);
      default:
        return const Color(0xFF4F46E5);
    }
  }

  List<dynamic> get _filteredInspections {
    if (_selectedFilter == 'ALL') return _inspections;
    if (_selectedFilter == 'MOVE_IN') {
      return _inspections.where((i) => i['type'] == 'MOVE_IN' || i['type'] == 'CHECKIN').toList();
    }
    if (_selectedFilter == 'MOVE_OUT') {
      return _inspections.where((i) => i['type'] == 'MOVE_OUT' || i['type'] == 'CHECKOUT').toList();
    }
    if (_selectedFilter == 'ROUTINE') {
      return _inspections.where((i) => i['type'] == 'ROUTINE').toList();
    }
    return _inspections;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredInspections;
    final isMobile = AppBreakpoints.isMobile(context);
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          isMobile ? 'Inspections' : 'Unit Inspections & Settlements',
          style: GoogleFonts.inter(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: isMobile ? 17 : 18,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh, color: Colors.black87),
            onPressed: _loadInspections,
          ),
          if (widget.isOwner)
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: isMobile
                  ? IconButton.filled(
                      tooltip: 'New Inspection',
                      style: IconButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.add, size: 20),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => const AddInspectionDialog(),
                        ).then((val) {
                          if (val == true) _loadInspections();
                        });
                      },
                    )
                  : ElevatedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => const AddInspectionDialog(),
                        ).then((val) {
                          if (val == true) _loadInspections();
                        });
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('New Inspection'),
                      style: AppTheme.actionButtonStyle,
                    ),
            ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('ALL', 'All Inspections'),
                  const SizedBox(width: 8),
                  _buildFilterChip('MOVE_IN', 'Move-In (Check-In)'),
                  const SizedBox(width: 8),
                  _buildFilterChip('MOVE_OUT', 'Move-Out (Settlement)'),
                  const SizedBox(width: 8),
                  _buildFilterChip('ROUTINE', 'Routine Periodic'),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Error: $_error', style: const TextStyle(color: Colors.red)),
                            const SizedBox(height: 12),
                            ElevatedButton(onPressed: _loadInspections, child: const Text('Retry')),
                          ],
                        ),
                      )
                    : filtered.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.fact_check_outlined, size: 56, color: Colors.grey.shade400),
                                const SizedBox(height: 12),
                                Text(
                                  _selectedFilter == 'ALL'
                                      ? 'No inspections recorded yet.'
                                      : 'No $_selectedFilter inspections found.',
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                                ),
                                if (widget.isOwner) ...[
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) => const AddInspectionDialog(),
                                      ).then((val) {
                                        if (val == true) _loadInspections();
                                      });
                                    },
                                    icon: const Icon(Icons.add),
                                    label: const Text('Schedule First Inspection'),
                                    style: AppTheme.actionButtonStyle,
                                  ),
                                ],
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final insp = filtered[index];
                              final status = insp['status'] ?? 'SCHEDULED';
                              final type = insp['type'] ?? 'ROUTINE';
                              final date = insp['inspection_date'] != null ? DateTime.tryParse(insp['inspection_date']) : null;
                              final lease = insp['lease'] ?? insp['Lease'];
                              final unit = lease?['unit'] ?? lease?['Unit'];
                              final tenant = lease?['tenant'] ?? lease?['Tenant'];
                              final unitName = unit?['unit_number'] != null ? 'Unit ${unit['unit_number']}' : 'Unit #${insp['lease_id'] ?? ''}';
                              final tenantName = tenant?['full_name'] ?? tenant?['username'] ?? 'Tenant';
                              final deductions = double.tryParse(insp['total_deductions']?.toString() ?? '0') ?? 0;
                              
                              return Card(
                                elevation: 0,
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(color: Colors.grey.shade200),
                                ),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () async {
                                    final res = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => InspectionDetailScreen(
                                          inspectionId: insp['id'],
                                          isOwner: widget.isOwner,
                                        ),
                                      ),
                                    );
                                    if (res == true) _loadInspections();
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: _typeColor(type).withValues(alpha: 0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(_typeIcon(type), color: _typeColor(type), size: 24),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      type == 'MOVE_IN' || type == 'CHECKIN'
                                                          ? 'Move-In Inspection'
                                                          : (type == 'MOVE_OUT' || type == 'CHECKOUT' ? 'Move-Out Inspection' : 'Routine Inspection'),
                                                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                    decoration: BoxDecoration(
                                                      color: _statusColor(status).withValues(alpha: 0.12),
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: Text(
                                                      status,
                                                      style: TextStyle(
                                                        color: _statusColor(status),
                                                        fontWeight: FontWeight.w700,
                                                        fontSize: 11,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '$unitName • $tenantName',
                                                style: TextStyle(color: Colors.grey.shade800, fontSize: 13, fontWeight: FontWeight.w500),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 6),
                                              Wrap(
                                                crossAxisAlignment: WrapCrossAlignment.center,
                                                spacing: 14,
                                                runSpacing: 4,
                                                children: [
                                                  if (date != null)
                                                    Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Icon(Icons.calendar_today, size: 12, color: Colors.grey.shade600),
                                                        const SizedBox(width: 4),
                                                        Text(
                                                          DateFormat('MMM d, yyyy').format(date),
                                                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                                        ),
                                                      ],
                                                    ),
                                                  if (deductions > 0)
                                                    Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Icon(Icons.money_off, size: 12, color: Colors.red.shade700),
                                                        const SizedBox(width: 4),
                                                        Text(
                                                          'Deductions: KES ${deductions.toStringAsFixed(0)}',
                                                          style: TextStyle(color: Colors.red.shade700, fontSize: 12, fontWeight: FontWeight.bold),
                                                        ),
                                                      ],
                                                    ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Icon(Icons.chevron_right, color: Colors.grey),
                                      ],
                                    ),
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

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _selectedFilter == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) {
        if (val) setState(() => _selectedFilter = key);
      },
      selectedColor: AppTheme.teal.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.teal : Colors.grey.shade800,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
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
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Inspection scheduled successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          )
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to schedule inspection. Please check your connection.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          )
        );
      }
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
                  onChanged: _isSubmitting ? null : (v) => setState(() => _selectedLeaseId = v),
                ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _type,
                decoration: InputDecoration(
                  labelText: 'Inspection Type',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                items: const [
                  DropdownMenuItem(value: 'ROUTINE', child: Text('Routine')),
                  DropdownMenuItem(value: 'MOVE_IN', child: Text('Move-In')),
                  DropdownMenuItem(value: 'MOVE_OUT', child: Text('Move-Out')),
                ],
                onChanged: _isSubmitting ? null : (v) => setState(() => _type = v!),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(_selectedDate == null ? 'Select Date' : DateFormat('MMM d, yyyy').format(_selectedDate!)),
                trailing: const Icon(Icons.calendar_today),
                onTap: _isSubmitting ? null : _selectDate,
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
        TextButton(onPressed: _isSubmitting ? null : () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.teal, foregroundColor: Colors.white),
          child: _isSubmitting ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Schedule'),
        )
      ],
    );
  }
}

