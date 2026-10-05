import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../config.dart';

class FooterSection extends StatelessWidget {
  const FooterSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.navy,
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(AppConfig.brandName, style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white)),
                        const SizedBox(height: 16),
                        const Text(
                          'Built in Kenya, M-Pesa ready, your data stays yours.',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  const Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Quick Links', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        SizedBox(height: 16),
                        const _FooterLink('Features'),
                        const _FooterLink('Pricing'),
                        const _FooterLink('FAQ'),
                      ],
                    ),
                  ),
                  const Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Contact', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        SizedBox(height: 16),
                        const _FooterLink(AppConfig.phone),
                        const _FooterLink(AppConfig.email),
                        const _FooterLink('Nairobi, Kenya'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 60),
              const Divider(color: Colors.white24),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('© ${DateTime.now().year} ${AppConfig.brandName}. All rights reserved.', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  const Row(
                    children: [
                      const _FooterLink('Privacy Policy', fontSize: 12),
                      SizedBox(width: 16),
                      const _FooterLink('Terms of Service', fontSize: 12),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  final String text;
  final double fontSize;

  const _FooterLink(this.text, {this.fontSize = 14});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Text(
          text,
          style: TextStyle(color: Colors.white70, fontSize: fontSize),
        ),
      ),
    );
  }
}
