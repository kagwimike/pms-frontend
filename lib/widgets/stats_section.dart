import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config.dart';
import '../theme/app_theme.dart';

class StatsSection extends StatelessWidget {
  const StatsSection({super.key});

  @override
  Widget build(BuildContext context) {
    if (AppConfig.stats.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      color: AppTheme.navy,
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 700;
              final crossAxisCount = isMobile ? 2 : AppConfig.stats.length;
              
              if (isMobile) {
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 24,
                    mainAxisSpacing: 40,
                    childAspectRatio: 1.5,
                  ),
                  itemCount: AppConfig.stats.length,
                  itemBuilder: (context, index) {
                    final key = AppConfig.stats.keys.elementAt(index);
                    return _StatItem(value: key, label: AppConfig.stats[key]!);
                  },
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: AppConfig.stats.entries.map((e) {
                  return _StatItem(value: e.key, label: e.value);
                }).toList(),
              );
            },
          ),
        ),
      ),
    ).animate().fadeIn().slideY(begin: 0.2, end: 0);
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;

  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.displayMedium?.copyWith(color: AppTheme.brass),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
