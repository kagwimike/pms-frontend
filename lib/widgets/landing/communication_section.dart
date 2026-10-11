import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class CommunicationSection extends StatelessWidget {
  const CommunicationSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppTheme.bgGreyGreen,
      padding: const EdgeInsets.symmetric(vertical: 100, horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 900;
              
              final content = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Keep every conversation connected to the property.',
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: isMobile ? 32 : 40,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.navy,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'No more searching through WhatsApp, SMS, or emails. PMS Pro connects communication directly to the relevant properties, leases, and maintenance requests.',
                    style: TextStyle(fontSize: 18, color: AppTheme.mutedText, height: 1.5),
                  ),
                  const SizedBox(height: 40),
                  _buildCommItem(Icons.chat_bubble_outline, 'Tenant conversations'),
                  _buildCommItem(Icons.maps_home_work_outlined, 'Property channels'),
                  _buildCommItem(Icons.build_circle_outlined, 'Maintenance updates'),
                  _buildCommItem(Icons.notifications_active_outlined, 'Automated notifications'),
                  _buildCommItem(Icons.campaign_outlined, 'Mass announcements'),
                ],
              );

              final visual = Container(
                height: 500,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.border),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.navy.withValues(alpha: 0.05),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                  image: const DecorationImage(
                    image: AssetImage('assets/images/communication_ui.jpg'),
                    fit: BoxFit.cover,
                  ),
                ),
              );

              if (isMobile) {
                return Column(
                  children: [
                    content,
                    const SizedBox(height: 64),
                    visual,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(flex: 5, child: content),
                  const SizedBox(width: 80),
                  Expanded(flex: 5, child: visual),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCommItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.border),
            ),
            child: Icon(icon, color: AppTheme.teal, size: 24),
          ),
          const SizedBox(width: 20),
          Text(
            text,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.navy,
            ),
          ),
        ],
      ),
    );
  }
}
