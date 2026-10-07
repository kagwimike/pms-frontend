import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/ticket_chat_widget.dart';
// import 'package:image_picker/image_picker.dart'; // Uncomment if using real upload

class VendorJobsScreen extends StatefulWidget {
  const VendorJobsScreen({super.key});

  @override
  State<VendorJobsScreen> createState() => _VendorJobsScreenState();
}

class _VendorJobsScreenState extends State<VendorJobsScreen> {
  final ApiService _api = ApiService();
  List<dynamic> _jobs = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  Future<void> _loadJobs() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final res = await _api.getMaintenanceRequests(limit: 100);
      if (mounted) {
        setState(() {
          _jobs = ApiService.extractList(res);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _showUpdateDialog(Map<String, dynamic> job) {
    showDialog(
      context: context,
      builder: (context) => _VendorJobUpdateDialog(job: job),
    ).then((updated) {
      if (updated == true) _loadJobs();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: AppTheme.teal));
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Failed to load jobs: $_error'),
            TextButton(onPressed: _loadJobs, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_jobs.isEmpty) {
      return Center(
        child: Text('No assigned jobs at the moment.', style: GoogleFonts.dmSans(color: AppTheme.mutedText)),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadJobs,
      child: ListView.separated(
        padding: const EdgeInsets.all(24),
        itemCount: _jobs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final job = _jobs[index];
          final unit = job['unit']?['unit_number'] ?? 'Unknown Unit';
          final prop = job['property']?['name'] ?? 'Unknown Property';
          final createdAt = DateTime.tryParse(job['createdAt'] ?? '');
          final dateFmt = createdAt != null ? DateFormat('MMM d, yyyy h:mm a').format(createdAt) : '';

          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppTheme.border),
            ),
            child: InkWell(
              onTap: () => _showUpdateDialog(job),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            job['title'] ?? 'No Title',
                            style: GoogleFonts.bricolageGrotesque(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.navy,
                            ),
                          ),
                        ),
                        StatusBadge(status: job['status'] ?? 'PENDING'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 16, color: AppTheme.mutedText),
                        const SizedBox(width: 8),
                        Text('$prop - Unit $unit', style: GoogleFonts.dmSans(color: AppTheme.mutedText)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 16, color: AppTheme.mutedText),
                        const SizedBox(width: 8),
                        Text(dateFmt, style: GoogleFonts.dmSans(color: AppTheme.mutedText)),
                      ],
                    ),
                    if (job['vendor_notes'] != null && job['vendor_notes'].toString().isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          children: [
                            const Icon(Icons.note_alt_outlined, size: 16, color: AppTheme.mutedText),
                            const SizedBox(width: 8),
                            Expanded(child: Text(job['vendor_notes'], style: GoogleFonts.dmSans(color: AppTheme.navy))),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 8),
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
                                  child: TicketChatWidget(maintenanceId: job['id']),
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.forum_outlined, size: 16),
                          label: const Text('Ticket Chat'),
                          style: TextButton.styleFrom(foregroundColor: AppTheme.navy),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: () => _showUpdateDialog(job),
                          icon: const Icon(Icons.edit_outlined, size: 16),
                          label: const Text('Update'),
                          style: TextButton.styleFrom(foregroundColor: AppTheme.teal),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _VendorJobUpdateDialog extends StatefulWidget {
  final Map<String, dynamic> job;
  const _VendorJobUpdateDialog({required this.job});

  @override
  State<_VendorJobUpdateDialog> createState() => _VendorJobUpdateDialogState();
}

class _VendorJobUpdateDialogState extends State<_VendorJobUpdateDialog> {
  late String _status;
  final _notesCtrl = TextEditingController();
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _status = widget.job['status'] ?? 'PENDING';
    _notesCtrl.text = widget.job['vendor_notes'] ?? '';
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
        widget.job['id'],
        {
          'status': _status,
          'vendor_notes': _notesCtrl.text,
        },
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() { _error = e.toString(); _isSubmitting = false; });
    }
  }

  void _uploadDocument(String type) {
    // In a real app, this would use image_picker or file_picker to upload a file 
    // to /api/documents with entity_type='MAINTENANCE', entity_id=job['id'], document_type=type
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Simulated uploading $type document...')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Update Job', style: GoogleFonts.bricolageGrotesque(fontWeight: FontWeight.w600)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.red.shade50,
                child: Text(_error!, style: TextStyle(color: Colors.red.shade700)),
              ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _status,
              decoration: InputDecoration(
                labelText: 'Job Status',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                filled: true, fillColor: Colors.grey.shade50,
              ),
              items: const [
                DropdownMenuItem(value: 'ASSIGNED', child: Text('Assigned')),
                DropdownMenuItem(value: 'IN_PROGRESS', child: Text('In Progress')),
                DropdownMenuItem(value: 'COMPLETED', child: Text('Completed')),
              ],
              onChanged: (v) => setState(() => _status = v!),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesCtrl,
              decoration: InputDecoration(
                labelText: 'Notes for Manager',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                filled: true, fillColor: Colors.grey.shade50,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _uploadDocument('QUOTATION'),
                  icon: const Icon(Icons.receipt_long_outlined, size: 18),
                  label: const Text('Quote'),
                  style: OutlinedButton.styleFrom(foregroundColor: AppTheme.brass),
                ),
                OutlinedButton.icon(
                  onPressed: () => _uploadDocument('INVOICE'),
                  icon: const Icon(Icons.request_quote_outlined, size: 18),
                  label: const Text('Invoice'),
                  style: OutlinedButton.styleFrom(foregroundColor: AppTheme.teal),
                ),
              ],
            )
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.teal, foregroundColor: Colors.white),
          child: _isSubmitting 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Update Job'),
        ),
      ],
    );
  }
}
