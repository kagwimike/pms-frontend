import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../config.dart';
import '../theme/app_theme.dart';

class TenantsScreen extends StatefulWidget {
  const TenantsScreen({super.key});

  @override
  State<TenantsScreen> createState() => _TenantsScreenState();
}

class _TenantsScreenState extends State<TenantsScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  List<dynamic> _tenants = [];
  String? _error;
  String _roleFilter = 'TENANT';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final res = await _api.getUsers(limit: 100);
      final all = ApiService.extractList(res);
      setState(() {
        if (_roleFilter == 'ALL') {
          _tenants = all.where((u) => u['role'] == 'TENANT' || u['role'] == 'FORMER_TENANT').toList();
        } else {
          _tenants = all.where((u) => u['role'] == _roleFilter).toList();
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  void _showAddTenantDialog() {
    showDialog(
      context: context,
      builder: (context) => const AddTenantDialog(),
    ).then((result) {
      if (result == true) {
        _load();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Tenants', style: GoogleFonts.bricolageGrotesque(fontSize: 26, fontWeight: FontWeight.w700, color: AppTheme.navy)),
                const SizedBox(height: 4),
                Text('Manage tenant profiles and assignments', style: GoogleFonts.dmSans(fontSize: 14, color: AppTheme.mutedText)),
              ]),
              ElevatedButton.icon(
                onPressed: _showAddTenantDialog,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Tenant'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(children: [
            _chip('TENANT', 'Active Tenants'),
            const SizedBox(width: 8),
            _chip('FORMER_TENANT', 'Former Tenants'),
            const SizedBox(width: 8),
            _chip('ALL', 'All'),
          ]),
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
                    : _tenants.isEmpty
                        ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Icon(Icons.people_outline, size: 64, color: AppTheme.mutedText.withValues(alpha: 0.3)),
                            const SizedBox(height: 16),
                            Text('No tenants found', style: GoogleFonts.bricolageGrotesque(fontSize: 20, color: AppTheme.navy)),
                            const SizedBox(height: 8),
                            Text('Tenants register via the app and appear here once assigned.', style: GoogleFonts.dmSans(color: AppTheme.mutedText)),
                          ]))
                        : ListView.builder(
                            itemCount: _tenants.length,
                            itemBuilder: (ctx, i) => _TenantRow(
                              tenant: _tenants[i],
                              onArchive: () => _archiveTenant(_tenants[i]),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String value, String label) {
    final sel = _roleFilter == value;
    return FilterChip(
      selected: sel,
      label: Text(label),
      labelStyle: GoogleFonts.dmSans(color: sel ? Colors.white : AppTheme.navy, fontWeight: sel ? FontWeight.w600 : FontWeight.w400),
      backgroundColor: Colors.white,
      selectedColor: AppTheme.navy,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: sel ? AppTheme.navy : AppTheme.border)),
      onSelected: (s) { if (s) { setState(() => _roleFilter = value); _load(); } },
    );
  }

  Future<void> _archiveTenant(Map<String, dynamic> tenant) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Archive Tenant?', style: GoogleFonts.bricolageGrotesque(fontWeight: FontWeight.w700, color: AppTheme.navy)),
        content: Text(
          'This will move ${tenant['username']} to FORMER_TENANT status. This cannot be reversed easily.',
          style: GoogleFonts.dmSans(),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
            child: const Text('Archive'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final auth = AuthService();
      final headers = {
        'Content-Type': 'application/json',
        if (auth.accessToken != null) 'Authorization': 'Bearer ${auth.accessToken}',
      };
      final res = await http.patch(
        Uri.parse('${AppConfig.apiBaseUrl}/users/${tenant['id']}/archive'),
        headers: headers,
      );
      if (res.statusCode >= 200 && res.statusCode < 300) {
        _load();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${tenant['username']} archived successfully'), backgroundColor: Colors.green),
          );
        }
      } else {
        final body = jsonDecode(res.body);
        throw Exception(body['message'] ?? 'Failed to archive');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red));
      }
    }
  }
}

class _TenantRow extends StatelessWidget {
  final Map<String, dynamic> tenant;
  final VoidCallback onArchive;

  const _TenantRow({required this.tenant, required this.onArchive});

  @override
  Widget build(BuildContext context) {
    final role = tenant['role'] ?? 'UNKNOWN';
    final isActive = role == 'TENANT';
    final name = '${tenant['first_name'] ?? ''} ${tenant['last_name'] ?? ''}'.trim();
    final displayName = name.isNotEmpty ? name : (tenant['username'] ?? 'Unknown');
    final initials = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: isActive ? AppTheme.teal.withValues(alpha: 0.15) : Colors.grey.withValues(alpha: 0.15),
              child: Text(initials, style: GoogleFonts.bricolageGrotesque(fontWeight: FontWeight.w700, color: isActive ? AppTheme.teal : Colors.grey)),
            ),
            const SizedBox(width: 16),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(displayName, style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.navy)),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.email_outlined, size: 14, color: AppTheme.mutedText),
                  const SizedBox(width: 4),
                  Text(tenant['email'] ?? '', style: GoogleFonts.dmSans(fontSize: 13, color: AppTheme.mutedText)),
                  const SizedBox(width: 16),
                  if (tenant['phone'] != null) ...[
                    const Icon(Icons.phone_outlined, size: 14, color: AppTheme.mutedText),
                    const SizedBox(width: 4),
                    Text(tenant['phone'], style: GoogleFonts.dmSans(fontSize: 13, color: AppTheme.mutedText)),
                  ],
                ]),
              ],
            )),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isActive ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                role,
                style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w700, color: isActive ? Colors.green.shade700 : Colors.orange.shade700),
              ),
            ),
            if (isActive) ...[
              const SizedBox(width: 12),
              IconButton(
                icon: Icon(Icons.archive_outlined, color: Colors.orange.shade700, size: 20),
                tooltip: 'Archive Tenant',
                onPressed: onArchive,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class AddTenantDialog extends StatefulWidget {
  const AddTenantDialog({super.key});

  @override
  State<AddTenantDialog> createState() => _AddTenantDialogState();
}

class _AddTenantDialogState extends State<AddTenantDialog> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _idPassportController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _citizenshipController = TextEditingController();
  String _gender = 'PREFER_NOT_TO_SAY';
  
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _idPassportController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _citizenshipController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() { _isSubmitting = true; _error = null; });

    try {
      final email = _emailController.text.trim();
      final username = email.split('@')[0] + DateTime.now().millisecondsSinceEpoch.toString().substring(8);
      
      final data = {
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'email': email,
        'username': username,
        'password': 'DefaultPassword123!', // Required by backend for auth register
        'tenant_id_passport': _idPassportController.text.trim(),
        'phone': _phoneController.text.trim(),
        'citizenship': _citizenshipController.text.trim(),
        'gender': _gender,
      };

      await ApiService().createTenant(data);
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

    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: isSmall ? 12 : 40, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(28.0),
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
                      Text('Add Tenant', style: GoogleFonts.bricolageGrotesque(fontSize: 22, fontWeight: FontWeight.w700, color: AppTheme.navy)),
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
                  Row(
                    children: [
                      Expanded(child: TextFormField(controller: _firstNameController, decoration: _inputDecoration('First Name'), validator: (v) => v!.isEmpty ? 'Required' : null)),
                      const SizedBox(width: 12),
                      Expanded(child: TextFormField(controller: _lastNameController, decoration: _inputDecoration('Last Name'), validator: (v) => v!.isEmpty ? 'Required' : null)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(controller: _idPassportController, decoration: _inputDecoration('Tenant ID or Passport'), validator: (v) => v!.isEmpty ? 'Required' : null),
                  const SizedBox(height: 12),
                  TextFormField(controller: _emailController, decoration: _inputDecoration('Email Address'), keyboardType: TextInputType.emailAddress, validator: (v) => !v!.contains('@') ? 'Invalid email' : null),
                  const SizedBox(height: 12),
                  TextFormField(controller: _phoneController, decoration: _inputDecoration('Phone Number'), keyboardType: TextInputType.phone, validator: (v) => v!.isEmpty ? 'Required' : null),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: TextFormField(controller: _citizenshipController, decoration: _inputDecoration('Citizenship'), validator: (v) => v!.isEmpty ? 'Required' : null)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _gender,
                          decoration: _inputDecoration('Gender'),
                          items: const [
                            DropdownMenuItem(value: 'MALE', child: Text('Male')),
                            DropdownMenuItem(value: 'FEMALE', child: Text('Female')),
                            DropdownMenuItem(value: 'OTHER', child: Text('Other')),
                            DropdownMenuItem(value: 'PREFER_NOT_TO_SAY', child: Text('Prefer not to say')),
                          ],
                          onChanged: (v) => setState(() => _gender = v!),
                        ),
                      ),
                    ],
                  ),
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
                          : const Text('ADD TENANT', style: TextStyle(fontWeight: FontWeight.bold)),
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

