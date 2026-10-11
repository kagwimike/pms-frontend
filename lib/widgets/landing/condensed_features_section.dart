import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class CondensedFeaturesSection extends StatelessWidget {
  const CondensedFeaturesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              Text(
                'Everything you need to manage your properties.',
                textAlign: TextAlign.center,
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.navy,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'A single platform for rent, tenants, maintenance, and communication.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: AppTheme.mutedText),
              ),
              const SizedBox(height: 64),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isMobile = constraints.maxWidth < 768;
                  final double cardWidth = isMobile ? constraints.maxWidth : (constraints.maxWidth - 32) / 2;

                  return Wrap(
                    spacing: 32,
                    runSpacing: 32,
                    children: [
                      _buildFeatureCard(
                        width: cardWidth,
                        title: 'Property & Tenants',
                        description: 'Manage your portfolio, units, and tenant leases in one organized directory.',
                        imagePath: 'assets/images/feature_properties.jpg',
                        icon: Icons.business_center_rounded,
                      ),
                      _buildFeatureCard(
                        width: cardWidth,
                        title: 'Rent & Finance',
                        description: 'Automate rent tracking, invoicing, and generate financial reports instantly.',
                        imagePath: 'assets/images/feature_finance.jpg',
                        icon: Icons.account_balance_wallet_rounded,
                      ),
                      _buildFeatureCard(
                        width: cardWidth,
                        title: 'Maintenance',
                        description: 'Track repairs from tenant request to vendor completion with ease.',
                        imagePath: 'assets/images/feature_maintenance.jpg',
                        icon: Icons.handyman_rounded,
                      ),
                      _buildFeatureCard(
                        width: cardWidth,
                        title: 'Communication',
                        description: 'Keep all property-related conversations and notifications in one place.',
                        imagePath: 'assets/images/communication_ui.jpg',
                        icon: Icons.forum_rounded,
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required double width,
    required String title,
    required String description,
    required String imagePath,
    required IconData icon,
  }) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: AppTheme.bgGreyGreen,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              image: DecorationImage(
                image: AssetImage(imagePath),
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: AppTheme.teal, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.navy,
                      ),
                    ),
                  ],
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
          ),
        ],
      ),
    );
  }
}
