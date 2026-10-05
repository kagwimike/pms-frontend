import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'package:intl/intl.dart';

class LeaseDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> lease;

  const LeaseDetailsScreen({super.key, required this.lease});

  @override
  Widget build(BuildContext context) {
    final status = lease['status'] ?? 'UNKNOWN';
    Color statusColor = Colors.grey;
    if (status == 'ACTIVE') statusColor = Colors.green;
    if (status == 'PENDING') statusColor = Colors.orange;
    if (status == 'TERMINATED') statusColor = Colors.red;
    if (status == 'RENEWED') statusColor = Colors.blue;

    final unit = lease['unit'] ?? {};
    final tenant = lease['tenant'] ?? {};
    final property = unit['property'] ?? {};

    // Basic date formatting safely
    String formatSafeDate(dynamic d) {
      if (d == null) return 'N/A';
      try {
        final dt = DateTime.parse(d.toString());
        return DateFormat('MMM dd, yyyy').format(dt);
      } catch (_) {
        return d.toString();
      }
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text('Lease Details', style: GoogleFonts.bricolageGrotesque(color: AppTheme.navy, fontWeight: FontWeight.w700)),
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
                    'Lease Agreement',
                    style: GoogleFonts.bricolageGrotesque(fontSize: 28, fontWeight: FontWeight.w700, color: AppTheme.navy),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(status, style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w700, color: statusColor)),
                ),
              ],
            ),
            const SizedBox(height: 32),
            
            Text('Financials', style: GoogleFonts.bricolageGrotesque(fontSize: 20, fontWeight: FontWeight.w600, color: AppTheme.navy)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _InfoCard(icon: Icons.payments_outlined, label: 'Monthly Rent', value: 'KSh ${lease['rent_amount'] ?? 0}'),
                _InfoCard(icon: Icons.savings_outlined, label: 'Deposit', value: 'KSh ${lease['deposit_amount'] ?? 0}'),
              ],
            ),
            
            const SizedBox(height: 32),
            Text('Term', style: GoogleFonts.bricolageGrotesque(fontSize: 20, fontWeight: FontWeight.w600, color: AppTheme.navy)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _InfoCard(icon: Icons.calendar_today_outlined, label: 'Start Date', value: formatSafeDate(lease['start_date'])),
                _InfoCard(icon: Icons.event_busy_outlined, label: 'End Date', value: formatSafeDate(lease['end_date'])),
              ],
            ),

            const SizedBox(height: 32),
            Text('Unit & Property', style: GoogleFonts.bricolageGrotesque(fontSize: 20, fontWeight: FontWeight.w600, color: AppTheme.navy)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.border)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Unit ${unit['unit_number'] ?? '?'}', style: GoogleFonts.bricolageGrotesque(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.navy)),
                  const SizedBox(height: 8),
                  Text(property['name'] ?? 'Property ID: ${unit['property_id']}', style: GoogleFonts.dmSans(fontSize: 14, color: AppTheme.mutedText)),
                ],
              ),
            ),

            const SizedBox(height: 32),
            Text('Tenant', style: GoogleFonts.bricolageGrotesque(fontSize: 20, fontWeight: FontWeight.w600, color: AppTheme.navy)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.border)),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppTheme.teal.withValues(alpha: 0.1),
                    child: const Icon(Icons.person, color: AppTheme.teal),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tenant['username'] ?? 'Unknown Tenant', style: GoogleFonts.bricolageGrotesque(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.navy)),
                      Text(tenant['email'] ?? 'No email provided', style: GoogleFonts.dmSans(fontSize: 14, color: AppTheme.mutedText)),
                    ],
                  ),
                ],
              ),
            ),

            if (lease['notes'] != null && lease['notes'].toString().trim().isNotEmpty) ...[
              const SizedBox(height: 32),
              Text('Notes', style: GoogleFonts.bricolageGrotesque(fontSize: 20, fontWeight: FontWeight.w600, color: AppTheme.navy)),
              const SizedBox(height: 8),
              Text(
                lease['notes'],
                style: GoogleFonts.dmSans(fontSize: 15, color: AppTheme.navy.withValues(alpha: 0.8), height: 1.5),
              ),
            ],
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoCard({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.border)),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.teal, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.dmSans(fontSize: 12, color: AppTheme.mutedText)),
                const SizedBox(height: 2),
                Text(value, style: GoogleFonts.bricolageGrotesque(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.navy), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
