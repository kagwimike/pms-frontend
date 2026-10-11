import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class TestimonialsSection extends StatelessWidget {
  const TestimonialsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppTheme.bgGreyGreen,
      padding: const EdgeInsets.symmetric(vertical: 100, horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              Text(
                'Trusted by property businesses.',
                textAlign: TextAlign.center,
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 40,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.navy,
                ),
              ),
              const SizedBox(height: 64),
              Wrap(
                spacing: 32,
                runSpacing: 32,
                alignment: WrapAlignment.center,
                children: [
                  _buildTestimonialCard(),
                  _buildTestimonialCard(),
                  _buildTestimonialCard(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTestimonialCard() {
    return Container(
      width: 350,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(5, (_) => const Icon(Icons.star_rounded, color: AppTheme.brass, size: 20)),
          ),
          const SizedBox(height: 24),
          const Text(
            '[Customer testimonial placeholder. A short quote about how PMS Pro improved their property management operations.]',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.navy,
              height: 1.5,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: AppTheme.bgGreyGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person, color: AppTheme.mutedText),
              ),
              const SizedBox(width: 16),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '[Customer Name]',
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.navy, fontSize: 16),
                  ),
                  Text(
                    '[Company]',
                    style: TextStyle(color: AppTheme.mutedText, fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
