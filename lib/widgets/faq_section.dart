import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import 'shared_widgets.dart';

class FaqSection extends StatelessWidget {
  const FaqSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 80),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 900;
          
          final leftCol = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Frequently Asked Questions', style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 24),
              Text('Everything you need to know about getting started.', style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.bgGreyGreen,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Have more questions?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    SizedBox(height: 12),
                    Text('Our team is ready to help you out.', style: TextStyle(color: AppTheme.mutedText)),
                    SizedBox(height: 24),
                    WhatsappButton(),
                  ],
                ),
              ),
            ],
          ).animate().fadeIn().slideX();

          final rightCol = const Column(
            children: const [
              _FaqTile(
                question: 'Do my tenants need to download an app?',
                answer: 'No. Tenants receive simple SMS notifications and can pay using normal M-Pesa. There is no app for them to download.',
              ),
              _FaqTile(
                question: 'Can I use my existing Paybill or Till number?',
                answer: 'Yes! We integrate with your existing C2B Paybill or Till number so funds go directly to your account. We do not hold your money.',
              ),
              _FaqTile(
                question: 'I manage properties for other owners. Does this work for me?',
                answer: 'Absolutely. You can create multiple properties, assign them to different owners, and generate commission-deducted owner statements.',
              ),
              _FaqTile(
                question: 'Can you help me import my existing Excel records?',
                answer: 'Yes, our onboarding team will help you migrate your data from Excel or other systems completely free of charge.',
              ),
              _FaqTile(
                question: 'How secure is my data?',
                answer: 'We use bank-level encryption. Your tenant data and payment records are private, backed up daily, and only accessible by you.',
              ),
            ],
          ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.1, end: 0);

          if (isMobile) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                leftCol,
                const SizedBox(height: 40),
                rightCol,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 1, child: leftCol),
              const SizedBox(width: 80),
              Expanded(flex: 2, child: rightCol),
            ],
          );
        },
      ),
    );
  }
}

class _FaqTile extends StatefulWidget {
  final String question;
  final String answer;

  const _FaqTile({required this.question, required this.answer});

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: AppTheme.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.border),
        ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(widget.question, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.navy)),
          iconColor: AppTheme.teal,
          collapsedIconColor: AppTheme.navy,
          onExpansionChanged: (val) => setState(() => _isExpanded = val),
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
              child: Text(widget.answer, style: const TextStyle(color: AppTheme.mutedText, height: 1.5)),
            ),
          ],
        ),
        ),
      ),
    );
  }
}
