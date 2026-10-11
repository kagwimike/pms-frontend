import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class TrustSection extends StatelessWidget {
  const TrustSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
      child: Column(
        children: [
          Text(
            'Built for the people who keep properties running.',
            textAlign: TextAlign.center,
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: AppTheme.navy,
            ),
          ),
          const SizedBox(height: 48),
          Wrap(
            spacing: 32,
            runSpacing: 32,
            alignment: WrapAlignment.center,
            children: [
              _buildTrustBadge(Icons.business_center_rounded, 'Property Managers'),
              _buildTrustBadge(Icons.real_estate_agent_rounded, 'Property Owners'),
              _buildTrustBadge(Icons.house_rounded, 'Landlords'),
              _buildTrustBadge(Icons.admin_panel_settings_rounded, 'Caretakers'),
              _buildTrustBadge(Icons.people_alt_rounded, 'Tenants'),
              _buildTrustBadge(Icons.handyman_rounded, 'Maintenance Vendors'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrustBadge(IconData icon, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.bgGreyGreen,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: AppTheme.teal, size: 32),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: AppTheme.navy,
          ),
        ),
      ],
    );
  }
}
