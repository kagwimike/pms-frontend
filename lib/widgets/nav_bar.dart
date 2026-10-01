import 'package:flutter/material.dart';
import '../config.dart';
import '../theme/app_theme.dart';
import 'shared_widgets.dart';

class NavBar extends StatelessWidget {
  final VoidCallback onFeaturesTap;
  final VoidCallback onHowItWorksTap;
  final VoidCallback onPricingTap;
  final VoidCallback onFaqTap;

  const NavBar({
    super.key,
    required this.onFeaturesTap,
    required this.onHowItWorksTap,
    required this.onPricingTap,
    required this.onFaqTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      color: AppTheme.bgGreyGreen,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 1100;
          
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (isMobile)
                IconButton(
                  icon: const Icon(Icons.menu, color: AppTheme.navy),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              Text(
                AppConfig.brandName,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              if (!isMobile)
                Row(
                  children: [
                    TextButton(onPressed: onFeaturesTap, child: const Text('Features', style: TextStyle(color: AppTheme.navy))),
                    const SizedBox(width: 24),
                    TextButton(onPressed: onHowItWorksTap, child: const Text('How it works', style: TextStyle(color: AppTheme.navy))),
                    const SizedBox(width: 24),
                    TextButton(onPressed: onPricingTap, child: const Text('Pricing', style: TextStyle(color: AppTheme.navy))),
                    const SizedBox(width: 24),
                    TextButton(onPressed: onFaqTap, child: const Text('FAQ', style: TextStyle(color: AppTheme.navy))),
                  ],
                ),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pushNamed('/login'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.navy,
                      side: const BorderSide(color: AppTheme.navy),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    ),
                    child: const Text('Log In', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 12),
                  const WhatsappButton(),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
