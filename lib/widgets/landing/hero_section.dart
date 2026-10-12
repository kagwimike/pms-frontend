import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class HeroSection extends StatelessWidget {
  final VoidCallback onGetStartedTap;
  final VoidCallback onExploreTap;

  const HeroSection({
    super.key,
    required this.onGetStartedTap,
    required this.onExploreTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppTheme.bgGreyGreen,
      padding: const EdgeInsets.only(top: 80, bottom: 60, left: 24, right: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Headline
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Text(
              'Everything You Need to Manage Property.\nIn One Place.',
              textAlign: TextAlign.center,
              style: GoogleFonts.bricolageGrotesque(
                fontSize: MediaQuery.of(context).size.width > 768 ? 64 : 40,
                fontWeight: FontWeight.w800,
                color: AppTheme.navy,
                height: 1.1,
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Subheadline
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: const Text(
              'PMS Pro brings properties, tenants, rent, payments, maintenance, communication, and operations together in one powerful platform built for modern property managers.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                color: AppTheme.mutedText,
                height: 1.6,
              ),
            ),
          ),
          const SizedBox(height: 40),

          // CTAs
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: onGetStartedTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('Get Started', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 16),
              OutlinedButton(
                onPressed: onExploreTap,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.navy,
                  side: const BorderSide(color: AppTheme.border, width: 1.5),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('See How It Works', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          
          const SizedBox(height: 80),

          // Product Visual Mockup
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: _buildBrowserMockup(context),
          ),
        ],
      ),
    );
  }

  Widget _buildBrowserMockup(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.navy.withValues(alpha: 0.1),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          // Browser Header
          Container(
            height: 40,
            decoration: const BoxDecoration(
              color: AppTheme.bgGreyGreen,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              border: Border(bottom: BorderSide(color: AppTheme.border)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildDot(const Color(0xFFFF5F56)),
                const SizedBox(width: 8),
                _buildDot(const Color(0xFFFFBD2E)),
                const SizedBox(width: 8),
                _buildDot(const Color(0xFF27C93F)),
              ],
            ),
          ),
          
          // Dashboard Content
          Container(
            height: MediaQuery.of(context).size.width > 768 ? 600 : 300,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
              image: DecorationImage(
                image: AssetImage('assets/images/hero_dashboard.jpg'),
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(Color color) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
