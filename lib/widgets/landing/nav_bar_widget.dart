import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../config.dart';
import 'package:google_fonts/google_fonts.dart';

class NavBarWidget extends StatelessWidget {
  final VoidCallback onLoginTap;
  final VoidCallback onGetStartedTap;

  const NavBarWidget({
    super.key,
    required this.onLoginTap,
    required this.onGetStartedTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 900;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            border: const Border(bottom: const BorderSide(color: AppTheme.border)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Logo
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppTheme.teal,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.maps_home_work, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    AppConfig.brandName,
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.navy,
                    ),
                  ),
                ],
              ),

              // Desktop Links
              if (isDesktop)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildNavLink('Product'),
                    const SizedBox(width: 24),
                    _buildNavLink('Solutions'),
                    const SizedBox(width: 24),
                    _buildNavLink('Features'),
                    const SizedBox(width: 24),
                    _buildNavLink('Resources'),
                    const SizedBox(width: 24),
                    _buildNavLink('Pricing'),
                  ],
                ),

              // Actions
              if (isDesktop)
                Row(
                  children: [
                    TextButton(
                      onPressed: onLoginTap,
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.navy,
                        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                      child: const Text('Log in'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: onGetStartedTap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.teal,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Get Started', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                )
              else
                IconButton(
                  icon: const Icon(Icons.menu, color: AppTheme.navy),
                  onPressed: () {
                    Scaffold.of(context).openDrawer();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNavLink(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: AppTheme.mutedText,
        fontWeight: FontWeight.w500,
        fontSize: 16,
      ),
    );
  }
}
