import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';

class SecurityAuditSettingsSection extends StatefulWidget {
  final Map<String, dynamic> securityConfig;
  final VoidCallback onSaved;

  const SecurityAuditSettingsSection({
    super.key,
    required this.securityConfig,
    required this.onSaved,
  });

  @override
  State<SecurityAuditSettingsSection> createState() => _SecurityAuditSettingsSectionState();
}

class _SecurityAuditSettingsSectionState extends State<SecurityAuditSettingsSection> {
  final _passwordFormKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isChangingPassword = false;
  String? _passwordError;
  String? _passwordSuccess;

  List<dynamic> _recentAuditLogs = [];
  bool _isLoadingLogs = true;

  @override
  void initState() {
    super.initState();
    _fetchAuditLogs();
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _fetchAuditLogs() async {
    try {
      final res = await ApiService().getAuditLogs(limit: 5);
      final logs = ApiService.extractList(res);
      setState(() {
        _recentAuditLogs = logs;
        _isLoadingLogs = false;
      });
    } catch (e) {
      setState(() => _isLoadingLogs = false);
    }
  }

  Future<void> _changePassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;
    if (_newPasswordController.text != _confirmPasswordController.text) {
      setState(() => _passwordError = 'New passwords do not match');
      return;
    }

    setState(() {
      _isChangingPassword = true;
      _passwordError = null;
      _passwordSuccess = null;
    });

    try {
      await ApiService().changePassword(
        _currentPasswordController.text.trim(),
        _newPasswordController.text.trim(),
      );
      setState(() {
        _isChangingPassword = false;
        _passwordSuccess = 'Password changed successfully!';
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      });
      _fetchAuditLogs();
    } catch (e) {
      setState(() {
        _isChangingPassword = false;
        _passwordError = e.toString();
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

    return Column(
      children: [
        // Password Change Card
        Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _passwordFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.lock_reset_outlined, color: Colors.red, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Security & Password Management',
                            style: GoogleFonts.bricolageGrotesque(fontSize: 18, fontWeight: FontWeight.w700, color: textColor)),
                        Text('Update your credentials and maintain account security',
                            style: GoogleFonts.dmSans(fontSize: 13, color: muted)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 16),

                if (_passwordSuccess != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                    child: Text(_passwordSuccess!, style: const TextStyle(color: Colors.green)),
                  ),
                if (_passwordError != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                    child: Text(_passwordError!, style: const TextStyle(color: Colors.red)),
                  ),

                TextFormField(
                  controller: _currentPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Current Password', border: OutlineInputBorder()),
                  validator: (v) => v!.isEmpty ? 'Current password required' : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _newPasswordController,
                        obscureText: true,
                        decoration: const InputDecoration(labelText: 'New Password', border: OutlineInputBorder()),
                        validator: (v) => v!.length < 6 ? 'Minimum 6 characters' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: true,
                        decoration: const InputDecoration(labelText: 'Confirm New Password', border: OutlineInputBorder()),
                        validator: (v) => v!.isEmpty ? 'Confirm password' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: _isChangingPassword ? null : _changePassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: _isChangingPassword
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.shield_outlined, size: 18),
                    label: Text(_isChangingPassword ? 'Updating...' : 'Update Password'),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Recent Audit Trail Card
        Container(
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
                    child: const Icon(Icons.history_edu_outlined, color: AppTheme.teal, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('System Audit Trail',
                            style: GoogleFonts.bricolageGrotesque(fontSize: 18, fontWeight: FontWeight.w700, color: textColor)),
                        Text('Immutable log of security and configuration changes',
                            style: GoogleFonts.dmSans(fontSize: 13, color: muted)),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      if (_isLoadingLogs) return;
                      if (_recentAuditLogs.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('No logs available'),
                            behavior: SnackBarBehavior.floating,
                            duration: Duration(seconds: 2),
                          ),
                        );
                        return;
                      }
                      context.push('/auditlogs');
                    },
                    icon: const Icon(Icons.open_in_new, size: 14),
                    label: const Text('View All Logs', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.teal,
                      side: const BorderSide(color: AppTheme.teal),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),

              if (_isLoadingLogs)
                const Center(child: CircularProgressIndicator(color: AppTheme.teal))
              else if (_recentAuditLogs.isEmpty)
                Text('No logs available', style: TextStyle(color: muted, fontSize: 13))
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _recentAuditLogs.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, idx) {
                    final item = _recentAuditLogs[idx];
                    final action = (item['action'] ?? 'ACTION').toString().toUpperCase();
                    final isLogin = action.contains('LOGIN') || action.contains('SIGNIN');
                    final isFailure = item['outcome'] == 'FAILURE' || action.contains('FAIL');

                    final createdAtRaw = item['created_at']?.toString();
                    final createdAt = createdAtRaw != null ? DateTime.tryParse(createdAtRaw)?.toLocal() : null;
                    final dateStr = createdAt != null ? DateFormat('MMM d, yyyy').format(createdAt) : '';
                    final timeStr = createdAt != null ? DateFormat('hh:mm:ss a').format(createdAt) : '';

                    final IconData iconData;
                    final Color iconColor;
                    if (isLogin) {
                      iconData = isFailure ? Icons.no_accounts_outlined : Icons.login_rounded;
                      iconColor = isFailure ? Colors.red.shade700 : AppTheme.teal;
                    } else if (isFailure) {
                      iconData = Icons.error_outline_rounded;
                      iconColor = Colors.red.shade700;
                    } else if (action.contains('LOGOUT')) {
                      iconData = Icons.logout_rounded;
                      iconColor = Colors.orange.shade700;
                    } else {
                      iconData = Icons.verified_user_outlined;
                      iconColor = AppTheme.teal;
                    }

                    final summary = item['summary']?.toString();
                    final title = summary != null && summary.isNotEmpty
                        ? summary
                        : '$action • ${item['entity_type'] ?? 'SYSTEM'}';

                    final actorName = item['user']?['username'] ?? 'System';
                    final actorRole = item['actor_role'] ?? item['user']?['role'] ?? 'USER';
                    final ip = item['ip_address'] ?? '127.0.0.1';

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      onTap: () => context.push('/auditlogs'),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: iconColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(iconData, color: iconColor, size: 20),
                      ),
                      title: Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        'By $actorName ($actorRole) • IP: $ip',
                        style: TextStyle(color: muted, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: createdAt != null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  dateStr,
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textColor),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.access_time_rounded, size: 10, color: isLogin ? AppTheme.teal : muted),
                                    const SizedBox(width: 3),
                                    Text(
                                      timeStr,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: isLogin ? AppTheme.teal : muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            )
                          : null,
                    );
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }
}
