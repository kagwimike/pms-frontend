import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class SecuritySection extends StatelessWidget {
  const SecuritySection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppTheme.navy,
      padding: const EdgeInsets.symmetric(vertical: 100, horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            children: [
              const Icon(Icons.shield_rounded, color: AppTheme.teal, size: 64),
              const SizedBox(height: 24),
              Text(
                'Your property data deserves a secure home.',
                textAlign: TextAlign.center,
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 40,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 64),
              Wrap(
                spacing: 32,
                runSpacing: 32,
                alignment: WrapAlignment.center,
                children: [
                  _buildSecurityItem(Icons.key_rounded, 'Authentication', 'Secure user authentication and session management.'),
                  _buildSecurityItem(Icons.admin_panel_settings_rounded, 'Role-based access', 'Strict permissions ensuring users only see what they should.'),
                  _buildSecurityItem(Icons.lock_rounded, 'Secure API', 'Encrypted data transmission across all communications.'),
                  _buildSecurityItem(Icons.history_rounded, 'Activity tracking', 'Comprehensive audit logs of important system actions.'),
                  _buildSecurityItem(Icons.folder_shared_rounded, 'Data organization', 'Complete separation of property portfolios.'),
                  _buildSecurityItem(Icons.visibility_off_rounded, 'Controlled permissions', 'Granular control over who can edit financial and tenant data.'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSecurityItem(IconData icon, String title, String description) {
    return SizedBox(
      width: 300,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.7),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
