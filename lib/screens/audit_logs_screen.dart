import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class AuditLogsScreen extends StatefulWidget {
  const AuditLogsScreen({super.key});

  @override
  State<AuditLogsScreen> createState() => _AuditLogsScreenState();
}

class _AuditLogsScreenState extends State<AuditLogsScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchCtrl = TextEditingController();

  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;
  List<dynamic> _logs = [];
  String? _nextCursor;

  // Filter state
  String _selectedModule = 'ALL';
  String _selectedSeverity = 'ALL';
  String _selectedOutcome = 'ALL';

  final List<String> _modules = [
    'ALL',
    'AUTH',
    'LEASES',
    'FINANCE',
    'DOCUMENTS',
    'MAINTENANCE',
    'INSPECTIONS',
    'PROPERTIES',
    'SETTINGS',
    'SECURITY',
  ];

  @override
  void initState() {
    super.initState();
    _loadAuditLogs();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAuditLogs({bool loadMore = false}) async {
    if (loadMore) {
      if (_nextCursor == null || _isLoadingMore) return;
      setState(() => _isLoadingMore = true);
    } else {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final response = await _apiService.getAuditLogs(
        limit: 20,
        cursor: loadMore ? _nextCursor : null,
        module: _selectedModule == 'ALL' ? null : _selectedModule,
        severity: _selectedSeverity == 'ALL' ? null : _selectedSeverity,
        outcome: _selectedOutcome == 'ALL' ? null : _selectedOutcome,
        search: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
      );

      final newItems = ApiService.extractList(response);
      final meta = response['meta'] as Map<String, dynamic>?;
      final cursor = meta?['nextCursor']?.toString();

      setState(() {
        if (loadMore) {
          _logs.addAll(newItems);
        } else {
          _logs = newItems;
        }
        _nextCursor = cursor;
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _exportCsv() async {
    try {
      final exportUrl = _apiService.getAuditExportUrl(
        module: _selectedModule == 'ALL' ? null : _selectedModule,
        severity: _selectedSeverity == 'ALL' ? null : _selectedSeverity,
        outcome: _selectedOutcome == 'ALL' ? null : _selectedOutcome,
      );

      final uri = Uri.parse(exportUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Downloading audit trail CSV export...'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppTheme.teal,
            ),
          );
        }
      } else {
        throw 'Could not launch export URL';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export audit logs: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showEventDetails(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (context) => _AuditEventDetailsDialog(item: item),
    );
  }

  Color _getSeverityColor(String? severity) {
    switch (severity?.toUpperCase()) {
      case 'CRITICAL':
        return Colors.red.shade700;
      case 'WARNING':
        return Colors.orange.shade800;
      case 'INFO':
      default:
        return AppTheme.teal;
    }
  }

  Color _getOutcomeColor(String? outcome) {
    switch (outcome?.toUpperCase()) {
      case 'SUCCESS':
        return Colors.green.shade700;
      case 'DENIED':
        return Colors.deepOrange.shade700;
      case 'FAILURE':
      default:
        return Colors.red.shade700;
    }
  }

  IconData _getModuleIcon(String? module) {
    switch (module?.toUpperCase()) {
      case 'AUTH':
        return Icons.login_rounded;
      case 'LEASES':
        return Icons.vpn_key_outlined;
      case 'FINANCE':
        return Icons.payments_outlined;
      case 'DOCUMENTS':
        return Icons.description_outlined;
      case 'MAINTENANCE':
        return Icons.build_outlined;
      case 'INSPECTIONS':
        return Icons.fact_check_outlined;
      case 'PROPERTIES':
        return Icons.apartment_outlined;
      case 'SETTINGS':
        return Icons.settings_outlined;
      case 'SECURITY':
        return Icons.security_outlined;
      default:
        return Icons.history_edu_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2E2E2E) : Colors.grey.shade200;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Audit Logs', style: GoogleFonts.bricolageGrotesque(fontWeight: FontWeight.bold, fontSize: 20)),
            Text('Immutable activity trail and compliance records', style: GoogleFonts.dmSans(fontSize: 12, color: Colors.grey)),
          ],
        ),
        backgroundColor: cardBg,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => _loadAuditLogs(),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ElevatedButton.icon(
              onPressed: _exportCsv,
              icon: const Icon(Icons.download_rounded, size: 16),
              label: const Text('Export CSV'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter & Search bar
          Container(
            color: cardBg,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              children: [
                // Search row
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        decoration: InputDecoration(
                          hintText: 'Search by actor, action, summary, or resource...',
                          hintStyle: const TextStyle(fontSize: 13),
                          prefixIcon: const Icon(Icons.search, size: 20),
                          suffixIcon: _searchCtrl.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    _loadAuditLogs();
                                  },
                                )
                              : null,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderColor)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderColor)),
                          fillColor: isDark ? const Color(0xFF262626) : Colors.grey.shade50,
                          filled: true,
                        ),
                        onSubmitted: (_) => _loadAuditLogs(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _loadAuditLogs(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.navy,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Filter'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Filter dropdowns
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Module Filter
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF262626) : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: borderColor),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedModule,
                            isDense: true,
                            items: _modules.map((m) => DropdownMenuItem(value: m, child: Text('Module: $m', style: const TextStyle(fontSize: 12)))).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedModule = val);
                                _loadAuditLogs();
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Outcome Filter
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF262626) : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: borderColor),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedOutcome,
                            isDense: true,
                            items: ['ALL', 'SUCCESS', 'FAILURE', 'DENIED'].map((o) => DropdownMenuItem(value: o, child: Text('Outcome: $o', style: const TextStyle(fontSize: 12)))).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedOutcome = val);
                                _loadAuditLogs();
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Severity Filter
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF262626) : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: borderColor),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedSeverity,
                            isDense: true,
                            items: ['ALL', 'INFO', 'WARNING', 'CRITICAL'].map((s) => DropdownMenuItem(value: s, child: Text('Severity: $s', style: const TextStyle(fontSize: 12)))).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedSeverity = val);
                                _loadAuditLogs();
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Main audit event list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.teal))
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline_rounded, color: Colors.red, size: 48),
                              const SizedBox(height: 12),
                              Text('Failed to load audit trail: $_error', textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () => _loadAuditLogs(),
                                icon: const Icon(Icons.refresh),
                                label: const Text('Try Again'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _logs.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.history_toggle_off_rounded, size: 56, color: Colors.grey.shade400),
                                const SizedBox(height: 12),
                                Text('No logs available', style: GoogleFonts.bricolageGrotesque(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
                                const SizedBox(height: 4),
                                const Text('Try adjusting your search criteria or filters.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            color: AppTheme.teal,
                            onRefresh: () => _loadAuditLogs(),
                            child: ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: _logs.length + (_nextCursor != null ? 1 : 0),
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                if (index == _logs.length) {
                                  return Center(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                                      child: _isLoadingMore
                                          ? const CircularProgressIndicator(color: AppTheme.teal)
                                          : OutlinedButton(
                                              onPressed: () => _loadAuditLogs(loadMore: true),
                                              child: const Text('Load More Events'),
                                            ),
                                    ),
                                  );
                                }

                                final log = _logs[index] as Map<String, dynamic>;
                                final action = log['action'] ?? 'ACTION';
                                final entityType = log['entity_type'] ?? 'SYSTEM';
                                final entityId = log['entity_id'];
                                final module = log['module'] ?? 'SYSTEM';
                                final outcome = log['outcome'] ?? 'SUCCESS';
                                final severity = log['severity'] ?? 'INFO';
                                final summary = log['summary'] ?? '$action on $entityType';
                                final ip = log['ip_address'] ?? '127.0.0.1';
                                final user = log['user'] as Map<String, dynamic>?;
                                final actor = user?['username'] ?? 'System';
                                final actorRole = log['actor_role'] ?? user?['role'] ?? 'SYSTEM';
                                final createdAt = log['created_at'] != null ? DateTime.tryParse(log['created_at'].toString())?.toLocal() : null;
                                final dateStr = createdAt != null ? DateFormat('MMM dd, yyyy').format(createdAt) : '';
                                final timeStr = createdAt != null ? DateFormat('hh:mm:ss a').format(createdAt) : '';

                                return Card(
                                  elevation: 0,
                                  color: cardBg,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(color: borderColor),
                                  ),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () => _showEventDetails(log),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: _getSeverityColor(severity).withValues(alpha: 0.12),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Icon(_getModuleIcon(module), color: _getSeverityColor(severity), size: 18),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      '$action • $entityType${entityId != null ? ' #$entityId' : ''}',
                                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                                    ),
                                                    if (createdAt != null)
                                                      Padding(
                                                        padding: const EdgeInsets.only(top: 3.0),
                                                        child: Wrap(
                                                          crossAxisAlignment: WrapCrossAlignment.center,
                                                          spacing: 6,
                                                          runSpacing: 4,
                                                          children: [
                                                            Text(
                                                              dateStr,
                                                              style: TextStyle(color: Colors.grey.shade600, fontSize: 11, fontWeight: FontWeight.w500),
                                                            ),
                                                            Container(
                                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                              decoration: BoxDecoration(
                                                                color: AppTheme.teal.withValues(alpha: 0.1),
                                                                borderRadius: BorderRadius.circular(4),
                                                              ),
                                                              child: Row(
                                                                mainAxisSize: MainAxisSize.min,
                                                                children: [
                                                                  const Icon(Icons.access_time_rounded, size: 11, color: AppTheme.teal),
                                                                  const SizedBox(width: 3),
                                                                  Text(
                                                                    timeStr,
                                                                    style: const TextStyle(
                                                                      color: AppTheme.teal,
                                                                      fontSize: 10,
                                                                      fontWeight: FontWeight.bold,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                              // Outcome Badge
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: _getOutcomeColor(outcome).withValues(alpha: 0.12),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  outcome,
                                                  style: TextStyle(color: _getOutcomeColor(outcome), fontWeight: FontWeight.bold, fontSize: 11),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            summary,
                                            style: const TextStyle(fontSize: 13),
                                          ),
                                          const SizedBox(height: 10),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'Actor: $actor ($actorRole)  •  IP: $ip',
                                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                              ),
                                              const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _AuditEventDetailsDialog extends StatelessWidget {
  final Map<String, dynamic> item;
  const _AuditEventDetailsDialog({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2E2E2E) : Colors.grey.shade200;

    final user = item['user'] as Map<String, dynamic>?;
    final details = item['details'];
    final createdAt = item['created_at'] != null ? DateTime.tryParse(item['created_at'].toString())?.toLocal() : null;
    final localTimeStr = createdAt != null ? DateFormat('MMM dd, yyyy • hh:mm:ss a').format(createdAt) : 'N/A';
    final utcTimeStr = createdAt != null ? DateFormat('yyyy-MM-dd HH:mm:ss').format(createdAt.toUtc()) : 'N/A';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: cardBg,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.verified_user_outlined, color: AppTheme.teal, size: 24),
                      const SizedBox(width: 8),
                      Text('Audit Event #${item['id']}', style: GoogleFonts.bricolageGrotesque(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _row('Action', item['action'] ?? 'N/A'),
                      _row('Module', item['module'] ?? 'SYSTEM'),
                      _row('Outcome', item['outcome'] ?? 'SUCCESS'),
                      _row('Severity', item['severity'] ?? 'INFO'),
                      _row('Target Resource', '${item['entity_type']} ${item['entity_id'] != null ? '#${item['entity_id']}' : ''}'),
                      if (item['property_id'] != null) _row('Property Context', 'Property #${item['property_id']}'),
                      _row('Event Time (Local)', localTimeStr),
                      _row('Timestamp (UTC)', '$utcTimeStr UTC'),
                      _row('Actor', '${user?['username'] ?? 'System'} (Role: ${item['actor_role'] ?? user?['role'] ?? 'SYSTEM'})'),
                      _row('IP Address', item['ip_address'] ?? '127.0.0.1'),
                      if (item['request_id'] != null) _row('Request ID', item['request_id']),
                      _row('Summary', item['summary'] ?? 'N/A'),
                      const SizedBox(height: 16),
                      Text('Event Details & Diffs:', style: GoogleFonts.dmSans(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF141414) : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: borderColor),
                        ),
                        child: Text(
                          details != null ? const JsonEncoder.withIndent('  ').convert(details) : 'No change payload recorded.',
                          style: GoogleFonts.firaCode(fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.teal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.grey)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
