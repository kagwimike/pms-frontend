import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class FaqSection extends StatefulWidget {
  const FaqSection({super.key});

  @override
  State<FaqSection> createState() => _FaqSectionState();
}

class _FaqSectionState extends State<FaqSection> {
  bool _showAll = false;

  final List<Map<String, String>> _faqs = const [
    {'q': 'What is PMS Pro?', 'a': 'PMS Pro is a complete property-management platform for managing properties, tenants, rent, maintenance, communication, and daily operations from one place.'},
    {'q': 'Who is PMS Pro designed for?', 'a': 'It is built for property managers, landlords, property owners, real-estate companies, caretakers, tenants, and maintenance vendors.'},
    {'q': 'Can I manage multiple properties?', 'a': 'Yes, you can manage an unlimited number of properties, buildings, and units within a single portfolio.'},
    {'q': 'Can tenants use PMS Pro?', 'a': 'Yes, tenants have their own dashboard to pay rent, view their lease, submit maintenance requests, and communicate.'},
    {'q': 'Can PMS Pro integrate with payment services?', 'a': 'Yes, PMS Pro integrates with local payment gateways like M-Pesa to automate rent collection and reconciliation.'},
    {'q': 'Can property owners access their properties?', 'a': 'Yes, owners can view performance, income, occupancy, and reports for their specific properties.'},
    {'q': 'Can tenants submit maintenance requests?', 'a': 'Absolutely. Tenants can report issues, and managers can assign them directly to maintenance vendors.'},
    {'q': 'Can I manage rent and payments?', 'a': 'Yes, the financial dashboard tracks invoices, rent collected, balances, and payment history.'},
    {'q': 'Does PMS Pro support mobile devices?', 'a': 'Yes, PMS Pro works seamlessly across desktop, tablet, and mobile devices.'},
    {'q': 'Can PMS Pro support multiple user roles?', 'a': 'Yes, we support role-based access control with specific permissions for managers, owners, caretakers, and vendors.'},
    {'q': 'How does PMS Pro handle property documents?', 'a': 'You can securely upload and centralize leases, receipts, inspection reports, and property documents.'},
  ];

  @override
  Widget build(BuildContext context) {
    final displayedFaqs = _showAll ? _faqs : _faqs.take(5).toList();

    return Container(
      width: double.infinity,
      color: AppTheme.bgGreyGreen,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              Text(
                'Frequently Asked Questions',
                textAlign: TextAlign.center,
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.navy,
                ),
              ),
              const SizedBox(height: 24),
              ...displayedFaqs.map((faq) => _buildFaqItem(faq['q']!, faq['a']!)),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => setState(() => _showAll = !_showAll),
                icon: Icon(_showAll ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, color: AppTheme.teal, size: 20),
                label: Text(
                  _showAll ? 'Show fewer questions' : 'View all ${_faqs.length} questions',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.navy),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.border),
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: Theme(
          data: ThemeData(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            title: Text(
              question,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.navy,
                fontSize: 15,
              ),
            ),
            iconColor: AppTheme.teal,
            collapsedIconColor: AppTheme.navy,
            childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  answer,
                  style: const TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 14,
                    height: 1.45,
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
