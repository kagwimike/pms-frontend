import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class FeaturesSection extends StatelessWidget {
  const FeaturesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 100, horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              _buildFeatureRow(
                context,
                title: 'Property Management',
                headline: 'Manage your entire portfolio from one place.',
                bullets: ['Properties', 'Units', 'Occupancy', 'Owners'],
                imagePath: 'assets/images/feature_properties.jpg',
                icon: Icons.business_center_rounded,
                isImageLeft: false,
              ),
              const SizedBox(height: 120),
              _buildFeatureRow(
                context,
                title: 'Rent & Payments',
                headline: 'Know exactly what has been billed, paid, and is outstanding.',
                bullets: ['Invoices', 'Receipts', 'Balances', 'Statements'],
                imagePath: 'assets/images/feature_finance.jpg',
                icon: Icons.account_balance_wallet_rounded,
                isImageLeft: true,
              ),
              const SizedBox(height: 120),
              _buildFeatureRow(
                context,
                title: 'Maintenance',
                headline: 'From maintenance request to resolution.',
                bullets: ['Reported', 'Assigned', 'In Progress', 'Completed'],
                imagePath: 'assets/images/feature_maintenance.jpg',
                icon: Icons.handyman_rounded,
                isImageLeft: false,
              ),
              const SizedBox(height: 120),
              _buildFeatureRow(
                context,
                title: 'Tenant Management',
                headline: 'Maintain complete tenant profiles and rental history.',
                bullets: ['Profiles', 'Leases', 'Payments', 'Documents'],
                imagePath: 'assets/images/feature_tenants.jpg',
                icon: Icons.people_alt_rounded,
                isImageLeft: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow(
    BuildContext context, {
    required String title,
    required String headline,
    required List<String> bullets,
    required String imagePath,
    required IconData icon,
    required bool isImageLeft,
  }) {
    final isMobile = MediaQuery.of(context).size.width < 900;

    final textContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppTheme.teal, size: 24),
            const SizedBox(width: 12),
            Text(
              title.toUpperCase(),
              style: const TextStyle(
                color: AppTheme.teal,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          headline,
          style: GoogleFonts.bricolageGrotesque(
            fontSize: isMobile ? 32 : 40,
            fontWeight: FontWeight.w700,
            color: AppTheme.navy,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 32),
        ...bullets.map((b) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppTheme.bgGreyGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: AppTheme.teal, size: 16),
              ),
              const SizedBox(width: 16),
              Text(
                b,
                style: const TextStyle(
                  fontSize: 18,
                  color: AppTheme.navy,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        )),
      ],
    );

    final imageContent = Container(
      height: 450,
      decoration: BoxDecoration(
        color: AppTheme.bgGreyGreen,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.border),
        image: DecorationImage(
          image: AssetImage(imagePath),
          fit: BoxFit.cover,
        ),
      ),
    );

    if (isMobile) {
      return Column(
        children: [
          textContent,
          const SizedBox(height: 48),
          imageContent,
        ],
      );
    }

    return Row(
      children: [
        if (isImageLeft) Expanded(flex: 5, child: imageContent),
        if (isImageLeft) const SizedBox(width: 80),
        Expanded(flex: 5, child: textContent),
        if (!isImageLeft) const SizedBox(width: 80),
        if (!isImageLeft) Expanded(flex: 5, child: imageContent),
      ],
    );
  }
}
