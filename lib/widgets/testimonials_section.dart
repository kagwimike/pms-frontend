import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../data/content.dart';
import 'shared_widgets.dart';

class TestimonialsSection extends StatelessWidget {
  const TestimonialsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 80),
      child: Column(
        children: [
          const SectionTitle(
            title: 'Trusted by Kenyan Landlords',
            subtitle: 'Join hundreds of property managers saving time and money.',
          ).animate().fadeIn().slideY(),
          const SizedBox(height: 60),
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 700;
              final crossAxisCount = isMobile ? 1 : 3;
              
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 24,
                mainAxisSpacing: 24,
                childAspectRatio: isMobile ? 1.5 : 0.8,
                children: AppContent.testimonials.asMap().entries.map((entry) {
                  return _TestimonialCard(
                    quote: entry.value['quote']!,
                    author: entry.value['author']!,
                    role: entry.value['role']!,
                    avatarUrl: entry.value['avatarUrl']!,
                    delay: entry.key * 200,
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TestimonialCard extends StatelessWidget {
  final String quote;
  final String author;
  final String role;
  final String avatarUrl;
  final int delay;

  const _TestimonialCard({
    required this.quote,
    required this.author,
    required this.role,
    required this.avatarUrl,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return HoverCard(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.format_quote, color: AppTheme.teal, size: 40),
            const SizedBox(height: 16),
            Expanded(
              child: Text(
                '“$quote”',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.navy,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppTheme.border,
                  child: const Icon(Icons.person, color: AppTheme.mutedText),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(author, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.navy)),
                      Text(role, style: const TextStyle(color: AppTheme.mutedText, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: delay.ms).slideY(begin: 0.2, end: 0);
  }
}
