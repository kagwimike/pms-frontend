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
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              Text(
                'Plans that grow with your property business.',
                textAlign: TextAlign.center,
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.navy,
                ),
              ),
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isMobile = constraints.maxWidth < 900;
                  final double cardWidth = isMobile ? constraints.maxWidth : (constraints.maxWidth - 48) / 3;

                  return Wrap(
                    spacing: 20,
                    runSpacing: 20,
                    alignment: WrapAlignment.center,
                    children: [
                      _buildPricingCard(
                        title: 'Starter',
                        subtitle: 'For independent landlords managing their initial units',
                        price: '\$29',
                        period: '/month',
                        features: const [
                          'Up to 20 rental units',
                          'Automated rent invoice generation',
                          'Tenant directory & lease tracking',
                          'Maintenance request intake',
                          'Mobile-friendly tenant portal',
                        ],
                        buttonText: 'Start Free Trial',
                        isHighlighted: false,
                        width: cardWidth,
                        onAction: onViewPricingTap,
                      ),
                      _buildPricingCard(
                        title: 'Professional',
                        subtitle: 'For growing property managers and agencies',
                        price: '\$79',
                        period: '/month',
                        features: const [
                          'Up to 100 rental units',
                          'M-Pesa automated reconciliation',
                          'Vendor dispatch & quote tracking',
                          'Owner financial & yield reports',
                          'SMS & WhatsApp notifications',
                          'Document vault & digital leases',
                        ],
                        buttonText: 'Start 14-Day Trial',
                        isHighlighted: true,
                        width: cardWidth,
                        onAction: onViewPricingTap,
                      ),
                      _buildPricingCard(
                        title: 'Enterprise',
                        subtitle: 'For large portfolios and commercial property firms',
                        price: 'Custom',
                        period: '',
                        features: const [
                          'Unlimited units & properties',
                          'Multi-portfolio database separation',
                          'Advanced role-based access (RBAC)',
                          'Dedicated account manager',
                          'Custom API integrations & SLA',
                          'Priority 24/7 technical support',
                        ],
                        buttonText: 'Contact Sales',
                        isHighlighted: false,
                        width: cardWidth,
                        onAction: onViewPricingTap,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 28),
              OutlinedButton(
                onPressed: onViewPricingTap,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.navy,
                  side: const BorderSide(color: AppTheme.navy, width: 1.5),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Compare All Features & Add-ons', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPricingCard({
    required String title,
    required String subtitle,
    required String price,
    required String period,
    required List<String> features,
    required String buttonText,
    required bool isHighlighted,
    required double width,
    required VoidCallback onAction,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isHighlighted ? AppTheme.navy : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isHighlighted ? AppTheme.teal : AppTheme.border,
          width: isHighlighted ? 2 : 1,
        ),
        boxShadow: isHighlighted
            ? [
                BoxShadow(
                  color: AppTheme.teal.withValues(alpha: 0.25),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                )
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                )
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isHighlighted)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: AppTheme.teal,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'MOST POPULAR',
                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
            ),
          Text(
            title,
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isHighlighted ? Colors.white : AppTheme.navy,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 13,
              height: 1.35,
              color: isHighlighted ? Colors.white70 : AppTheme.mutedText,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                price,
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: isHighlighted ? Colors.white : AppTheme.navy,
                ),
              ),
              if (period.isNotEmpty)
                Text(
                  period,
                  style: TextStyle(
                    fontSize: 14,
                    color: isHighlighted ? Colors.white70 : AppTheme.mutedText,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: isHighlighted ? Colors.white12 : AppTheme.border),
          const SizedBox(height: 14),
          ...features.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      color: isHighlighted ? AppTheme.whatsappGreen : AppTheme.teal,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        f,
                        style: TextStyle(
                          fontSize: 13,
                          color: isHighlighted ? Colors.white.withValues(alpha: 0.9) : AppTheme.navy,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: isHighlighted ? AppTheme.teal : AppTheme.navy,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                buttonText,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
