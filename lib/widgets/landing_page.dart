import 'package:flutter/material.dart';
import 'widgets.dart';
import '../config.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final _featuresKey = GlobalKey();
  final _howItWorksKey = GlobalKey();
  final _pricingKey = GlobalKey();
  final _faqKey = GlobalKey();

  void _scrollTo(GlobalKey key) {
    if (key.currentContext != null) {
      Scrollable.ensureVisible(
        key.currentContext!,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 1100) return const SizedBox.shrink();
          return Drawer(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const SizedBox(height: 40),
                Text(AppConfig.brandName, style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 40),
                ListTile(title: const Text('Features'), onTap: () { Navigator.pop(context); _scrollTo(_featuresKey); }),
                ListTile(title: const Text('How it works'), onTap: () { Navigator.pop(context); _scrollTo(_howItWorksKey); }),
                ListTile(title: const Text('Pricing'), onTap: () { Navigator.pop(context); _scrollTo(_pricingKey); }),
                ListTile(title: const Text('FAQ'), onTap: () { Navigator.pop(context); _scrollTo(_faqKey); }),
              ],
            ),
          );
        },
      ),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(child: TopBar()),
              SliverToBoxAdapter(
                child: NavBar(
                  onFeaturesTap: () => _scrollTo(_featuresKey),
                  onHowItWorksTap: () => _scrollTo(_howItWorksKey),
                  onPricingTap: () => _scrollTo(_pricingKey),
                  onFaqTap: () => _scrollTo(_faqKey),
                ),
              ),
              SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: const Column(
                      children: [
                        HeroSection(),
                        BeforeAfterSection(),
                      ],
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                key: _featuresKey,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: const FeaturesSection(),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                key: _howItWorksKey,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: const HowItWorksSection(),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: const TestimonialsSection(),
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: StatsSection(),
              ),
              SliverToBoxAdapter(
                key: _pricingKey,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: const PricingSection(),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                key: _faqKey,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: const FaqSection(),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: const ClosingBanner(),
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: FooterSection(),
              ),
            ],
          ),
          const FloatingWhatsapp(),
        ],
      ),
    );
  }
}
