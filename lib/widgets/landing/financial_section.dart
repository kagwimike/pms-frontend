import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class FinancialSection extends StatelessWidget {
  const FinancialSection({super.key});

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
                'Know where your property business stands.',
                textAlign: TextAlign.center,
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 40,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.navy,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'A complete financial picture of rent collected, outstanding balances, and expenses.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  color: AppTheme.mutedText,
                ),
              ),
              const SizedBox(height: 64),
              
              // Financial Dashboard Mockup
              Container(
                width: double.infinity,
                height: MediaQuery.of(context).size.width > 768 ? 500 : 300,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.navy.withValues(alpha: 0.05),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                  border: Border.all(color: AppTheme.border),
                  image: const DecorationImage(
                    image: AssetImage('assets/images/financial_dashboard.jpg'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
