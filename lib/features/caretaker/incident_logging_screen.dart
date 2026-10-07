import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/status_badge.dart';

class IncidentLoggingScreen extends StatefulWidget {
  const IncidentLoggingScreen({super.key});

  @override
  State<IncidentLoggingScreen> createState() => _IncidentLoggingScreenState();
}

class _IncidentLoggingScreenState extends State<IncidentLoggingScreen> {
  final ApiService _api = ApiService();
  List<dynamic> _incidents = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadIncidents();
  }

  Future<void> _loadIncidents() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final res = await _api.getIncidents(limit: 100);
      if (mounted) {
        setState(() {
          _incidents = ApiService.extractList(res);
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

  void _showReportIncidentDialog() {
    showDialog(
      context: context,
      builder: (context) => const _ReportIncidentDialog(),
    ).then((created) {
      if (created == true) _loadIncidents();
    });
  }

  void _updateStatus(int id, String currentStatus) {
    showDialog(
      context: context,
      builder: (context) {
        String newStatus = currentStatus;
        bool isSubmitting = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Update Incident Status'),
              content: DropdownButtonFormField<String>(
                value: newStatus,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'OPEN', child: Text('Open')),
                  DropdownMenuItem(value: 'IN_PROGRESS', child: Text('In Progress')),
                  DropdownMenuItem(value: 'RESOLVED', child: Text('Resolved')),
                  DropdownMenuItem(value: 'CLOSED', child: Text('Closed')),
                ],
                onChanged: (v) => setDialogState(() => newStatus = v!),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: isSubmitting ? null : () async {
                    setDialogState(() => isSubmitting = true);
                    try {
                      await _api.updateIncidentStatus(id, newStatus);
                      if (context.mounted) Navigator.pop(context, true);
                    } catch (e) {
                      setDialogState(() => isSubmitting = false);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    }
                  },
                  child: isSubmitting ? const CircularProgressIndicator() : const Text('Update'),
                ),
              ],
            );
          }
        );
      }
    ).then((updated) {
      if (updated == true) _loadIncidents();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showReportIncidentDialog,
        backgroundColor: AppTheme.teal,
        icon: const Icon(Icons.add_alert, color: Colors.white),
        label: const Text('Log Incident', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: AppTheme.teal));
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Failed to load incidents: $_error'),
            TextButton(onPressed: _loadIncidents, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_incidents.isEmpty) {
      return Center(
        child: Text('No incidents reported.', style: GoogleFonts.dmSans(color: AppTheme.mutedText)),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadIncidents,
      child: ListView.separated(
        padding: const EdgeInsets.all(24),
        itemCount: _incidents.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final incident = _incidents[index];
          final prop = incident['property']?['name'] ?? 'Unknown Property';
          final reporter = incident['reporter']?['username'] ?? 'Unknown User';
          final createdAt = DateTime.tryParse(incident['createdAt'] ?? '');
          final dateFmt = createdAt != null ? DateFormat('MMM d, yyyy h:mm a').format(createdAt) : '';
          
          Color sevColor = Colors.grey;
          switch (incident['severity']) {
            case 'CRITICAL': sevColor = Colors.red; break;
            case 'HIGH': sevColor = Colors.orange; break;
            case 'MEDIUM': sevColor = Colors.amber; break;
            case 'LOW': sevColor = Colors.green; break;
          }

          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppTheme.border),
            ),
            child: InkWell(
              onTap: () => _updateStatus(incident['id'], incident['status'] ?? 'OPEN'),
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
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: sevColor.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                                child: Text(
                                  incident['severity'] ?? 'UNKNOWN',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: sevColor),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  incident['title'] ?? 'No Title',
                                  style: GoogleFonts.bricolageGrotesque(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.navy),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        StatusBadge(status: incident['status'] ?? 'OPEN'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      incident['description'] ?? 'No description provided.',
                      style: GoogleFonts.dmSans(color: AppTheme.navy),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 16, color: AppTheme.mutedText),
                            const SizedBox(width: 4),
                            Text(prop, style: GoogleFonts.dmSans(color: AppTheme.mutedText, fontSize: 12)),
                          ],
                        ),
                        Row(
                          children: [
                            const Icon(Icons.person_outline, size: 16, color: AppTheme.mutedText),
                            const SizedBox(width: 4),
                            Text(reporter, style: GoogleFonts.dmSans(color: AppTheme.mutedText, fontSize: 12)),
                          ],
                        ),
                        Text(dateFmt, style: GoogleFonts.dmSans(color: AppTheme.mutedText, fontSize: 12)),
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

class _ReportIncidentDialog extends StatefulWidget {
  const _ReportIncidentDialog();

  @override
  State<_ReportIncidentDialog> createState() => _ReportIncidentDialogState();
}

class _ReportIncidentDialogState extends State<_ReportIncidentDialog> {
  final ApiService _api = ApiService();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _severity = 'MEDIUM';
  String? _selectedPropertyId;
  List<dynamic> _properties = [];
  bool _isLoadingProps = true;
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProperties();
  }

  Future<void> _loadProperties() async {
    try {
      final res = await _api.getProperties(limit: 100);
      if (mounted) {
        setState(() {
          _properties = ApiService.extractList(res);
          if (_properties.isNotEmpty) _selectedPropertyId = _properties.first['id'].toString();
          _isLoadingProps = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingProps = false);
    }
  }

  Future<void> _submit() async {
    if (_titleCtrl.text.isEmpty || _selectedPropertyId == null) {
      setState(() => _error = 'Title and Property are required');
      return;
    }
    setState(() { _isSubmitting = true; _error = null; });
    try {
      await _api.createIncident({
        'title': _titleCtrl.text,
        'description': _descCtrl.text,
        'severity': _severity,
        'property_id': int.parse(_selectedPropertyId!),
      });
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() { _error = e.toString(); _isSubmitting = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Log New Incident', style: GoogleFonts.bricolageGrotesque(fontWeight: FontWeight.w600)),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_error != null) ...[
                Text(_error!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 8),
              ],
              TextField(
                controller: _titleCtrl,
                decoration: const InputDecoration(labelText: 'Incident Title', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descCtrl,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              if (_isLoadingProps) const CircularProgressIndicator()
              else DropdownButtonFormField<String>(
                value: _selectedPropertyId,
                decoration: const InputDecoration(labelText: 'Property', border: OutlineInputBorder()),
                items: _properties.map((p) => DropdownMenuItem(value: p['id'].toString(), child: Text(p['name']))).toList(),
                onChanged: (v) => setState(() => _selectedPropertyId = v),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _severity,
                decoration: const InputDecoration(labelText: 'Severity', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'LOW', child: Text('Low')),
                  DropdownMenuItem(value: 'MEDIUM', child: Text('Medium')),
                  DropdownMenuItem(value: 'HIGH', child: Text('High')),
                  DropdownMenuItem(value: 'CRITICAL', child: Text('Critical')),
                ],
                onChanged: (v) => setState(() => _severity = v!),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Photo upload placeholder')));
                },
                icon: const Icon(Icons.add_a_photo_outlined),
                label: const Text('Attach Photos'),
              )
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.teal, foregroundColor: Colors.white),
          child: _isSubmitting ? const CircularProgressIndicator() : const Text('Submit'),
        ),
      ],
    );
  }
}
