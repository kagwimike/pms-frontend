import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';

class NotificationsSettingsSection extends StatefulWidget {
  final Map<String, dynamic> notificationsConfig;
  final VoidCallback onSaved;

  const NotificationsSettingsSection({
    super.key,
    required this.notificationsConfig,
    required this.onSaved,
  });

  @override
  State<NotificationsSettingsSection> createState() => _NotificationsSettingsSectionState();
}

class _NotificationsSettingsSectionState extends State<NotificationsSettingsSection> {
  late bool _emailEnabled;
  late bool _smsEnabled;
  late bool _pushEnabled;
  late bool _sendPaymentReceipts;
  late bool _sendOverdueNotices;
  late bool _maintenanceStatusAlerts;
  late bool _inspectionNotifications;

  bool _isSaving = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    final n = widget.notificationsConfig;
    _emailEnabled = n['email_enabled'] ?? true;
    _smsEnabled = n['sms_enabled'] ?? true;
    _pushEnabled = n['push_enabled'] ?? true;
    _sendPaymentReceipts = n['send_payment_receipts'] ?? true;
    _sendOverdueNotices = n['send_overdue_notices'] ?? true;
    _maintenanceStatusAlerts = n['maintenance_status_alerts'] ?? true;
    _inspectionNotifications = n['inspection_notifications'] ?? true;
  }

  Future<void> _saveNotificationSettings() async {
    setState(() {
      _isSaving = true;
      _message = null;
    });

    try {
      await ApiService().updateSettings('NOTIFICATIONS', {
        'scope': 'GLOBAL',
        'value': {
          'email_enabled': _emailEnabled,
          'sms_enabled': _smsEnabled,
          'push_enabled': _pushEnabled,
          'send_payment_receipts': _sendPaymentReceipts,
          'send_overdue_notices': _sendOverdueNotices,
          'maintenance_status_alerts': _maintenanceStatusAlerts,
          'inspection_notifications': _inspectionNotifications,
        },
      });

      setState(() {
        _isSaving = false;
        _message = 'Notification preferences updated!';
      });
      widget.onSaved();
    } catch (e) {
      setState(() {
        _isSaving = false;
        _message = 'Failed to save: $e';
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
    final muted = isDark ? AppTheme.darkMutedText : AppTheme.mutedText;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      padding: const EdgeInsets.all(24),
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
                child: const Icon(Icons.notifications_active_outlined, color: AppTheme.teal, size: 22),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Notification & Automation Triggers',
                      style: GoogleFonts.bricolageGrotesque(fontSize: 18, fontWeight: FontWeight.w700, color: textColor)),
                  Text('Manage automated delivery channels and trigger rules',
                      style: GoogleFonts.dmSans(fontSize: 13, color: muted)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 12),

          if (_message != null)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.teal.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(_message!, style: const TextStyle(color: AppTheme.teal)),
            ),

          Text('Delivery Channels', style: TextStyle(fontWeight: FontWeight.w700, color: textColor)),
          SwitchListTile(
            title: const Text('Email Notifications'),
            subtitle: const Text('Send emails via configured SMTP/SendGrid delivery gateway'),
            value: _emailEnabled,
            activeColor: AppTheme.teal,
            onChanged: (v) => setState(() => _emailEnabled = v),
          ),
          SwitchListTile(
            title: const Text('SMS Text Alerts'),
            subtitle: const Text('Send SMS notices via Africa\'s Talking gateway for urgent alerts'),
            value: _smsEnabled,
            activeColor: AppTheme.teal,
            onChanged: (v) => setState(() => _smsEnabled = v),
          ),
          SwitchListTile(
            title: const Text('Push & In-App Notifications'),
            subtitle: const Text('Real-time alerts via WebSocket and Mobile notifications'),
            value: _pushEnabled,
            activeColor: AppTheme.teal,
            onChanged: (v) => setState(() => _pushEnabled = v),
          ),

          const SizedBox(height: 16),
          Text('Event Triggers', style: TextStyle(fontWeight: FontWeight.w700, color: textColor)),
          SwitchListTile(
            title: const Text('Automatic Payment Receipts'),
            subtitle: const Text('Issue instant receipt notifications upon verified M-Pesa or bank payments'),
            value: _sendPaymentReceipts,
            activeColor: AppTheme.teal,
            onChanged: (v) => setState(() => _sendPaymentReceipts = v),
          ),
          SwitchListTile(
            title: const Text('Overdue Rent Notices'),
            subtitle: const Text('Notify tenants when rent remains unpaid past grace period'),
            value: _sendOverdueNotices,
            activeColor: AppTheme.teal,
            onChanged: (v) => setState(() => _sendOverdueNotices = v),
          ),
          SwitchListTile(
            title: const Text('Maintenance & Work Order Updates'),
            subtitle: const Text('Alert relevant vendors and caretakers upon assignment'),
            value: _maintenanceStatusAlerts,
            activeColor: AppTheme.teal,
            onChanged: (v) => setState(() => _maintenanceStatusAlerts = v),
          ),
          SwitchListTile(
            title: const Text('Move-In/Move-Out Inspection Alerts'),
            subtitle: const Text('Send checklist completions and damage summaries to parties'),
            value: _inspectionNotifications,
            activeColor: AppTheme.teal,
            onChanged: (v) => setState(() => _inspectionNotifications = v),
          ),

          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveNotificationSettings,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: _isSaving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.check, size: 18),
              label: Text(_isSaving ? 'Saving...' : 'Save Notification Rules'),
            ),
          ),
        ],
      ),
    );
  }
}
