import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';

class IntegrationsSettingsSection extends StatefulWidget {
  final Map<String, dynamic> integrationsConfig;
  final VoidCallback onSaved;

  const IntegrationsSettingsSection({
    super.key,
    required this.integrationsConfig,
    required this.onSaved,
  });

  @override
  State<IntegrationsSettingsSection> createState() => _IntegrationsSettingsSectionState();
}

class _IntegrationsSettingsSectionState extends State<IntegrationsSettingsSection> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderColor = isDark ? const Color(0xFF27272A) : AppTheme.border;
    final textColor = isDark ? Colors.white : AppTheme.navy;
    final muted = isDark ? AppTheme.darkMutedText : AppTheme.mutedText;

    final mpesaConfigured = widget.integrationsConfig['mpesa_configured'] == true;
    final bankConfigured = widget.integrationsConfig['bank_configured'] == true;

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
                child: const Icon(Icons.hub_outlined, color: AppTheme.teal, size: 22),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Third-Party Integrations',
                      style: GoogleFonts.bricolageGrotesque(fontSize: 18, fontWeight: FontWeight.w700, color: textColor)),
                  Text('Real backend gateway connections, payment processors and notifications',
                      style: GoogleFonts.dmSans(fontSize: 13, color: muted)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 16),

          // M-Pesa Integration Card
          _buildGatewayCard(
            title: 'Safaricom M-Pesa (Daraja API)',
            subtitle: 'Lipa Na M-Pesa Online (STK Push) & C2B Paybill Ingestion',
            icon: Icons.phone_android,
            iconColor: Colors.green,
            isConfigured: mpesaConfigured,
            details: [
              'Environment: ${widget.integrationsConfig['mpesa_env'] ?? 'sandbox'}',
              'Shortcode: ${widget.integrationsConfig['mpesa_shortcode'] ?? 'Not set'}',
              'Secret Key: ********',
            ],
            isDark: isDark,
            borderColor: borderColor,
          ),
          const SizedBox(height: 16),

          // Bank Integration Card
          _buildGatewayCard(
            title: 'Bank Transfer & Webhook Gateway',
            subtitle: 'Automated bank notification reconciliation with HMAC verification',
            icon: Icons.account_balance,
            iconColor: AppTheme.teal,
            isConfigured: bankConfigured,
            details: [
              'Provider: ${widget.integrationsConfig['bank_name'] ?? 'Bank'}',
              'Webhook Status: ${bankConfigured ? 'Active' : 'Unconfigured'}',
            ],
            isDark: isDark,
            borderColor: borderColor,
          ),
          const SizedBox(height: 16),

          // SMS Gateway Card
          _buildGatewayCard(
            title: 'SMS Gateway (Africa\'s Talking)',
            subtitle: 'Automated SMS delivery for payment receipts and rent reminders',
            icon: Icons.sms_outlined,
            iconColor: Colors.orange,
            isConfigured: true,
            details: [
              'Sender ID: PMSPRO',
              'Status: Operational',
            ],
            isDark: isDark,
            borderColor: borderColor,
          ),
        ],
      ),
    );
  }

  Widget _buildGatewayCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool isConfigured,
    required List<String> details,
    required bool isDark,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF27272A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    Text(subtitle, style: TextStyle(fontSize: 12, color: isDark ? AppTheme.darkMutedText : AppTheme.mutedText)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isConfigured ? Colors.green.withValues(alpha: 0.1) : Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isConfigured ? Colors.green : Colors.amber),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isConfigured ? Icons.check_circle : Icons.warning_amber_rounded,
                      size: 14,
                      color: isConfigured ? Colors.green : Colors.amber,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isConfigured ? 'CONNECTED' : 'STANDBY',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isConfigured ? Colors.green : Colors.amber[800],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 6),
          ...details.map((d) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text('• $d', style: TextStyle(fontSize: 12, color: isDark ? AppTheme.darkMutedText : AppTheme.mutedText)),
              )),
        ],
      ),
    );
  }
}
