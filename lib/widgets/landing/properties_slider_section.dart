import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class PropertiesSliderSection extends StatefulWidget {
  const PropertiesSliderSection({super.key});

  @override
  State<PropertiesSliderSection> createState() => _PropertiesSliderSectionState();
}

class _PropertiesSliderSectionState extends State<PropertiesSliderSection> {
  int _activeFilter = 0;
  final List<String> _filters = ['All Features', 'Financials', 'Maintenance', 'Leases'];

  final List<Map<String, dynamic>> _features = [
    {
      'image': 'assets/images/feature_finance.jpg',
      'tag': 'Finance',
      'title': 'Automated Rent',
      'desc': 'Track invoices, receipts, and balances instantly across your entire portfolio.',
      'f1': 'Auto-billing',
      'f2': 'Multi-currency',
      'f3': 'Reminders',
    },
    {
      'image': 'assets/images/feature_maintenance.jpg',
      'tag': 'Operations',
      'title': 'Maintenance Tracking',
      'desc': 'From tenant request to vendor completion, never miss a repair update.',
      'f1': 'Ticketing',
      'f2': 'Vendors',
      'f3': 'Inspections',
    },
    {
      'image': 'assets/images/feature_tenants.jpg',
      'tag': 'Tenants',
      'title': 'Tenant Directory',
      'desc': 'Maintain complete tenant profiles, leases, and communication history in one click.',
      'f1': 'Screening',
      'f2': 'Leases',
      'f3': 'Messaging',
    },
    {
      'image': 'assets/images/feature_properties.jpg',
      'tag': 'Portfolio',
      'title': 'Property Management',
      'desc': 'Manage multi-unit complexes, commercial spaces, and residential homes easily.',
      'f1': 'Occupancy',
      'f2': 'Owners',
      'f3': 'Reporting',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFF8FAFC),
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              Text(
                'POWERFUL FEATURES',
                style: GoogleFonts.bricolageGrotesque(
                  color: const Color(0xFF6B66FF),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Everything You Need in One Place',
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.navy,
                ),
              ),
              const SizedBox(height: 48),
              
              // Filters
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: _filters.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final isSelected = idx == _activeFilter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: InkWell(
                        onTap: () => setState(() => _activeFilter = idx),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF6B66FF) : Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: isSelected ? const Color(0xFF6B66FF) : AppTheme.border),
                          ),
                          child: Row(
                            children: [
                              if (isSelected) const Icon(Icons.check_circle, color: Colors.white, size: 18) else const Icon(Icons.apps_rounded, color: AppTheme.navy, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                entry.value,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : AppTheme.navy,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              
              const SizedBox(height: 48),
              
              // Property Cards
              LayoutBuilder(
                builder: (context, constraints) {
                  final isMobile = constraints.maxWidth < 768;
                  if (isMobile) {
                    return Column(
                      children: List.generate(4, (index) => Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: _buildPropertyCard(constraints.maxWidth, _features[index]),
                      )),
                    );
                  }
                  
                  final cardWidth = (constraints.maxWidth - 72) / 4;
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(4, (index) => _buildPropertyCard(cardWidth, _features[index])),
                  );
                },
              ),
              
              const SizedBox(height: 48),
              
              // Dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.arrow_back, size: 16, color: AppTheme.navy),
                  const SizedBox(width: 16),
                  _buildDot(true),
                  const SizedBox(width: 8),
                  _buildDot(false),
                  const SizedBox(width: 8),
                  _buildDot(false),
                  const SizedBox(width: 16),
                  const Icon(Icons.arrow_forward, size: 16, color: AppTheme.border),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPropertyCard(double width, Map<String, dynamic> data) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Stack(
            children: [
              Container(
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  image: DecorationImage(
                    image: AssetImage(data['image']),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                bottom: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    data['tag'],
                    style: GoogleFonts.bricolageGrotesque(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['title'],
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.navy),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, size: 16, color: Color(0xFF6B66FF)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        data['desc'],
                        style: const TextStyle(color: AppTheme.mutedText, fontSize: 12, height: 1.4),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                // Amenities
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildAmenity(Icons.check_circle_outline, data['f1']),
                    _buildAmenity(Icons.check_circle_outline, data['f2']),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildAmenity(Icons.check_circle_outline, data['f3']),
                    const SizedBox(),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmenity(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppTheme.mutedText),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 12, color: AppTheme.navy, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildDot(bool isActive) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? const Color(0xFF6B66FF) : AppTheme.border,
      ),
    );
  }
}
