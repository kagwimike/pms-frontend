import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class DeviceShowcase extends StatelessWidget {
  const DeviceShowcase({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 100, horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              Text(
                'Available on every device.',
                textAlign: TextAlign.center,
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 40,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.navy,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Access PMS Pro from your desktop in the office, or your phone while at the property.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, color: AppTheme.mutedText),
              ),
              const SizedBox(height: 80),
              
              // Device mockups
              LayoutBuilder(
                builder: (context, constraints) {
                  final isMobile = constraints.maxWidth < 768;
                  if (isMobile) {
                    return Column(
                      children: [
                        _buildDevice('Mobile', 300, 600),
                        const SizedBox(height: 40),
                        _buildDevice('Desktop', double.infinity, 250),
                      ],
                    );
                  }

                  return SizedBox(
                    height: 500,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Desktop
                        Positioned(
                          left: 0,
                          right: 150,
                          bottom: 0,
                          top: 50,
                          child: _buildDevice('Desktop Dashboard', double.infinity, double.infinity),
                        ),
                        // Mobile
                        Positioned(
                          right: 50,
                          bottom: -20,
                          child: _buildDevice('Mobile App', 250, 480, isMobileFrame: true),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDevice(String label, double width, double height, {bool isMobileFrame = false}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppTheme.bgGreyGreen,
        borderRadius: BorderRadius.circular(isMobileFrame ? 32 : 16),
        border: Border.all(
          color: AppTheme.border,
          width: isMobileFrame ? 8 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.navy.withValues(alpha: 0.1),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isMobileFrame ? Icons.phone_iphone_rounded : Icons.desktop_mac_rounded, size: 48, color: AppTheme.border),
            const SizedBox(height: 12),
            Text(label, style: const TextStyle(color: AppTheme.mutedText, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
