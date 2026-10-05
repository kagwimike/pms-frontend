import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import 'shared_widgets.dart';

class PricingSection extends StatefulWidget {
  const PricingSection({super.key});

  @override
  State<PricingSection> createState() => _PricingSectionState();
}

class _PricingSectionState extends State<PricingSection> {
  double _units = 25;

  @override
  Widget build(BuildContext context) {
    int unitsInt = _units.toInt();
    int monthlyPrice = unitsInt * 100; // Example pricing: KSh 100 per unit
    if (monthlyPrice < 1000) monthlyPrice = 1000; // Minimum

    String planName = 'Starter';
    if (unitsInt > 10 && unitsInt <= 50) planName = 'Growth';
    if (unitsInt > 50) planName = 'Portfolio';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 80),
      child: Column(
        children: [
          const SectionTitle(
            title: 'Simple, transparent pricing.',
            subtitle: 'Pay only for what you manage. No hidden fees.',
          ).animate().fadeIn().slideY(),
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppTheme.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              children: [
                Text('How many units do you manage?', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Text('1', style: TextStyle(fontWeight: FontWeight.bold)),
                    Expanded(
                      child: Slider(
                        value: _units,
                        min: 1,
                        max: 80,
                        activeColor: AppTheme.teal,
                        inactiveColor: AppTheme.bgGreyGreen,
                        onChanged: (val) {
                          setState(() {
                            _units = val;
                          });
                        },
                      ),
                    ),
                    const Text('80+', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  '$unitsInt Units',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.navy),
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.bgGreyGreen,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Estimated cost: ', style: Theme.of(context).textTheme.bodyLarge),
                      Text(
                        'KSh $monthlyPrice / month',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.teal),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 60),
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 800;
              final cards = [
                _PlanCard(
                  name: 'Starter',
                  limit: 'Up to 10 units',
                  price: 'KSh 1,000 /mo',
                  features: const ['Basic M-Pesa Matching', 'SMS Reminders', 'Tenant Records'],
                  isHighlighted: false,
                  currentPlan: planName,
                ),
                SizedBox(width: isMobile ? 0 : 24, height: isMobile ? 24 : 0),
                _PlanCard(
                  name: 'Growth',
                  limit: 'Up to 50 units',
                  price: 'KSh 100 /unit',
                  features: const ['Everything in Starter', 'Owner Statements', 'Maintenance Tracking', 'Priority Support'],
                  isHighlighted: true,
                  currentPlan: planName,
                ),
                SizedBox(width: isMobile ? 0 : 24, height: isMobile ? 24 : 0),
                _PlanCard(
                  name: 'Portfolio',
                  limit: '50+ units',
                  price: 'Custom pricing',
                  features: const ['Everything in Growth', 'Custom Integrations', 'Dedicated Account Manager'],
                  isHighlighted: false,
                  currentPlan: planName,
                ),
              ];

              if (isMobile) {
                return Column(children: cards);
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: cards.map((c) => c is SizedBox ? c : Expanded(child: c)).toList(),
              );
            },
          ).animate().fadeIn(delay: 400.ms),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String name;
  final String limit;
  final String price;
  final List<String> features;
  final bool isHighlighted;
  final String currentPlan;

  const _PlanCard({
    required this.name,
    required this.limit,
    required this.price,
    required this.features,
    required this.isHighlighted,
    required this.currentPlan,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = name == currentPlan;
    
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isHighlighted ? AppTheme.navy : AppTheme.white,
        borderRadius: BorderRadius.circular(24),
        border: isHighlighted ? null : Border.all(color: AppTheme.border),
        boxShadow: isActive ? [
          BoxShadow(
            color: AppTheme.teal.withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 2,
          )
        ] : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: TextStyle(color: isHighlighted ? Colors.white : AppTheme.navy, fontWeight: FontWeight.bold, fontSize: 24)),
          const SizedBox(height: 8),
          Text(limit, style: TextStyle(color: isHighlighted ? Colors.white70 : AppTheme.mutedText)),
          const SizedBox(height: 24),
          Text(price, style: TextStyle(color: isHighlighted ? AppTheme.brass : AppTheme.teal, fontWeight: FontWeight.bold, fontSize: 28)),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 24),
          ...features.map((f) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Icon(Icons.check, color: isHighlighted ? AppTheme.whatsappGreen : AppTheme.teal, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text(f, style: TextStyle(color: isHighlighted ? Colors.white : AppTheme.navy))),
              ],
            ),
          )),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isHighlighted ? AppTheme.teal : AppTheme.bgGreyGreen,
                foregroundColor: isHighlighted ? Colors.white : AppTheme.navy,
              ),
              onPressed: () {},
              child: const Text('Get Started'),
            ),
          ),
        ],
      ),
    );
  }
}
