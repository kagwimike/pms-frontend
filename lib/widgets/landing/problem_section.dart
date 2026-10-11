import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class ProblemSection extends StatelessWidget {
  const ProblemSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppTheme.bgGreyGreen,
      padding: const EdgeInsets.symmetric(vertical: 100, horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              Text(
                'Property management shouldn\'t be this complicated.',
                textAlign: TextAlign.center,
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 40,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.navy,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 64),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isMobile = constraints.maxWidth < 768;
                  return Wrap(
                    spacing: 32,
                    runSpacing: 32,
                    alignment: WrapAlignment.center,
                    children: [
                      _buildProblemCard(
                        Icons.description_outlined,
                        'Scattered information',
                        'Property data spread across spreadsheets, WhatsApp, and notebooks.',
                        isMobile ? constraints.maxWidth : (constraints.maxWidth - 64) / 3,
                      ),
                      _buildProblemCard(
                        Icons.payments_outlined,
                        'Rent tracking',
                        'Struggling to know who has paid, who owes, and what is outstanding.',
                        isMobile ? constraints.maxWidth : (constraints.maxWidth - 64) / 3,
                      ),
                      _buildProblemCard(
                        Icons.handyman_outlined,
                        'Maintenance chaos',
                        'Requests getting lost in a sea of messages and phone calls.',
                        isMobile ? constraints.maxWidth : (constraints.maxWidth - 64) / 3,
                      ),
                      _buildProblemCard(
                        Icons.chat_bubble_outline,
                        'Poor communication',
                        'Owners, tenants, caretakers, and vendors operating in disconnected channels.',
                        isMobile ? constraints.maxWidth : (constraints.maxWidth - 32) / 2,
                      ),
                      _buildProblemCard(
                        Icons.analytics_outlined,
                        'Manual reporting',
                        'Managers spending hours compiling simple performance reports.',
                        isMobile ? constraints.maxWidth : (constraints.maxWidth - 32) / 2,
                      ),
                    ],
                  );
                }
              ),
              const SizedBox(height: 80),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 48),
                decoration: BoxDecoration(
                  color: AppTheme.teal,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  'PMS Pro brings everything together.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.bricolageGrotesque(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProblemCard(IconData icon, String title, String description, double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.red.shade700, size: 28),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.navy,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: const TextStyle(
              fontSize: 16,
              color: AppTheme.mutedText,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
