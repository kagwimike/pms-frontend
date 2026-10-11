import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class LocationsGridSection extends StatelessWidget {
  const LocationsGridSection({super.key});

  @override
  Widget build(BuildContext context) {
    final locations = [
      {'title': 'Residential', 'image': 'assets/images/feature_finance.jpg', 'count': 'Multi-Family & Single'},
      {'title': 'Commercial', 'image': 'assets/images/feature_maintenance.jpg', 'count': 'Retail & Office'},
      {'title': 'Student Housing', 'image': 'assets/images/feature_tenants.jpg', 'count': 'Off-Campus & Dorms'},
      {'title': 'Mixed Use', 'image': 'assets/images/feature_properties.jpg', 'count': 'Retail & Residential'},
    ];

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
                'BUILT FOR EVERY PORTFOLIO',
                style: GoogleFonts.bricolageGrotesque(
                  color: const Color(0xFF6B66FF),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Empowering Property Managers Everywhere',
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.navy,
                ),
              ),
              const SizedBox(height: 48),
              
              LayoutBuilder(
                builder: (context, constraints) {
                  final isMobile = constraints.maxWidth < 768;
                  if (isMobile) {
                    return Column(
                      children: locations.map((loc) => Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: _buildLocationCard(
                          width: constraints.maxWidth,
                          title: loc['title']!,
                          imagePath: loc['image']!,
                          count: loc['count']!,
                        ),
                      )).toList(),
                    );
                  }
                  
                  final cardWidth = (constraints.maxWidth - 72) / 4;
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: locations.map((loc) => _buildLocationCard(
                      width: cardWidth,
                      title: loc['title']!,
                      imagePath: loc['image']!,
                      count: loc['count']!,
                    )).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationCard({required double width, required String title, required String imagePath, required String count}) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          Container(
            height: 240,
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                image: AssetImage(imagePath),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.navy),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6B66FF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    count,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
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
