import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class UnitDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> unit;

  const UnitDetailsScreen({super.key, required this.unit});

  @override
  Widget build(BuildContext context) {
    final status = unit['status'] ?? 'UNKNOWN';
    Color statusColor = Colors.grey;
    if (status == 'VACANT') statusColor = Colors.green;
    if (status == 'OCCUPIED') statusColor = AppTheme.navy;
    if (status == 'MAINTENANCE') statusColor = Colors.orange;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          'Unit ${unit['unit_number'] ?? 'Details'}',
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Unit ${unit['unit_number'] ?? ''}',
                    style: GoogleFonts.bricolageGrotesque(fontSize: 32, fontWeight: FontWeight.w700, color: AppTheme.navy),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    status,
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Property ID: ${unit['property_id'] ?? 'Unknown'}',
              style: GoogleFonts.dmSans(fontSize: 16, color: AppTheme.mutedText),
            ),
            
            const SizedBox(height: 32),
            Text('Financials', style: GoogleFonts.bricolageGrotesque(fontSize: 20, fontWeight: FontWeight.w600, color: AppTheme.navy)),
            const SizedBox(height: 16),
            _DetailCard(
              icon: Icons.payments_outlined,
              label: 'Monthly Rent',
              value: 'KSh ${unit['rent_price'] ?? 0}',
              valueColor: AppTheme.teal,
            ),
            
            const SizedBox(height: 32),
            Text('Unit Specifications', style: GoogleFonts.bricolageGrotesque(fontSize: 20, fontWeight: FontWeight.w600, color: AppTheme.navy)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _DetailChip(icon: Icons.stairs_outlined, label: 'Floor', value: '${unit['floor'] ?? 'N/A'}'),
                _DetailChip(icon: Icons.bed_outlined, label: 'Bedrooms', value: '${unit['bedrooms'] ?? 'N/A'}'),
              ],
            ),
            
            const SizedBox(height: 32),
            // Example of expanding this later if more fields exist (e.g. current tenant, features, square footage)
          ],
        ),
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailCard({required this.icon, required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.teal.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.teal, size: 28),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.dmSans(fontSize: 14, color: AppTheme.mutedText)),
              const SizedBox(height: 4),
              Text(value, style: GoogleFonts.bricolageGrotesque(fontSize: 22, fontWeight: FontWeight.w700, color: valueColor ?? AppTheme.navy)),
            ],
          ),
        ],
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
          Icon(icon, color: AppTheme.navy, size: 20),
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
