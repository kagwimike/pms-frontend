import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class TestimonialsSection extends StatelessWidget {
  const TestimonialsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final testimonials = [
      {
        'quote': 'PMS Pro cut our overdue rent by 78% in the first quarter. Automated M-Pesa tracking saved our finance team 20+ hours a month.',
        'author': 'Sarah Kimani',
        'company': 'Horizon Crest Properties, Nairobi',
        'initials': 'SK',
      },
      {
        'quote': 'Our caretakers log maintenance issues on-site with photos. Vendors receive tasks instantly, and tenants are updated in real time.',
        'author': 'David Mugisha',
        'company': 'Kigali Ridge Real Estate, Kigali',
        'initials': 'DM',
      },
      {
        'quote': 'Having all leases, deposits, and landlord statements synchronized across our 250 units gave us complete clarity and peace of mind.',
        'author': 'Brenda Ochieng',
        'company': 'Apex Urban Living, Kampala',
        'initials': 'BO',
      },
    ];

    return Container(
      width: double.infinity,
      color: AppTheme.bgGreyGreen,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              Text(
                'Trusted by property businesses.',
                textAlign: TextAlign.center,
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.navy,
                ),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 20,
                runSpacing: 20,
                alignment: WrapAlignment.center,
                children: testimonials.map((t) => _buildTestimonialCard(
                  quote: t['quote']!,
                  author: t['author']!,
                  company: t['company']!,
                  initials: t['initials']!,
                )).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTestimonialCard({
    required String quote,
    required String author,
    required String company,
    required String initials,
  }) {
    return Container(
      width: 340,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(5, (_) => const Icon(Icons.star_rounded, color: AppTheme.brass, size: 18)),
          ),
          const SizedBox(height: 14),
          Text(
            '"$quote"',
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.navy,
              height: 1.45,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: AppTheme.teal,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      author,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.navy, fontSize: 14),
                    ),
                    Text(
                      company,
                      style: const TextStyle(color: AppTheme.mutedText, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
