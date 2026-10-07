import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ticket_chat_widget.dart';

class MaintenanceScreen extends StatefulWidget {
  /// If true, shows owner view with all requests + status updates.
  /// If false, shows tenant view (create + track own requests).
  final bool isOwner;

  const MaintenanceScreen({super.key, this.isOwner = true});

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  List<dynamic> _requests = [];
  String? _error;
  String _statusFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final status = _statusFilter == 'ALL' ? null : _statusFilter;
      final res = await _api.getMaintenanceRequests(limit: 50, status: status);
      setState(() {
        _requests = ApiService.extractList(res);
        _isLoading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  void _showCreateDialog() {
    showDialog(context: context, builder: (ctx) => _CreateMaintenanceDialog(isOwner: widget.isOwner))
      .then((result) { if (result == true) _load(); });
  }

  void _showUpdateStatusDialog(Map<String, dynamic> request) {
    showDialog(context: context, builder: (ctx) => _UpdateStatusDialog(request: request))
      .then((result) { if (result == true) _load(); });
  }

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 400;
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
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Maintenance', style: GoogleFonts.bricolageGrotesque(fontSize: isSmall ? 22 : 26, fontWeight: FontWeight.w700, color: AppTheme.navy)),
                const SizedBox(height: 4),
                Text(
                  widget.isOwner ? 'Manage maintenance requests' : 'Report and track issues',
                  style: GoogleFonts.dmSans(fontSize: isSmall ? 12 : 14, color: AppTheme.mutedText),
                ),
              ]),
              if (!widget.isOwner)
                ElevatedButton.icon(
                  onPressed: _showCreateDialog,
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(isSmall ? 'Report' : 'Report Issue'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.teal, foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: isSmall ? 12 : 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              _chip('ALL', 'All'),
              const SizedBox(width: 8),
              _chip('PENDING', 'Pending'),
              const SizedBox(width: 8),
              _chip('ASSIGNED', 'Assigned'),
              const SizedBox(width: 8),
              _chip('IN_PROGRESS', 'In Progress'),
              const SizedBox(width: 8),
              _chip('COMPLETED', 'Completed'),
              const SizedBox(width: 8),
              _chip('VERIFIED', 'Verified'),
              const SizedBox(width: 8),
              _chip('CANCELLED', 'Cancelled'),
            ]),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.teal))
                : _error != null
                    ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.error_outline, color: Colors.red.shade300, size: 48),
                        const SizedBox(height: 16),
                        Text(_error!, style: TextStyle(color: Colors.red.shade700)),
                        const SizedBox(height: 16),
                        ElevatedButton(onPressed: _load, child: const Text('Retry')),
                      ]))
                    : _requests.isEmpty
                        ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Icon(Icons.build_outlined, size: 64, color: AppTheme.mutedText.withValues(alpha: 0.3)),
                            const SizedBox(height: 16),
                            Text('No maintenance requests', style: GoogleFonts.bricolageGrotesque(fontSize: 20, color: AppTheme.navy)),
                            const SizedBox(height: 8),
                            Text('Everything is in great shape!', style: GoogleFonts.dmSans(color: AppTheme.mutedText)),
                          ]))
                        : ListView.builder(
                            itemCount: _requests.length,
                            itemBuilder: (ctx, i) => _RequestCard(
                              request: _requests[i],
                              isOwner: widget.isOwner,
                              onStatusUpdate: widget.isOwner ? () => _showUpdateStatusDialog(_requests[i]) : null,
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String value, String label) {
    final sel = _statusFilter == value;
    return FilterChip(
      selected: sel,
      label: Text(label),
      labelStyle: GoogleFonts.dmSans(color: sel ? Colors.white : AppTheme.navy, fontWeight: sel ? FontWeight.w600 : FontWeight.w400),
      backgroundColor: Colors.white,
      selectedColor: AppTheme.navy,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: sel ? AppTheme.navy : AppTheme.border)),
      onSelected: (s) { if (s) { setState(() => _statusFilter = value); _load(); } },
    );
  }
}

class _RequestCard extends StatelessWidget {
  final Map<String, dynamic> request;
  final bool isOwner;
  final VoidCallback? onStatusUpdate;

  const _RequestCard({required this.request, required this.isOwner, this.onStatusUpdate});

  Color _statusColor(String status) {
    switch (status) {
      case 'PENDING': return Colors.orange;
      case 'ASSIGNED': return Colors.blueAccent;
      case 'IN_PROGRESS': return Colors.blue;
      case 'COMPLETED': return Colors.green;
      case 'VERIFIED': return AppTheme.teal;
      case 'CANCELLED': return Colors.red;
      default: return Colors.grey;
    }
  }

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'URGENT': return Colors.red;
      case 'HIGH': return Colors.orange;
      case 'MEDIUM': return AppTheme.brass;
      case 'LOW': return Colors.green;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = request['status'] ?? 'UNKNOWN';
    final priority = request['priority'] ?? 'MEDIUM';
    final tenant = request['tenant'] ?? {};
    final unit = request['unit'] ?? {};
    final vendor = request['assigned_vendor'];

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: EdgeInsets.all(MediaQuery.of(context).size.width < 400 ? 14.0 : 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: _priorityColor(priority).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.build_outlined, color: _priorityColor(priority), size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request['title'] ?? 'Untitled',
                      style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.navy),
                    ),
                    const SizedBox(height: 4),
                    if (isOwner)
                      Text(
                        'Unit ${unit['unit_number'] ?? '?'} • ${tenant['username'] ?? 'Unknown Tenant'}',
                        style: GoogleFonts.dmSans(fontSize: 13, color: AppTheme.mutedText),
                      ),
                  ],
                )),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _statusColor(status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(status, style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w700, color: _statusColor(status))),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _priorityColor(priority).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(priority, style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w600, color: _priorityColor(priority))),
                  ),
                ]),
              ],
            ),
            if (request['description'] != null && (request['description'] as String).isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                request['description'],
                style: GoogleFonts.dmSans(fontSize: 13, color: AppTheme.mutedText, height: 1.4),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (vendor != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.engineering_outlined, size: 16, color: AppTheme.teal),
                  const SizedBox(width: 8),
                  Text('Assigned to: ${vendor['name']}', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.navy)),
                ],
              ),
            ],
            if (isOwner && onStatusUpdate != null) ...[
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => DraggableScrollableSheet(
                          initialChildSize: 0.8,
                          minChildSize: 0.5,
                          maxChildSize: 0.95,
                          builder: (_, controller) => Container(
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                            ),
                            child: TicketChatWidget(maintenanceId: request['id']),
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.forum_outlined, size: 16),
                    label: const Text('Ticket Chat'),
                    style: TextButton.styleFrom(foregroundColor: AppTheme.navy),
                  ),
                  const SizedBox(width: 8),
                  if (isOwner && onStatusUpdate != null)
                    TextButton.icon(
                      onPressed: onStatusUpdate,
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: const Text('Update Status'),
                      style: TextButton.styleFrom(foregroundColor: AppTheme.teal),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CreateMaintenanceDialog extends StatefulWidget {
  final bool isOwner;
  const _CreateMaintenanceDialog({required this.isOwner});

  @override
  State<_CreateMaintenanceDialog> createState() => _CreateMaintenanceDialogState();
}

class _CreateMaintenanceDialogState extends State<_CreateMaintenanceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _priority = 'MEDIUM';
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isSubmitting = true; _error = null; });
    try {
      await ApiService().createMaintenanceRequest({
        'title': _titleCtrl.text,
        'description': _descCtrl.text,
        'priority': _priority,
      });
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() { _error = e.toString(); _isSubmitting = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 400;
    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: isSmall ? 12 : 40, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
        padding: EdgeInsets.all(isSmall ? 16.0 : 28.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Flexible(child: Text('Report Maintenance Issue', style: GoogleFonts.bricolageGrotesque(fontSize: isSmall ? 18 : 22, fontWeight: FontWeight.w700, color: AppTheme.navy))),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ]),
              const SizedBox(height: 24),
              if (_error != null)
                Container(
                  padding: const EdgeInsets.all(12), margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(_error!, style: TextStyle(color: Colors.red.shade700)),
                ),
              TextFormField(
                controller: _titleCtrl,
                decoration: _inputDeco('Issue Title'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _priority,
                decoration: _inputDeco('Priority'),
                items: const [
                  DropdownMenuItem(value: 'LOW', child: Text('Low')),
                  DropdownMenuItem(value: 'MEDIUM', child: Text('Medium')),
                  DropdownMenuItem(value: 'HIGH', child: Text('High')),
                  DropdownMenuItem(value: 'URGENT', child: Text('Urgent')),
                ],
                onChanged: (v) => setState(() => _priority = v!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descCtrl,
                decoration: _inputDeco('Description'),
                maxLines: 4,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.teal, foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('SUBMIT REQUEST', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
        ),
      ),
      ),
    );
  }

  InputDecoration _inputDeco(String label) => InputDecoration(
    labelText: label,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.border)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.border)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.teal, width: 2)),
    filled: true, fillColor: Colors.grey.shade50,
  );
}

class _UpdateStatusDialog extends StatefulWidget {
  final Map<String, dynamic> request;
  const _UpdateStatusDialog({required this.request});

  @override
  State<_UpdateStatusDialog> createState() => _UpdateStatusDialogState();
}

class _UpdateStatusDialogState extends State<_UpdateStatusDialog> {
  late String _status;
  late String _priority;
  final _notesCtrl = TextEditingController();
  String? _assignedVendorId;
  List<dynamic> _vendors = [];
  bool _isLoadingVendors = true;
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _status = widget.request['status'] ?? 'PENDING';
    _priority = widget.request['priority'] ?? 'MEDIUM';
    _notesCtrl.text = widget.request['vendor_notes'] ?? '';
    if (widget.request['assigned_vendor_id'] != null) {
      _assignedVendorId = widget.request['assigned_vendor_id'].toString();
    }
    _loadVendors();
  }

  Future<void> _loadVendors() async {
    try {
      final res = await ApiService().getVendors(limit: 100);
      if (mounted) {
        setState(() {
          _vendors = ApiService.extractList(res);
          _isLoadingVendors = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingVendors = false);
    }
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() { _isSubmitting = true; _error = null; });
    try {
      await ApiService().updateMaintenanceRequest(
        widget.request['id'],
        {
          'status': _status,
          'priority': _priority,
          'vendor_notes': _notesCtrl.text,
          'assigned_vendor_id': _assignedVendorId != null ? int.tryParse(_assignedVendorId!) : null,
        },
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() { _error = e.toString(); _isSubmitting = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 400;
    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: isSmall ? 12 : 40, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
        padding: EdgeInsets.all(isSmall ? 16.0 : 28.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Flexible(child: Text('Update Status', style: GoogleFonts.bricolageGrotesque(fontSize: isSmall ? 18 : 22, fontWeight: FontWeight.w700, color: AppTheme.navy))),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ]),
            const SizedBox(height: 8),
            Text(widget.request['title'] ?? '', style: GoogleFonts.dmSans(fontSize: 14, color: AppTheme.mutedText)),
            const SizedBox(height: 24),
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(12), margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(_error!, style: TextStyle(color: Colors.red.shade700)),
              ),
            DropdownButtonFormField<String>(
              initialValue: _priority,
              decoration: InputDecoration(
                labelText: 'Priority',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                filled: true, fillColor: Colors.grey.shade50,
              ),
              items: const [
                DropdownMenuItem(value: 'LOW', child: Text('Low')),
                DropdownMenuItem(value: 'MEDIUM', child: Text('Medium')),
                DropdownMenuItem(value: 'HIGH', child: Text('High')),
                DropdownMenuItem(value: 'URGENT', child: Text('Urgent')),
              ],
              onChanged: (v) => setState(() => _priority = v!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _status,
              decoration: InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                filled: true, fillColor: Colors.grey.shade50,
              ),
              items: const [
                DropdownMenuItem(value: 'PENDING', child: Text('Pending')),
                DropdownMenuItem(value: 'ASSIGNED', child: Text('Assigned')),
                DropdownMenuItem(value: 'IN_PROGRESS', child: Text('In Progress')),
                DropdownMenuItem(value: 'COMPLETED', child: Text('Completed')),
                DropdownMenuItem(value: 'VERIFIED', child: Text('Verified')),
                DropdownMenuItem(value: 'CANCELLED', child: Text('Cancelled')),
              ],
              onChanged: (v) => setState(() => _status = v!),
            ),
            const SizedBox(height: 16),
            if (!_isLoadingVendors)
              DropdownButtonFormField<String>(
                value: _assignedVendorId,
                decoration: InputDecoration(
                  labelText: 'Assign Vendor',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  filled: true, fillColor: Colors.grey.shade50,
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('None')),
                  ..._vendors.map((v) => DropdownMenuItem(
                        value: v['id'].toString(),
                        child: Text(v['name']),
                      )),
                ],
                onChanged: (v) => setState(() => _assignedVendorId = v),
              ),
            if (!_isLoadingVendors) const SizedBox(height: 16),
            TextFormField(
              controller: _notesCtrl,
              decoration: InputDecoration(
                labelText: 'Vendor Notes',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                filled: true, fillColor: Colors.grey.shade50,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.teal, foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _isSubmitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('UPDATE', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
        ),
      ),
      ),
    );
  }
}
