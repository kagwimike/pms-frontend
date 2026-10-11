import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class FaqSection extends StatelessWidget {
  const FaqSection({super.key});

  @override
  Widget build(BuildContext context) {
    final faqs = [
      {'q': 'What is PMS Pro?', 'a': 'PMS Pro is a complete property-management platform for managing properties, tenants, rent, maintenance, communication, and daily operations from one place.'},
      {'q': 'Who is PMS Pro designed for?', 'a': 'It is built for property managers, landlords, property owners, real-estate companies, caretakers, tenants, and maintenance vendors.'},
      {'q': 'Can I manage multiple properties?', 'a': 'Yes, you can manage an unlimited number of properties, buildings, and units within a single portfolio.'},
      {'q': 'Can tenants use PMS Pro?', 'a': 'Yes, tenants have their own dashboard to pay rent, view their lease, submit maintenance requests, and communicate.'},
      {'q': 'Can property owners access their properties?', 'a': 'Yes, owners can view performance, income, occupancy, and reports for their specific properties.'},
      {'q': 'Can tenants submit maintenance requests?', 'a': 'Absolutely. Tenants can report issues, and managers can assign them directly to maintenance vendors.'},
      {'q': 'Can I manage rent and payments?', 'a': 'Yes, the financial dashboard tracks invoices, rent collected, balances, and payment history.'},
      {'q': 'Does PMS Pro support mobile devices?', 'a': 'Yes, PMS Pro works seamlessly across desktop, tablet, and mobile devices.'},
      {'q': 'Can PMS Pro support multiple user roles?', 'a': 'Yes, we support role-based access control with specific permissions for managers, owners, caretakers, and vendors.'},
      {'q': 'How does PMS Pro handle property documents?', 'a': 'You can securely upload and centralize leases, receipts, inspection reports, and property documents.'},
      {'q': 'Can PMS Pro integrate with payment services?', 'a': 'Yes, PMS Pro integrates with local payment gateways like M-Pesa to automate rent collection and reconciliation.'},
    ];

    return Container(
      width: double.infinity,
      color: AppTheme.bgGreyGreen,
      padding: const EdgeInsets.symmetric(vertical: 100, horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              Text(
                'Frequently Asked Questions',
                textAlign: TextAlign.center,
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 40,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.navy,
                ),
              ),
              const SizedBox(height: 64),
              ...faqs.map((faq) => _buildFaqItem(faq['q']!, faq['a']!)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Theme(
        data: ThemeData(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(
            question,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.navy,
              fontSize: 18,
            ),
          ),
          iconColor: AppTheme.teal,
          collapsedIconColor: AppTheme.navy,
          childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                answer,
                style: const TextStyle(
                  color: AppTheme.mutedText,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
