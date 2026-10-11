import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class HowItWorksSection extends StatelessWidget {
  const HowItWorksSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 100, horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            children: [
              Text(
                'Get your property operation under control in four steps.',
                textAlign: TextAlign.center,
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 40,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.navy,
                ),
              ),
              const SizedBox(height: 80),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isMobile = constraints.maxWidth < 768;
                  return Column(
                    children: [
                      _buildStep(
                        '01',
                        'Add your properties',
                        'Create your portfolio and configure properties and units.',
                        isMobile,
                      ),
                      _buildDivider(isMobile),
                      _buildStep(
                        '02',
                        'Add your tenants',
                        'Connect tenants, leases, and property relationships.',
                        isMobile,
                      ),
                      _buildDivider(isMobile),
                      _buildStep(
                        '03',
                        'Run your operations',
                        'Manage rent, payments, maintenance, inspections, documents, and communication.',
                        isMobile,
                      ),
                      _buildDivider(isMobile),
                      _buildStep(
                        '04',
                        'See everything',
                        'Use dashboards, reports, notifications, and activity tracking to stay informed.',
                        isMobile,
                      ),
                    ],
                  );
                }
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep(String number, String title, String description, bool isMobile) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          number,
          style: GoogleFonts.bricolageGrotesque(
            fontSize: isMobile ? 32 : 48,
            fontWeight: FontWeight.w800,
            color: AppTheme.teal.withValues(alpha: 0.2),
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.navy,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 18,
                  color: AppTheme.mutedText,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDivider(bool isMobile) {
    return Padding(
      padding: EdgeInsets.only(left: isMobile ? 16 : 24, top: 32, bottom: 32),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          width: 2,
          height: 40,
          color: AppTheme.border,
        ),
      ),
    );
  }
}
