import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../config.dart';
import 'package:google_fonts/google_fonts.dart';

class LandingFooterSection extends StatelessWidget {
  const LandingFooterSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppTheme.navy,
      padding: const EdgeInsets.only(top: 52, bottom: 28, left: 24, right: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final isMobile = constraints.maxWidth < 768;
                  
                  if (isMobile) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildBrand(),
                        const SizedBox(height: 28),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildColumn('Product', ['Features', 'Property Management', 'Payments', 'Maintenance', 'Reporting'])),
                            Expanded(child: _buildColumn('Solutions', ['Property Managers', 'Owners', 'Landlords', 'Caretakers', 'Tenants', 'Vendors'])),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildColumn('Resources', ['Help Center', 'Documentation', 'FAQs', 'Contact'])),
                            Expanded(child: _buildColumn('Company', ['About', 'Contact', 'Privacy', 'Terms'])),
                          ],
                        ),
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: _buildBrand()),
                      Expanded(flex: 2, child: _buildColumn('Product', ['Features', 'Property Management', 'Payments', 'Maintenance', 'Reporting'])),
                      Expanded(flex: 2, child: _buildColumn('Solutions', ['Property Managers', 'Owners', 'Landlords', 'Caretakers', 'Tenants', 'Vendors'])),
                      Expanded(flex: 2, child: _buildColumn('Resources', ['Help Center', 'Documentation', 'FAQs', 'Contact'])),
                      Expanded(flex: 2, child: _buildColumn('Company', ['About', 'Contact', 'Privacy', 'Terms'])),
                    ],
                  );
                },
              ),
              const SizedBox(height: 36),
              Container(height: 1, color: Colors.white.withValues(alpha: 0.1)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '© ${DateTime.now().year} ${AppConfig.brandName}. All rights reserved.',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                  ),
                  Row(
                    children: [
                      _buildSocialIcon(Icons.link_rounded),
                      const SizedBox(width: 16),
                      _buildSocialIcon(Icons.link_rounded),
                    ],
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBrand() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.teal,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.maps_home_work, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Text(
              AppConfig.brandName,
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Modern property management\nfor modern property businesses.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            height: 1.5,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildColumn(String title, List<String> links) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 24),
        ...links.map((link) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            link,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 14,
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildSocialIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.05),
      ),
      child: Icon(icon, color: Colors.white.withValues(alpha: 0.5), size: 20),
    );
  }
}
