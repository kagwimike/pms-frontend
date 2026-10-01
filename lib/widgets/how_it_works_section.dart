import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import 'shared_widgets.dart';

class HowItWorksSection extends StatelessWidget {
  const HowItWorksSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 80),
      color: AppTheme.bgGreyGreen,
      child: Column(
        children: [
          const SectionTitle(
            title: 'Up and running in minutes.',
            subtitle: 'We do the heavy lifting so you can focus on growing.',
          ).animate().fadeIn().slideY(),
          const SizedBox(height: 60),
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 700;
              
              if (isMobile) {
                return Column(
                  children: [
                    _StepItem(step: '1', title: 'Add Property', description: 'Upload your building and units in one go.', isLast: false, isMobile: true),
                    _StepItem(step: '2', title: 'Invite Tenants', description: 'We send a welcome SMS with their balance.', isLast: false, isMobile: true),
                    _StepItem(step: '3', title: 'Collect Rent', description: 'Payments match automatically.', isLast: false, isMobile: true),
                    _StepItem(step: '4', title: 'Report', description: 'Generate statements instantly.', isLast: true, isMobile: true),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _StepItem(step: '1', title: 'Add Property', description: 'Upload your building and units in one go.', isLast: false, isMobile: false)),
                  Expanded(child: _StepItem(step: '2', title: 'Invite Tenants', description: 'We send a welcome SMS with their balance.', isLast: false, isMobile: false)),
                  Expanded(child: _StepItem(step: '3', title: 'Collect Rent', description: 'Payments match automatically.', isLast: false, isMobile: false)),
                  Expanded(child: _StepItem(step: '4', title: 'Report', description: 'Generate statements instantly.', isLast: true, isMobile: false)),
                ],
              );
            },
          ).animate().fadeIn(delay: 200.ms),
        ],
      ),
    );
  }
}

class _StepItem extends StatelessWidget {
  final String step;
  final String title;
  final String description;
  final bool isLast;
  final bool isMobile;

  const _StepItem({
    required this.step,
    required this.title,
    required this.description,
    required this.isLast,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    if (isMobile) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 32),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildNumber(),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 20)),
                  const SizedBox(height: 8),
                  Text(description, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: isLast ? const SizedBox() : Container(height: 2, color: AppTheme.border, margin: const EdgeInsets.only(right: 16))),
            _buildNumber(),
            Expanded(child: isLast ? const SizedBox() : Container(height: 2, color: AppTheme.border, margin: const EdgeInsets.only(left: 16))),
          ],
        ),
        const SizedBox(height: 24),
        Text(title, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 20), textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(description, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
      ],
    );
  }

  Widget _buildNumber() {
    return Container(
      width: 48,
      height: 48,
      decoration: const BoxDecoration(
        color: AppTheme.navy,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          step,
          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
