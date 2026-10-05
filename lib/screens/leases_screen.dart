import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'lease_details_screen.dart';

class LeasesScreen extends StatefulWidget {
  const LeasesScreen({super.key});

  @override
  State<LeasesScreen> createState() => _LeasesScreenState();
}

class _LeasesScreenState extends State<LeasesScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<dynamic> _leases = [];
  String? _error;
  String _statusFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    _loadLeases();
  }

  Future<void> _loadLeases() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final status = _statusFilter == 'ALL' ? null : _statusFilter;
      final response = await _apiService.getLeases(status: status);
      
      if (response.containsKey('data') && response['data'] is List) {
         _leases = response['data'];
      } else if (response.containsKey('results') && response['results'] is List) {
         _leases = response['results'];
      } else if (response.containsKey('leases') && response['leases'] is List) {
         _leases = response['leases'];
      } else {
          _leases = response.values.firstWhere((v) => v is List, orElse: () => []);
      }
      
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showAddLeaseDialog() {
    showDialog(
      context: context,
      builder: (context) => const AddLeaseDialog(),
    ).then((result) {
      if (result == true) {
        _loadLeases();
      }
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
                    'Leases',
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: isSmall ? 22 : 26,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.navy,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Create and manage lease agreements',
                    style: GoogleFonts.dmSans(fontSize: isSmall ? 12 : 14, color: AppTheme.mutedText),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _showAddLeaseDialog,
                icon: const Icon(Icons.add, size: 18),
                label: Text(isSmall ? 'Create' : 'Create Lease'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.teal,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: isSmall ? 12 : 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          SizedBox(height: isSmall ? 16 : 24),
          // Filter Bar - Wrap
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFilterChip('ALL', 'All'),
              _buildFilterChip('ACTIVE', 'Active'),
              _buildFilterChip('PENDING', 'Pending'),
              _buildFilterChip('TERMINATED', 'Terminated'),
            ],
          ),
          SizedBox(height: isSmall ? 16 : 24),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.teal))
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, color: Colors.red.shade300, size: 48),
                            const SizedBox(height: 16),
                            Text(_error!, style: TextStyle(color: Colors.red.shade700), textAlign: TextAlign.center),
                            const SizedBox(height: 16),
                            ElevatedButton(onPressed: _loadLeases, child: const Text('Retry')),
                          ],
                        ),
                      )
                    : _leases.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.description_outlined, size: 64, color: AppTheme.mutedText.withValues(alpha: 0.3)),
                                const SizedBox(height: 16),
                                Text('No leases found', style: GoogleFonts.bricolageGrotesque(fontSize: 20, color: AppTheme.navy)),
                                const SizedBox(height: 8),
                                Text('Try changing the filter or creating a new lease.', style: GoogleFonts.dmSans(color: AppTheme.mutedText), textAlign: TextAlign.center),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _leases.length,
                            itemBuilder: (context, index) {
                              final lease = _leases[index];
                              return _LeaseListItem(lease: lease, onRefresh: _loadLeases);
                            },
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
      labelStyle: GoogleFonts.dmSans(
        color: isSelected ? Colors.white : AppTheme.navy,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        fontSize: 13,
      ),
      backgroundColor: Colors.white,
      selectedColor: AppTheme.navy,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: isSelected ? AppTheme.navy : AppTheme.border),
      ),
      onSelected: (selected) {
        if (selected) {
          setState(() => _statusFilter = value);
          _loadLeases();
        }
      },
    );
  }
}

class _LeaseListItem extends StatelessWidget {
  final Map<String, dynamic> lease;
  final VoidCallback onRefresh;

  const _LeaseListItem({required this.lease, required this.onRefresh});

  Future<void> _changeStatus(BuildContext context) async {
    final currentStatus = lease['status'] ?? 'PENDING';
    final statuses = ['PENDING', 'ACTIVE', 'TERMINATED', 'RENEWED'];
    
    final newStatus = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Change Lease Status'),
        children: statuses.map((s) => SimpleDialogOption(
          onPressed: () => Navigator.pop(ctx, s),
          child: Row(
            children: [
              Icon(
                currentStatus == s ? Icons.radio_button_checked : Icons.radio_button_off,
                color: currentStatus == s ? AppTheme.teal : Colors.grey,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(s, style: TextStyle(fontWeight: currentStatus == s ? FontWeight.bold : FontWeight.normal)),
            ],
          ),
        )).toList(),
      ),
    );

    if (newStatus != null && newStatus != currentStatus) {
      try {
        await ApiService().updateLease(lease['id'], {'status': newStatus});
        onRefresh();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status updated to $newStatus')));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = lease['status'] ?? 'UNKNOWN';
    Color statusColor = Colors.grey;
    if (status == 'ACTIVE') statusColor = Colors.green;
    if (status == 'PENDING') statusColor = Colors.orange;
    if (status == 'TERMINATED') statusColor = Colors.red;

    final unit = lease['unit'] ?? {};
    final tenant = lease['tenant'] ?? {};
    final isSmall = MediaQuery.of(context).size.width < 400;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.01), blurRadius: 5, offset: const Offset(0, 2)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => LeaseDetailsScreen(lease: lease)));
          },
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: isSmall ? 12 : 20, vertical: isSmall ? 12 : 16),
            child: Row(
              children: [
                Container(
                  width: isSmall ? 40 : 48,
                  height: isSmall ? 40 : 48,
                  decoration: BoxDecoration(
                    color: AppTheme.brass.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(child: Icon(Icons.description_outlined, color: AppTheme.brass, size: 20)),
                ),
                SizedBox(width: isSmall ? 10 : 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Unit ${unit['unit_number'] ?? '?'} • ${tenant['username'] ?? '?'}',
                        style: GoogleFonts.dmSans(fontSize: isSmall ? 13 : 16, fontWeight: FontWeight.w600, color: AppTheme.navy),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined, size: 12, color: AppTheme.mutedText),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              '${lease['start_date']} to ${lease['end_date']}',
                              style: GoogleFonts.dmSans(fontSize: 11, color: AppTheme.mutedText),
                              overflow: TextOverflow.ellipsis,
                            ),
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
                    Text(
                      'KSh ${lease['rent_amount'] ?? 0}',
                      style: GoogleFonts.bricolageGrotesque(fontSize: isSmall ? 13 : 16, fontWeight: FontWeight.w700, color: AppTheme.navy),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                      child: Text(status, style: GoogleFonts.dmSans(fontSize: 9, fontWeight: FontWeight.w700, color: statusColor)),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_horiz, color: AppTheme.mutedText),
                  onSelected: (value) {
                    if (value == 'status') _changeStatus(context);
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'status', child: Text('Change Status')),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AddLeaseDialog extends StatefulWidget {
  const AddLeaseDialog({super.key});

  @override
  State<AddLeaseDialog> createState() => _AddLeaseDialogState();
}

class _AddLeaseDialogState extends State<AddLeaseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();
  final _rentController = TextEditingController();
  final _depositController = TextEditingController();
  final _notesController = TextEditingController();
  
  final ApiService _apiService = ApiService();
  List<dynamic> _units = [];
  List<dynamic> _tenants = [];
  int? _selectedUnitId;
  int? _selectedTenantId;
  
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final unitRes = await _apiService.getUnits(limit: 100, status: 'VACANT');
      final tenantRes = await _apiService.getUsers(limit: 100);
      
      List<dynamic> u = [];
      if (unitRes.containsKey('data')) {
        u = unitRes['data'];
      } else if (unitRes.containsKey('results')) u = unitRes['results'];
      else u = unitRes.values.firstWhere((v) => v is List, orElse: () => []);

      List<dynamic> t = [];
      if (tenantRes.containsKey('data')) {
        t = tenantRes['data'];
      } else if (tenantRes.containsKey('results')) t = tenantRes['results'];
      else t = tenantRes.values.firstWhere((v) => v is List, orElse: () => []);
      
      setState(() {
        _units = u;
        _tenants = t.where((u) => u['role'] == 'TENANT').toList();
        if (_units.isNotEmpty) _selectedUnitId = _units[0]['id'];
        if (_tenants.isNotEmpty) _selectedTenantId = _tenants[0]['id'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = "Failed to load units/tenants. Can't create lease.";
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _startDateController.dispose();
    _endDateController.dispose();
    _rentController.dispose();
    _depositController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedUnitId == null || _selectedTenantId == null) {
      setState(() => _error = "Please select a unit and a tenant");
      return;
    }
    
    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final data = {
        'unit_id': _selectedUnitId,
        'tenant_id': _selectedTenantId,
        'start_date': _startDateController.text,
        'end_date': _endDateController.text,
        'rent_amount': double.parse(_rentController.text),
        'deposit_amount': double.parse(_depositController.text),
        'status': 'PENDING',
        'notes': _notesController.text,
      };

      await _apiService.createLease(data);
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = screenWidth < 400;
    final dialogPad = isSmall ? 16.0 : 28.0;

    if (_isLoading) {
       return const Dialog(child: SizedBox(width: 100, height: 100, child: Center(child: CircularProgressIndicator())));
    }

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
                      Flexible(
                        child: Text(
                          'Create Lease',
                          style: GoogleFonts.bricolageGrotesque(fontSize: isSmall ? 18 : 22, fontWeight: FontWeight.w700, color: AppTheme.navy),
                        ),
                      ),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (_error != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                      child: Text(_error!, style: TextStyle(color: Colors.red.shade700, fontSize: 13)),
                    ),
                  if (_units.isEmpty || _tenants.isEmpty)
                   const Text("You need vacant units and registered tenants to create a lease.", style: TextStyle(color: Colors.red, fontSize: 13)),
                  if (_units.isNotEmpty && _tenants.isNotEmpty) ...[
                    // Unit & Tenant dropdowns - stack on small
                    if (isSmall) ...[
                      DropdownButtonFormField<int>(
                        value: _selectedUnitId,
                        decoration: _inputDecoration('Select Unit (Vacant)'),
                        isExpanded: true,
                        items: _units.map((u) => DropdownMenuItem<int>(value: u['id'], child: Text('Unit ${u['unit_number']}', overflow: TextOverflow.ellipsis))).toList(),
                        onChanged: (v) => setState(() => _selectedUnitId = v),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        value: _selectedTenantId,
                        decoration: _inputDecoration('Select Tenant'),
                        isExpanded: true,
                        items: _tenants.map((t) => DropdownMenuItem<int>(value: t['id'], child: Text(t['username'] ?? t['email'] ?? 'Unknown', overflow: TextOverflow.ellipsis))).toList(),
                        onChanged: (v) => setState(() => _selectedTenantId = v),
                      ),
                    ] else
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              value: _selectedUnitId,
                              decoration: _inputDecoration('Select Unit (Vacant)'),
                              isExpanded: true,
                              items: _units.map((u) => DropdownMenuItem<int>(value: u['id'], child: Text('Unit ${u['unit_number']}'))).toList(),
                              onChanged: (v) => setState(() => _selectedUnitId = v),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              value: _selectedTenantId,
                              decoration: _inputDecoration('Select Tenant'),
                              isExpanded: true,
                              items: _tenants.map((t) => DropdownMenuItem<int>(value: t['id'], child: Text(t['username'] ?? t['email'] ?? 'Unknown', overflow: TextOverflow.ellipsis))).toList(),
                              onChanged: (v) => setState(() => _selectedTenantId = v),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 12),
                    // Dates - stack on small
                    if (isSmall) ...[
                      TextFormField(
                        controller: _startDateController,
                        decoration: _inputDecoration('Start Date (YYYY-MM-DD)'),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _endDateController,
                        decoration: _inputDecoration('End Date (YYYY-MM-DD)'),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                    ] else
                      Row(
                        children: [
                          Expanded(child: TextFormField(controller: _startDateController, decoration: _inputDecoration('Start Date (YYYY-MM-DD)'), validator: (v) => v!.isEmpty ? 'Required' : null)),
                          const SizedBox(width: 12),
                          Expanded(child: TextFormField(controller: _endDateController, decoration: _inputDecoration('End Date (YYYY-MM-DD)'), validator: (v) => v!.isEmpty ? 'Required' : null)),
                        ],
                      ),
                    const SizedBox(height: 12),
                    // Rent & Deposit - stack on small
                    if (isSmall) ...[
                      TextFormField(
                        controller: _rentController,
                        decoration: _inputDecoration('Monthly Rent (KSh)'),
                        keyboardType: TextInputType.number,
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _depositController,
                        decoration: _inputDecoration('Deposit (KSh)'),
                        keyboardType: TextInputType.number,
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                    ] else
                      Row(
                        children: [
                          Expanded(child: TextFormField(controller: _rentController, decoration: _inputDecoration('Monthly Rent (KSh)'), keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'Required' : null)),
                          const SizedBox(width: 12),
                          Expanded(child: TextFormField(controller: _depositController, decoration: _inputDecoration('Deposit (KSh)'), keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'Required' : null)),
                        ],
                      ),
                    const SizedBox(height: 12),
                    TextFormField(controller: _notesController, decoration: _inputDecoration('Notes (Optional)'), maxLines: 2),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.teal, foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('CREATE LEASE', style: TextStyle(fontWeight: FontWeight.bold)),
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

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      isDense: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.teal, width: 2)),
      filled: true,
      fillColor: Colors.grey.shade50,
    );
  }
}
