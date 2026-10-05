import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import 'shared_widgets.dart';

class FeaturesSection extends StatelessWidget {
  const FeaturesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 80),
      child: Column(
        children: [
          const SectionTitle(
            title: 'Everything you need to manage effortlessly.',
            subtitle: 'Powerful tools built for property managers and landlords.',
          ).animate().fadeIn().slideY(),
          const SizedBox(height: 60),
          LayoutBuilder(
            builder: (context, constraints) {
              int crossAxisCount = constraints.maxWidth < 700 ? 1 : (constraints.maxWidth < 1100 ? 2 : 3);
              
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 24,
                mainAxisSpacing: 24,
                childAspectRatio: 1.2,
                children: const [
                  _FeatureCard(
                    icon: Icons.receipt_long,
                    title: 'M-Pesa Matching',
                    description: 'Automatically match incoming Paybill or Till payments to the correct tenant and unit.',
                    delay: 0,
                  ),
                  _FeatureCard(
                    icon: Icons.notifications_active,
                    title: 'Auto Reminders',
                    description: 'Send automated, polite SMS reminders before and after rent is due.',
                    delay: 100,
                  ),
                  _FeatureCard(
                    icon: Icons.folder_shared,
                    title: 'Digital Records',
                    description: 'Keep all tenant information, lease agreements, and payment history in one place.',
                    delay: 200,
                  ),
                  _FeatureCard(
                    icon: Icons.build,
                    title: 'Maintenance',
                    description: 'Tenants can log requests. Track costs and assign handymen easily.',
                    delay: 300,
                  ),
                  _FeatureCard(
                    icon: Icons.pie_chart,
                    title: 'Owner Statements',
                    description: 'Generate one-click PDF statements for property owners showing rent, costs, and your commission.',
                    delay: 400,
                  ),
                  _FeatureCard(
                    icon: Icons.water_drop,
                    title: 'Utility Billing',
                    description: 'Read meters and automatically add water, garbage, and electricity to the monthly invoice.',
                    delay: 500,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final int delay;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return HoverCard(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.bgGreyGreen,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppTheme.teal, size: 32),
            ),
            const SizedBox(height: 24),
            Text(title, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 20)),
            const SizedBox(height: 12),
            Expanded(
              child: Text(description, style: Theme.of(context).textTheme.bodyMedium),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: delay.ms).slideY(begin: 0.2, end: 0);
  }
}
