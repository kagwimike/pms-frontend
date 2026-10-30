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
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              Text(
                'BUILT FOR EVERY PORTFOLIO',
                style: GoogleFonts.bricolageGrotesque(
                  color: AppTheme.teal,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Empowering Property Managers Everywhere',
                textAlign: TextAlign.center,
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: MediaQuery.of(context).size.width < 768 ? 26 : 32,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.navy,
                ),
              ),
              const SizedBox(height: 28),
              
              LayoutBuilder(
                builder: (context, constraints) {
                  final isMobile = constraints.maxWidth < 768;
                  if (isMobile) {
                    return Column(
                      children: locations.map((loc) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildLocationCard(
                          width: constraints.maxWidth,
                          title: loc['title']!,
                          imagePath: loc['image']!,
                          count: loc['count']!,
                        ),
                      )).toList(),
                    );
                  }
                  
                  final cardWidth = (constraints.maxWidth - 48) / 4;
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
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          Container(
            height: 150,
            margin: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              image: DecorationImage(
                image: AssetImage(imagePath),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Column(
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.navy),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.teal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    count,
                    style: const TextStyle(color: AppTheme.teal, fontWeight: FontWeight.bold, fontSize: 11),
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
