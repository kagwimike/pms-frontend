import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class HeroCollageSection extends StatelessWidget {
  const HeroCollageSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 900;
              
              if (isMobile) {
                return Column(
                  children: [
                    _buildTextContent(context),
                    const SizedBox(height: 36),
                    _buildImageCollage(),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(flex: 5, child: _buildImageCollage()),
                  const SizedBox(width: 48),
                  Expanded(flex: 5, child: _buildTextContent(context)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildImageCollage() {
    return SizedBox(
      height: 420,
      child: Stack(
        children: [
          // Background accent
          Positioned(
            top: 16,
            right: 0,
            child: Container(
              width: 220,
              height: 180,
              decoration: BoxDecoration(
                color: AppTheme.teal.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          // Top right image
          Positioned(
            top: 0,
            right: 16,
            child: Container(
              width: 200,
              height: 140,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                image: const DecorationImage(
                  image: AssetImage('assets/images/feature_properties.jpg'),
                  fit: BoxFit.cover,
                ),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 8)),
                ],
              ),
            ),
          ),
          // Top left tall image
          Positioned(
            top: 24,
            left: 0,
            child: Container(
              width: 95,
              height: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                image: const DecorationImage(
                  image: AssetImage('assets/images/feature_finance.jpg'),
                  fit: BoxFit.cover,
                ),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 8)),
                ],
              ),
            ),
          ),
          // Bottom large image
          Positioned(
            bottom: 0,
            left: 0,
            right: 16,
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                image: const DecorationImage(
                  image: AssetImage('assets/images/feature_maintenance.jpg'),
                  fit: BoxFit.cover,
                ),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 8)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextContent(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PROPERTY MANAGEMENT',
          style: GoogleFonts.bricolageGrotesque(
            color: AppTheme.teal,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Manage Your Portfolio With Confidence',
          style: GoogleFonts.bricolageGrotesque(
            fontSize: isMobile ? 30 : 38,
            fontWeight: FontWeight.w800,
            color: AppTheme.navy,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Streamline your property operations, rent collection, and tenant communications effortlessly with our intuitive platform. Built to scale from 5 units to enterprise portfolios.',
          style: TextStyle(
            fontSize: 15,
            color: AppTheme.mutedText,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(child: _buildGridItem(Icons.account_balance_wallet_outlined, 'Automated Billing', 'Generate invoices, collect rent online, and track balances.')),
            const SizedBox(width: 20),
            Expanded(child: _buildGridItem(Icons.people_outline, 'Tenant Portal', 'Self-service app for tenants to pay rent and submit tickets.')),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildGridItem(Icons.handyman_outlined, 'Maintenance Tracking', 'Manage work orders from tenant request to completion.')),
            const SizedBox(width: 20),
            Expanded(child: _buildGridItem(Icons.pie_chart_outline, 'Real-time Financials', 'Instant insights into net operating income and cash flow.')),
          ],
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 20,
          runSpacing: 14,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/register'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text('Start Free Trial', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: AppTheme.navy,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.call, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Contact Sales', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.navy)),
                    Text('+243 816 996 077', style: TextStyle(fontSize: 12, color: AppTheme.mutedText)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGridItem(IconData icon, String title, String desc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppTheme.teal, size: 26),
        const SizedBox(height: 8),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.navy)),
        const SizedBox(height: 4),
        Text(desc, style: const TextStyle(fontSize: 12, color: AppTheme.mutedText, height: 1.35)),
      ],
    );
  }
}
