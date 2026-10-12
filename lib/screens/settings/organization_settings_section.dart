import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';

class OrganizationSettingsSection extends StatefulWidget {
  final Map<String, dynamic> initialConfig;
  final VoidCallback onSaved;

  const OrganizationSettingsSection({
    super.key,
    required this.initialConfig,
    required this.onSaved,
  });

  @override
  State<OrganizationSettingsSection> createState() => _OrganizationSettingsSectionState();
}

class _OrganizationSettingsSectionState extends State<OrganizationSettingsSection> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _legalNameController;
  late TextEditingController _regController;
  late TextEditingController _taxPinController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  String _currency = 'KES';
  String _timezone = 'Africa/Nairobi';

  bool _isSaving = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    final c = widget.initialConfig;
    _nameController = TextEditingController(text: c['name'] ?? 'PMS Pro Real Estate');
    _legalNameController = TextEditingController(text: c['legal_name'] ?? '');
    _regController = TextEditingController(text: c['registration_number'] ?? '');
    _taxPinController = TextEditingController(text: c['tax_pin'] ?? '');
    _emailController = TextEditingController(text: c['email'] ?? '');
    _phoneController = TextEditingController(text: c['phone'] ?? '');
    _addressController = TextEditingController(text: c['address'] ?? '');
    _cityController = TextEditingController(text: c['city'] ?? 'Nairobi');
    _currency = c['currency'] ?? 'KES';
    _timezone = c['timezone'] ?? 'Africa/Nairobi';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _legalNameController.dispose();
    _regController.dispose();
    _taxPinController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _saveOrgSettings() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSaving = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      await ApiService().updateSettings('ORGANIZATION', {
        'scope': 'GLOBAL',
        'value': {
          'name': _nameController.text.trim(),
          'legal_name': _legalNameController.text.trim(),
          'registration_number': _regController.text.trim(),
          'tax_pin': _taxPinController.text.trim(),
          'email': _emailController.text.trim(),
          'phone': _phoneController.text.trim(),
          'address': _addressController.text.trim(),
          'city': _cityController.text.trim(),
          'currency': _currency,
          'timezone': _timezone,
        },
      });

      setState(() {
        _isSaving = false;
        _successMessage = 'Organization settings saved successfully!';
      });
      widget.onSaved();
    } catch (e) {
      setState(() {
        _isSaving = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderColor = isDark ? const Color(0xFF27272A) : AppTheme.border;
    final textColor = isDark ? Colors.white : AppTheme.navy;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.teal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.business_outlined, color: AppTheme.teal, size: 22),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Organization & Agency Identity',
                        style: GoogleFonts.bricolageGrotesque(fontSize: 18, fontWeight: FontWeight.w700, color: textColor)),
                    Text('Legal business details, default currency, time zone and branding',
                        style: GoogleFonts.dmSans(fontSize: 13, color: isDark ? AppTheme.darkMutedText : AppTheme.mutedText)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 16),

            if (_successMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(_successMessage!, style: const TextStyle(color: Colors.green)),
              ),
            if (_errorMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
              ),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Organization / Brand Name', border: OutlineInputBorder()),
                    validator: (v) => v!.isEmpty ? 'Name required' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _legalNameController,
                    decoration: const InputDecoration(labelText: 'Legal Entity Name', border: OutlineInputBorder()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _regController,
                    decoration: const InputDecoration(labelText: 'Registration / Certificate No.', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _taxPinController,
                    decoration: const InputDecoration(labelText: 'Tax PIN (KRA PIN)', border: OutlineInputBorder()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Official Email', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(labelText: 'Official Phone', border: OutlineInputBorder()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(labelText: 'Physical Address', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _currency,
                    decoration: const InputDecoration(labelText: 'Default Currency', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'KES', child: Text('KES (Kenyan Shilling)')),
                      DropdownMenuItem(value: 'USD', child: Text('USD (US Dollar)')),
                      DropdownMenuItem(value: 'EUR', child: Text('EUR (Euro)')),
                      DropdownMenuItem(value: 'GBP', child: Text('GBP (British Pound)')),
                    ],
                    onChanged: (v) => setState(() => _currency = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveOrgSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: _isSaving
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.check, size: 18),
                label: Text(_isSaving ? 'Saving...' : 'Save Organization Details'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
