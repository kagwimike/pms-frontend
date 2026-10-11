import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class PricingPreview extends StatelessWidget {
  final VoidCallback onViewPricingTap;

  const PricingPreview({super.key, required this.onViewPricingTap});

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
              Text(
                'Plans that grow with your property business.',
                textAlign: TextAlign.center,
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 40,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.navy,
                ),
              ),
              const SizedBox(height: 64),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isMobile = constraints.maxWidth < 900;
                  final double cardWidth = isMobile ? constraints.maxWidth : (constraints.maxWidth - 64) / 3;

                  return Wrap(
                    spacing: 32,
                    runSpacing: 32,
                    alignment: WrapAlignment.center,
                    children: [
                      _buildPricingCard('Starter', 'For small landlords', false, cardWidth),
                      _buildPricingCard('Professional', 'For growing property managers', true, cardWidth),
                      _buildPricingCard('Enterprise', 'For property companies', false, cardWidth),
                    ],
                  );
                },
              ),
              const SizedBox(height: 64),
              OutlinedButton(
                onPressed: onViewPricingTap,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.navy,
                  side: const BorderSide(color: AppTheme.navy, width: 1.5),
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('View Pricing Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPricingCard(String title, String subtitle, bool isHighlighted, double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: isHighlighted ? AppTheme.navy : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isHighlighted ? AppTheme.navy : AppTheme.border),
        boxShadow: isHighlighted
            ? [
                BoxShadow(
                  color: AppTheme.navy.withValues(alpha: 0.2),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                )
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isHighlighted)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: AppTheme.teal,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'MOST POPULAR',
                style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
            ),
          Text(
            title,
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: isHighlighted ? Colors.white : AppTheme.navy,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 16,
              color: isHighlighted ? Colors.white70 : AppTheme.mutedText,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            '[Pricing Placeholder]',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isHighlighted ? Colors.white : AppTheme.navy,
            ),
          ),
        ],
      ),
    );
  }
}
