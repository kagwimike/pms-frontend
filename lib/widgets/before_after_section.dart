import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../config.dart';

class BeforeAfterSection extends StatelessWidget {
  const BeforeAfterSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 80),
      child: Column(
        children: [
          Text(
            'Managing properties shouldn\'t be a headache.',
            style: Theme.of(context).textTheme.headlineLarge,
            textAlign: TextAlign.center,
          ).animate().fadeIn().slideY(),
          const SizedBox(height: 60),
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 700;
              final children = [
                Expanded(
                  flex: isMobile ? 0 : 1,
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: AppTheme.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Yesterday', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 18)),
                        const SizedBox(height: 24),
                        _buildListItem(Icons.close, 'Manually matching M-Pesa SMS messages to units', Colors.red),
                        _buildListItem(Icons.close, 'Awkward phone calls chasing late rent', Colors.red),
                        _buildListItem(Icons.close, 'Messy Excel sheets that are hard to update', Colors.red),
                        _buildListItem(Icons.close, 'Spending hours writing owner reports', Colors.red),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: isMobile ? 0 : 24, height: isMobile ? 24 : 0),
                Expanded(
                  flex: isMobile ? 0 : 1,
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: AppTheme.navy,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('With ${AppConfig.brandName}', style: const TextStyle(color: AppTheme.whatsappGreen, fontWeight: FontWeight.bold, fontSize: 18)),
                        const SizedBox(height: 24),
                        _buildListItem(Icons.check, 'Payments match automatically via Paybill/Till', AppTheme.whatsappGreen, textColor: Colors.white),
                        _buildListItem(Icons.check, 'Automated, polite SMS reminders to tenants', AppTheme.whatsappGreen, textColor: Colors.white),
                        _buildListItem(Icons.check, 'Clean digital records for every lease', AppTheme.whatsappGreen, textColor: Colors.white),
                        _buildListItem(Icons.check, 'One-click owner statements & commission tracking', AppTheme.whatsappGreen, textColor: Colors.white),
                      ],
                    ),
                  ),
                ),
              ];

              if (isMobile) {
                return Column(children: children);
              }
              return IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: children));
            },
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 40),
          Text(
            '“We built ${AppConfig.brandName} because we were tired of doing this the hard way.” — The Founders',
            style: const TextStyle(fontStyle: FontStyle.italic, color: AppTheme.mutedText),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 400.ms),
        ],
      ),
    );
  }

  Widget _buildListItem(IconData icon, String text, Color iconColor, {Color textColor = AppTheme.navy}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: TextStyle(color: textColor, height: 1.5))),
        ],
      ),
    );
  }
}
