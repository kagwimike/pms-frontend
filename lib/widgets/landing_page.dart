import 'package:flutter/material.dart';
import '../../config.dart';
import '../../theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'landing/landing_components.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _productKey = GlobalKey();
  final GlobalKey _solutionsKey = GlobalKey();
  final GlobalKey _featuresKey = GlobalKey();
  final GlobalKey _resourcesKey = GlobalKey();
  final GlobalKey _pricingKey = GlobalKey();

  int _selectedRoleIndex = 0;

  void _scrollTo(GlobalKey key) {
    void execute() {
      final context = key.currentContext;
      if (context != null) {
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 650),
          curve: Curves.easeInOutCubic,
          alignment: 0.0,
        );
      }
    }

    if (key.currentContext != null) {
      execute();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => execute());
    }
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 960) return const SizedBox.shrink();
          return Drawer(
            backgroundColor: Colors.white,
            child: SafeArea(
              child: Column(
                children: [
                  // Drawer Brand Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppTheme.teal,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.maps_home_work_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          AppConfig.brandName,
                          style: GoogleFonts.bricolageGrotesque(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.navy,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: AppTheme.navy),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: AppTheme.border, height: 1),

                  // Navigation Items
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      children: [
                        ListTile(
                          leading: const Icon(Icons.dashboard_customize_rounded, color: AppTheme.teal),
                          title: Text(
                            'Product',
                            style: GoogleFonts.dmSans(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          subtitle: const Text('Workflow, steps & device showcase'),
                          onTap: () {
                            Navigator.pop(context);
                            _scrollTo(_productKey);
                          },
                        ),
                        ExpansionTile(
                          leading: const Icon(Icons.people_outline_rounded, color: AppTheme.teal),
                          title: Text(
                            'Solutions',
                            style: GoogleFonts.dmSans(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          subtitle: const Text('Tailored by user role'),
                          childrenPadding: const EdgeInsets.only(left: 32, bottom: 8),
                          children: [
                            _buildDrawerRoleItem('Property Managers', 0),
                            _buildDrawerRoleItem('Property Owners', 1),
                            _buildDrawerRoleItem('Caretakers', 2),
                            _buildDrawerRoleItem('Tenants', 3),
                            _buildDrawerRoleItem('Maintenance Vendors', 4),
                          ],
                        ),
                        ListTile(
                          leading: const Icon(Icons.apartment_rounded, color: AppTheme.teal),
                          title: Text(
                            'Features',
                            style: GoogleFonts.dmSans(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          subtitle: const Text('Rent, maintenance, tenants & leases'),
                          onTap: () {
                            Navigator.pop(context);
                            _scrollTo(_featuresKey);
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.help_outline_rounded, color: AppTheme.teal),
                          title: Text(
                            'Resources',
                            style: GoogleFonts.dmSans(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          subtitle: const Text('FAQs, security & client testimonials'),
                          onTap: () {
                            Navigator.pop(context);
                            _scrollTo(_resourcesKey);
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.sell_outlined, color: AppTheme.teal),
                          title: Text(
                            'Pricing',
                            style: GoogleFonts.dmSans(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          subtitle: const Text('Starter, Pro & Enterprise plans'),
                          onTap: () {
                            Navigator.pop(context);
                            _scrollTo(_pricingKey);
                          },
                        ),
                      ],
                    ),
                  ),

                  // Bottom Action Buttons
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.pushNamed(context, '/login');
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.navy,
                              side: const BorderSide(color: AppTheme.border),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Log in', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.pushNamed(context, '/register');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.teal,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Get Started', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      body: Column(
        children: [
          NavBarWidget(
            onBrandTap: _scrollToTop,
            onProductTap: () => _scrollTo(_productKey),
            onSolutionsTap: () => _scrollTo(_solutionsKey),
            onFeaturesTap: () => _scrollTo(_featuresKey),
            onResourcesTap: () => _scrollTo(_resourcesKey),
            onPricingTap: () => _scrollTo(_pricingKey),
            onSelectRole: (roleIdx) {
              setState(() => _selectedRoleIndex = roleIdx);
              _scrollTo(_solutionsKey);
            },
            onLoginTap: () => Navigator.pushNamed(context, '/login'),
            onGetStartedTap: () => Navigator.pushNamed(context, '/register'),
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                children: [
                  const HeroCollageSection(),
                  const LocationsGridSection(),

                  // Product
                  KeyedSubtree(
                    key: _productKey,
                    child: const HowItWorksSection(),
                  ),

                  // Solutions
                  KeyedSubtree(
                    key: _solutionsKey,
                    child: RoleExperienceSection(
                      selectedRoleIndex: _selectedRoleIndex,
                      onRoleChanged: (idx) {
                        setState(() => _selectedRoleIndex = idx);
                      },
                    ),
                  ),

                  // Features
                  KeyedSubtree(
                    key: _featuresKey,
                    child: const CondensedFeaturesSection(),
                  ),

                  // Pricing
                  KeyedSubtree(
                    key: _pricingKey,
                    child: PricingPreview(
                      onViewPricingTap: () => Navigator.pushNamed(context, '/register'),
                    ),
                  ),

                  // Resources
                  KeyedSubtree(
                    key: _resourcesKey,
                    child: const Column(
                      children: [
                        TestimonialsSection(),
                        FaqSection(),
                      ],
                    ),
                  ),

                  // Final CTA
                  FinalCTA(
                    onGetStartedTap: () => Navigator.pushNamed(context, '/register'),
                    onTalkToUsTap: () => _scrollTo(_resourcesKey),
                  ),

                  // Footer
                  const LandingFooterSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerRoleItem(String title, int roleIdx) {
    return ListTile(
      dense: true,
      title: Text(title, style: const TextStyle(fontSize: 14)),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppTheme.mutedText),
      onTap: () {
        Navigator.pop(context);
        setState(() => _selectedRoleIndex = roleIdx);
        _scrollTo(_solutionsKey);
      },
    );
  }
}
