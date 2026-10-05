import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../config.dart';

class PropertyDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> property;

  const PropertyDetailsScreen({super.key, required this.property});

  @override
  Widget build(BuildContext context) {
    final images = property['images'] as List? ?? [];
    
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          property['name'] ?? 'Property Details',
          style: GoogleFonts.bricolageGrotesque(color: AppTheme.navy, fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.navy),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (images.isNotEmpty)
              SizedBox(
                height: 250,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: images.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          '${AppConfig.apiBaseUrl.replaceFirst('/api', '')}/media/${images[index]['image']}',
                          width: 300,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: 300,
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.broken_image, color: Colors.grey),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              )
            else
              Container(
                height: 250,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.home_work_outlined, size: 64, color: Colors.grey.shade400),
              ),
            
            const SizedBox(height: 24),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    property['name'] ?? '',
                    style: GoogleFonts.bricolageGrotesque(fontSize: 28, fontWeight: FontWeight.w700, color: AppTheme.navy),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: property['status'] == 'ACTIVE' ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    property['status'] ?? 'UNKNOWN',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: property['status'] == 'ACTIVE' ? Colors.green.shade700 : Colors.orange.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, color: AppTheme.mutedText, size: 18),
                const SizedBox(width: 8),
                Text(
                  '${property['address'] ?? ''}, ${property['city'] ?? ''}, ${property['country'] ?? ''}',
                  style: GoogleFonts.dmSans(fontSize: 16, color: AppTheme.mutedText),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            Text('Description', style: GoogleFonts.bricolageGrotesque(fontSize: 20, fontWeight: FontWeight.w600, color: AppTheme.navy)),
            const SizedBox(height: 8),
            Text(
              property['description']?.toString().isNotEmpty == true ? property['description'] : 'No description provided.',
              style: GoogleFonts.dmSans(fontSize: 15, color: AppTheme.navy.withValues(alpha: 0.8), height: 1.5),
            ),
            
            const SizedBox(height: 32),
            Text('Property Details', style: GoogleFonts.bricolageGrotesque(fontSize: 20, fontWeight: FontWeight.w600, color: AppTheme.navy)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _DetailChip(icon: Icons.category_outlined, label: 'Type', value: property['property_type'] ?? 'N/A'),
                _DetailChip(icon: Icons.door_sliding_outlined, label: 'Total Units', value: property['total_units']?.toString() ?? 'N/A'),
              ],
            ),
            
            const SizedBox(height: 32),
            Text('Amenities', style: GoogleFonts.bricolageGrotesque(fontSize: 20, fontWeight: FontWeight.w600, color: AppTheme.navy)),
            const SizedBox(height: 16),
            if (property['amenities'] != null && (property['amenities'] as List).isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: (property['amenities'] as List).map((a) {
                  final name = a is Map ? a['name'] : a.toString();
                  return Chip(
                    label: Text(name ?? '', style: GoogleFonts.dmSans(fontWeight: FontWeight.w500)),
                    backgroundColor: AppTheme.teal.withValues(alpha: 0.1),
                    side: BorderSide.none,
                  );
                }).toList(),
              )
            else
              Text('No amenities listed.', style: GoogleFonts.dmSans(color: AppTheme.mutedText)),
          ],
        ),
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailChip({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppTheme.teal, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.dmSans(fontSize: 12, color: AppTheme.mutedText)),
              Text(value, style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.navy)),
            ],
          ),
        ],
      ),
    );
  }
}
