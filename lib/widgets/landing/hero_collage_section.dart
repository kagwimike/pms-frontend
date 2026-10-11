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
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
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
                    const SizedBox(height: 64),
                    _buildImageCollage(),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(flex: 5, child: _buildImageCollage()),
                  const SizedBox(width: 64),
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
      height: 600,
      child: Stack(
        children: [
          // Background blue accent
          Positioned(
            top: 20,
            right: 0,
            child: Container(
              width: 300,
              height: 250,
              decoration: BoxDecoration(
                color: const Color(0xFF6B66FF).withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          // Top right image
          Positioned(
            top: 0,
            right: 20,
            child: Container(
              width: 280,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: const DecorationImage(
                  image: AssetImage('assets/images/feature_properties.jpg'), // using existing image as placeholder
                  fit: BoxFit.cover,
                ),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 10)),
                ],
              ),
            ),
          ),
          // Top left tall image
          Positioned(
            top: 40,
            left: 0,
            child: Container(
              width: 120,
              height: 250,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: const DecorationImage(
                  image: AssetImage('assets/images/feature_finance.jpg'),
                  fit: BoxFit.cover,
                ),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 10)),
                ],
              ),
            ),
          ),
          // Bottom large image
          Positioned(
            bottom: 0,
            left: 0,
            right: 20,
            child: Container(
              height: 280,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: const DecorationImage(
                  image: AssetImage('assets/images/feature_maintenance.jpg'),
                  fit: BoxFit.cover,
                ),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 10)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PROPERTY MANAGEMENT',
          style: GoogleFonts.bricolageGrotesque(
            color: const Color(0xFF6B66FF),
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Manage Your Portfolio With Confidence',
          style: GoogleFonts.bricolageGrotesque(
            fontSize: 48,
            fontWeight: FontWeight.w800,
            color: AppTheme.navy,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Streamline your property operations, rent collection, and tenant communications effortlessly with our intuitive platform. Whether you manage 10 units or 10,000, PMS Pro scales with your business.',
          style: TextStyle(
            fontSize: 16,
            color: AppTheme.mutedText,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 48),
        Row(
          children: [
            Expanded(child: _buildGridItem(Icons.account_balance_wallet_outlined, 'Automated Billing', 'Generate invoices, collect rent online, and track balances automatically.')),
            const SizedBox(width: 24),
            Expanded(child: _buildGridItem(Icons.people_outline, 'Tenant Portal', 'Give tenants a self-service app to pay rent and report issues.')),
          ],
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(child: _buildGridItem(Icons.handyman_outlined, 'Maintenance Tracking', 'Manage work orders from tenant request to vendor completion.')),
            const SizedBox(width: 24),
            Expanded(child: _buildGridItem(Icons.pie_chart_outline, 'Real-time Financials', 'Gain instant insights into your net operating income and expenses.')),
          ],
        ),
        const SizedBox(height: 48),
        Row(
          children: [
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B66FF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text('Start Free Trial', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 32),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: AppTheme.navy,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.call, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 16),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Contact Sales', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.navy)),
                    Text('+243 816 996 077', style: TextStyle(color: AppTheme.mutedText)),
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
        Icon(icon, color: const Color(0xFF6B66FF), size: 32),
        const SizedBox(height: 12),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.navy)),
        const SizedBox(height: 8),
        Text(desc, style: const TextStyle(fontSize: 13, color: AppTheme.mutedText, height: 1.4)),
      ],
    );
  }
}
