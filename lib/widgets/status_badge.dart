import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  Color _statusColor(String s) {
    switch (s.toUpperCase()) {
      case 'PENDING':
      case 'OPEN':
        return Colors.orange;
      case 'ASSIGNED':
      case 'IN_PROGRESS':
        return Colors.blueAccent;
      case 'COMPLETED':
      case 'RESOLVED':
        return Colors.green;
      case 'VERIFIED':
      case 'CLOSED':
        return AppTheme.teal;
      case 'CANCELLED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.dmSans(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
