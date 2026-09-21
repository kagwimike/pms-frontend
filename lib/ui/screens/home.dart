import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // State for hero dashboard occupancy filter: 'All', '1M', '6M', '1Y'
  String _selectedTimeFilter = '6M';
  String _activeNav = 'Home';

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. NAVBAR
            _buildNavbar(context, isMobile),

            // 2. HERO SECTION
            _buildHeroSection(context, isMobile),

            // 3. WHY CHOOSE US SECTION (DARK BACKGROUND)
            _buildWhyChooseUsSection(context, isMobile),

            // 4. MILESTONES/STATS SECTION
            _buildMilestonesSection(context, isMobile),

            // 5. FEATURES SECTION
            _buildFeaturesSection(context, isMobile),

            // 6. SOLUTIONS SECTION
            _buildSolutionsSection(context, isMobile),

            // 7. RESOURCES SECTION
            _buildResourcesSection(context, isMobile),

            // FOOTER
            _buildFooter(context, isMobile),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 1. NAVBAR
  // ==========================================
  Widget _buildNavbar(BuildContext context, bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20.0 : 64.0,
        vertical: 18.0,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // LOGO ON LEFT
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.home_work_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  RichText(
                    text: const TextSpan(
                      children: [
                        TextSpan(
                          text: 'RentPro ',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                            fontFamily: 'Roboto',
                          ),
                        ),
                        TextSpan(
                          text: 'KE',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0D9488),
                            fontFamily: 'Roboto',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          // CENTER NAV LINKS (Desktop)
          if (!isMobile)
            Row(
              children: ['Home', 'Features', 'Pricing', 'Blog', 'Contact'].map((item) {
                final isActive = item == _activeNav;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _activeNav = item;
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            item,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                              color: isActive ? const Color(0xFF0D9488) : const Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(height: 4),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            height: 2.5,
                            width: isActive ? 24 : 0,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0D9488),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

          // PROMINENT "JOIN NOW" BUTTON (Far Right)
          if (!isMobile)
            ElevatedButton(
              onPressed: () {
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                if (authProvider.isAuthenticated) {
                  context.go('/properties');
                } else {
                  context.go('/register');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D9488),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: Text(
                Provider.of<AuthProvider>(context).isAuthenticated ? 'Dashboard' : 'Join now',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )

          else
            IconButton(
              icon: const Icon(Icons.menu_rounded, color: Color(0xFF0F172A), size: 28),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Menu tapped')),
                );
              },
            ),
        ],
      ),
    );
  }

  // ==========================================
  // 2. HERO SECTION
  // ==========================================
  Widget _buildHeroSection(BuildContext context, bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20.0 : 64.0,
        vertical: isMobile ? 40.0 : 72.0,
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeroTextContent(isMobile),
                const SizedBox(height: 40),
                _buildHeroDashboardMockup(isMobile),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  flex: 5,
                  child: _buildHeroTextContent(isMobile),
                ),
                const SizedBox(width: 48),
                Expanded(
                  flex: 6,
                  child: _buildHeroDashboardMockup(isMobile),
                ),
              ],
            ),
    );
  }

  Widget _buildHeroTextContent(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Small eyebrow label above headline
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFFCCFBF1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF99F6E4)),
          ),
          child: const Text(
            'EARN MORE. SAVE TIME.',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F766E),
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Large bold headline
        const Text(
          'Property Management Software Built For Kenya.',
          style: TextStyle(
            fontSize: 42,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
            height: 1.15,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 20),

        // Supporting paragraph
        const Text(
          'Collect more rent owed, fill vacant units faster, and save endless hours of administrative hassle through automated M-Pesa invoicing and tenant reconciliation.',
          style: TextStyle(
            fontSize: 17,
            color: Color(0xFF475569),
            height: 1.6,
          ),
        ),
        const SizedBox(height: 32),

        // CTA Buttons
        Wrap(
          spacing: 16,
          runSpacing: 12,
          children: [
            ElevatedButton(
              onPressed: () {
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                if (authProvider.isAuthenticated) {
                  context.go('/properties');
                } else {
                  context.go('/register');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D9488),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 2,
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Start Free Trial',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ),
            ),
            OutlinedButton(
              onPressed: () {
                context.go('/contact');
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0F172A),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Schedule Demo',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),

          ],
        ),

        const SizedBox(height: 28),
        Row(
          children: const [
            Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20),
            SizedBox(width: 8),
            Text('M-Pesa STK Push Integrated', style: TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w600)),
            SizedBox(width: 16),
            Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20),
            SizedBox(width: 8),
            Text('No Credit Card Required', style: TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }

  // Large Mockup/Screenshot of Product Dashboard
  Widget _buildHeroDashboardMockup(bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withValues(alpha: 0.15),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
        border: Border.all(color: const Color(0xFF1E293B), width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Mockup browser window header bar
          Container(
            color: const Color(0xFF1E293B),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Row(
                  children: [
                    Container(width: 10, height: 10, decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Container(width: 10, height: 10, decoration: const BoxDecoration(color: Color(0xFFF59E0B), shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Container(width: 10, height: 10, decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle)),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'app.rentpro.co.ke/dashboard',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Dashboard Body: Sidebar + Main Stats Panel
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sidebar Navigation
              if (!isMobile)
                Container(
                  width: 170,
                  color: const Color(0xFF111827),
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSidebarItem(Icons.dashboard_rounded, 'Dashboard', isSelected: true),
                      _buildSidebarItem(Icons.add_box_rounded, 'Add listing'),
                      _buildSidebarItem(Icons.holiday_village_rounded, 'My listings'),
                      _buildSidebarItem(Icons.people_outline_rounded, 'List of Agents'),
                      _buildSidebarItem(Icons.person_add_outlined, 'Add an agent'),
                      _buildSidebarItem(Icons.group_work_rounded, 'Our Clients'),
                      _buildSidebarItem(Icons.person_add_alt_1_rounded, 'Add a client'),
                      _buildSidebarItem(Icons.pie_chart_outline_rounded, 'Our Portfolio'),
                    ],
                  ),
                ),

              // Dashboard Main Content
              Expanded(
                child: Container(
                  color: const Color(0xFF0F172A),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Stat Cards Row
                      Row(
                        children: [
                          // Revenue stat card
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E293B),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFF334155)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text('Total Rent Collected', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                                  SizedBox(height: 6),
                                  Text('KES 14,850,000', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                                  SizedBox(height: 4),
                                  Text('+18.4% vs last month', style: TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Property-views stat card with sparkline
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E293B),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFF334155)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Property Views', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Flexible(child: Text('48,290 Views', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                                      // Sparkline icon representation
                                      const Icon(Icons.show_chart_rounded, color: Color(0xFF0D9488), size: 20),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  const Text('High interest in Kilimani', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 10)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Pie chart panel titled "Occupancy Rate" with Time-Range Filter
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFF334155)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header with Title & Time Range Filter
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Occupancy Rate',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                // Time-range filter buttons (All / 1M / 6M / 1Y)
                                Row(
                                  children: ['All', '1M', '6M', '1Y'].map((filter) {
                                    final isSelected = _selectedTimeFilter == filter;
                                    return InkWell(
                                      onTap: () {
                                        setState(() {
                                          _selectedTimeFilter = filter;
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        margin: const EdgeInsets.only(left: 4),
                                        decoration: BoxDecoration(
                                          color: isSelected ? const Color(0xFF0D9488) : const Color(0xFF0F172A),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          filter,
                                          style: TextStyle(
                                            color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                                            fontSize: 10,
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Pie Chart & Property Breakdowns
                            Row(
                              children: [
                                // Custom Occupancy Pie Chart Graphic
                                SizedBox(
                                  width: 80,
                                  height: 80,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      CircularProgressIndicator(
                                        value: _selectedTimeFilter == '1M' ? 0.88 : (_selectedTimeFilter == '1Y' ? 0.96 : 0.94),
                                        strokeWidth: 10,
                                        backgroundColor: const Color(0xFF334155),
                                        color: const Color(0xFF0D9488),
                                      ),
                                      Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            _selectedTimeFilter == '1M' ? '88%' : (_selectedTimeFilter == '1Y' ? '96%' : '94%'),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                          ),
                                          const Text(
                                            'Avg',
                                            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),

                                // Property Breakdown List with Tenant counts & percentages
                                Expanded(
                                  child: Column(
                                    children: [
                                      _buildOccupancyPropertyRow('Kilimani Heights', '45 units', '94%', const Color(0xFF0D9488)),
                                      const SizedBox(height: 6),
                                      _buildOccupancyPropertyRow('Westlands Towers', '32 units', '98%', const Color(0xFF10B981)),
                                      const SizedBox(height: 6),
                                      _buildOccupancyPropertyRow('Karen Villas', '18 units', '88%', const Color(0xFFF59E0B)),
                                      const SizedBox(height: 6),
                                      _buildOccupancyPropertyRow('Parklands Suites', '25 units', '92%', const Color(0xFF38BDF8)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(IconData icon, String title, {bool isSelected = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0D9488).withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: isSelected ? const Color(0xFF2DD4BF) : const Color(0xFF94A3B8)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOccupancyPropertyRow(String name, String count, String percent, Color dotColor) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(name, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500)),
        ),
        Text(count, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
        const SizedBox(width: 8),
        Text(percent, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
      ],
    );
  }

  // ==========================================
  // 3. WHY CHOOSE US SECTION (DARK BACKGROUND)
  // ==========================================
  Widget _buildWhyChooseUsSection(BuildContext context, bool isMobile) {
    return Container(
      width: double.infinity,
      color: const Color(0xFF0B132B), // Dark contrasting background
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20.0 : 64.0,
        vertical: isMobile ? 50.0 : 80.0,
      ),
      child: Column(
        children: [
          // Small uppercase eyebrow label
          const Text(
            'WHY EVERYONE CHOOSES RENTPRO KENYA',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Color(0xFF2DD4BF),
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),

          // Heading with highlighted phrase & hand-drawn style underline
          Column(
            children: [
              RichText(
                textAlign: TextAlign.center,
                text: const TextSpan(
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.2,
                  ),
                  children: [
                    TextSpan(text: 'Built to do the '),
                    TextSpan(
                      text: 'hard parts',
                      style: TextStyle(color: Color(0xFF5EEAD4)),
                    ),
                    TextSpan(text: ' for you.'),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              // Hand-drawn wave underline SVG style
              CustomPaint(
                size: const Size(180, 10),
                painter: HandDrawnUnderlinePainter(),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Subtext
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: const Text(
              'Every single feature in RentPro Kenya is engineered with one goal: either help you earn more rental income or save you time and administrative costs.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF94A3B8),
                height: 1.6,
              ),
            ),
          ),
          const SizedBox(height: 48),

          // Two side-by-side cards below
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 768) {
                return Column(
                  children: [
                    _buildWhyCard(
                      title: 'Get paid on time',
                      description: 'Automate monthly rent invoicing via SMS and M-Pesa STK push. Send automatic payment reminders before due dates and automate overdue follow-ups effortlessly.',
                      linkText: 'Explore automated rent reminders →',
                    ),
                    const SizedBox(height: 24),
                    _buildWhyCard(
                      title: 'Reconcile payments automatically',
                      description: 'Automatically match incoming M-Pesa transactions and bank payments to the exact tenant, lease, and unit. Issue digital receipts in seconds without human error.',
                      linkText: 'Explore payment reconciliation →',
                    ),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(
                    child: _buildWhyCard(
                      title: 'Get paid on time',
                      description: 'Automate monthly rent invoicing via SMS and M-Pesa STK push. Send automatic payment reminders before due dates and automate overdue follow-ups effortlessly.',
                      linkText: 'Explore automated rent reminders →',
                    ),
                  ),
                  const SizedBox(width: 32),
                  Expanded(
                    child: _buildWhyCard(
                      title: 'Reconcile payments automatically',
                      description: 'Automatically match incoming M-Pesa transactions and bank payments to the exact tenant, lease, and unit. Issue digital receipts in seconds without human error.',
                      linkText: 'Explore payment reconciliation →',
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWhyCard({
    required String title,
    required String description,
    required String linkText,
  }) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 15, offset: Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0D9488).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.bolt_rounded, color: Color(0xFF2DD4BF), size: 28),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFFCBD5E1),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 24),
          InkWell(
            onTap: () {},
            child: Text(
              linkText,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2DD4BF),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 4. MILESTONES / STATS SECTION
  // ==========================================
  Widget _buildMilestonesSection(BuildContext context, bool isMobile) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20.0 : 64.0,
        vertical: isMobile ? 50.0 : 80.0,
      ),
      child: Column(
        children: [
          const Text(
            'Milestones',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0D9488),
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Just a few numbers.',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Real usage figures verified across landlords, property managers, and agencies in Kenya as of September 2026.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 48),

          // 4 Stat blocks in a row
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 640) {
                return Column(
                  children: [
                    _buildStatBlock(Icons.home_outlined, '25,000+', 'Rental Units Managed'),
                    const SizedBox(height: 24),
                    _buildStatBlock(Icons.receipt_long_rounded, 'KES 2.4B+', 'Rent Tracked & Auto-Reconciled'),
                    const SizedBox(height: 24),
                    _buildStatBlock(Icons.people_outline_rounded, '1,200+', 'Landlords, Agents & Agencies'),
                    const SizedBox(height: 24),
                    _buildStatBlock(Icons.description_outlined, '450,000+', 'Invoices Generated & Issued'),
                  ],
                );
              } else if (constraints.maxWidth < 1024) {
                return Wrap(
                  spacing: 24,
                  runSpacing: 24,
                  alignment: WrapAlignment.center,
                  children: [
                    SizedBox(width: constraints.maxWidth / 2 - 24, child: _buildStatBlock(Icons.home_outlined, '25,000+', 'Rental Units Managed')),
                    SizedBox(width: constraints.maxWidth / 2 - 24, child: _buildStatBlock(Icons.receipt_long_rounded, 'KES 2.4B+', 'Rent Tracked & Auto-Reconciled')),
                    SizedBox(width: constraints.maxWidth / 2 - 24, child: _buildStatBlock(Icons.people_outline_rounded, '1,200+', 'Landlords, Agents & Agencies')),
                    SizedBox(width: constraints.maxWidth / 2 - 24, child: _buildStatBlock(Icons.description_outlined, '450,000+', 'Invoices Generated & Issued')),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: _buildStatBlock(Icons.home_outlined, '25,000+', 'Rental Units Managed')),
                  Expanded(child: _buildStatBlock(Icons.receipt_long_rounded, 'KES 2.4B+', 'Rent Tracked & Auto-Reconciled')),
                  Expanded(child: _buildStatBlock(Icons.people_outline_rounded, '1,200+', 'Landlords, Agents & Agencies')),
                  Expanded(child: _buildStatBlock(Icons.description_outlined, '450,000+', 'Invoices Generated & Issued')),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatBlock(IconData icon, String number, String label) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          // Icon in bordered square
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: Icon(icon, color: const Color(0xFF0D9488), size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            number,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 5. FEATURES SECTION
  // ==========================================
  Widget _buildFeaturesSection(BuildContext context, bool isMobile) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFF1F5F9),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20.0 : 64.0,
        vertical: isMobile ? 50.0 : 80.0,
      ),
      child: Column(
        children: [
          const Text(
            'Empowering You with a Full Range of Features.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Unparalleled functionality designed to optimize real estate operations and enhance decision-making.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 48),

          // 4-column grid of feature categories
          LayoutBuilder(
            builder: (context, constraints) {
              int cols = 4;
              if (constraints.maxWidth < 640) {
                cols = 1;
              } else if (constraints.maxWidth < 1024) {
                cols = 2;
              }

              final featuresData = [
                {
                  'title': 'Financial Management',
                  'items': [
                    'digital invoicing',
                    'online rent collection',
                    'automated payment reconciliation',
                    'digital bookkeeping',
                    'reporting tools',
                  ]
                },
                {
                  'title': 'Marketing & Listings',
                  'items': [
                    'custom website creation',
                    'listing syndication',
                    'listing uploads',
                    'short-stay management',
                    'SEO optimization',
                  ]
                },
                {
                  'title': 'Communication & Notifications',
                  'items': [
                    'bulk text messaging',
                    'automated alerts',
                    'tenant communication',
                    'email invoices/alerts',
                    'broadcast reminders',
                  ]
                },
                {
                  'title': 'Data Management & Integration',
                  'items': [
                    'data migration',
                    'secure document/image backup',
                    'analytics dashboard',
                    'API integration',
                    'multi-user permission roles',
                  ]
                },
              ];

              if (cols == 1) {
                return Column(
                  children: featuresData.map((cat) => Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: _buildFeatureCategoryCard(cat['title'] as String, cat['items'] as List<String>),
                  )).toList(),
                );
              } else if (cols == 2) {
                return Wrap(
                  spacing: 24,
                  runSpacing: 24,
                  children: featuresData.map((cat) => SizedBox(
                    width: (constraints.maxWidth - 24) / 2,
                    child: _buildFeatureCategoryCard(cat['title'] as String, cat['items'] as List<String>),
                  )).toList(),
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: featuresData.map((cat) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: _buildFeatureCategoryCard(cat['title'] as String, cat['items'] as List<String>),
                  ),
                )).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCategoryCard(String title, List<String> items) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 16),
          Column(
            children: items.map((item) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Color(0xFFD1FAE5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check, color: Color(0xFF059669), size: 14),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF334155),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 6. SOLUTIONS SECTION
  // ==========================================
  Widget _buildSolutionsSection(BuildContext context, bool isMobile) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20.0 : 64.0,
        vertical: isMobile ? 50.0 : 80.0,
      ),
      child: Column(
        children: [
          const Text(
            'Solutions for every property business in Kenya.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Purpose-built for the local rental market, with tailored setups for how people operate.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 48),

          // 3x2 Grid of solution cards
          LayoutBuilder(
            builder: (context, constraints) {
              final solutions = [
                {
                  'icon': Icons.house_rounded,
                  'title': 'Kenyan landlords',
                  'desc': 'Collecting rent and tracking arrears effortlessly, from a few units to large multi-building portfolios.',
                },
                {
                  'icon': Icons.business_center_rounded,
                  'title': 'Property managers & agencies',
                  'desc': 'Multi-owner portfolios, automated per-owner remittance reporting, and team access permissions.',
                },
                {
                  'icon': Icons.public_rounded,
                  'title': 'Diaspora property owners',
                  'desc': 'Remote property management with real-time payment visibility and bank deposit alerts from anywhere.',
                },
                {
                  'icon': Icons.school_rounded,
                  'title': 'Student-hostel operators',
                  'desc': 'Room assignment, individual bed occupancy tracking, semester billing cycles, and maintenance tracking.',
                },
                {
                  'icon': Icons.apartment_rounded,
                  'title': 'Airbnb & short-let hosts',
                  'desc': 'Seamlessly manage short stays and calendar bookings right alongside your long-term rentals.',
                },
                {
                  'icon': Icons.location_city_rounded,
                  'title': 'Gated communities & estates',
                  'desc': 'Automated service-charge billing, amenity access collections, and resident communication records.',
                },
              ];

              if (constraints.maxWidth < 640) {
                return Column(
                  children: solutions.map((s) => Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: _buildSolutionCard(s['icon'] as IconData, s['title'] as String, s['desc'] as String),
                  )).toList(),
                );
              }

              return Wrap(
                spacing: 24,
                runSpacing: 24,
                children: solutions.map((s) => SizedBox(
                  width: constraints.maxWidth < 1024 ? (constraints.maxWidth - 24) / 2 : (constraints.maxWidth - 48) / 3,
                  child: _buildSolutionCard(s['icon'] as IconData, s['title'] as String, s['desc'] as String),
                )).toList(),
              );
            },
          ),
          const SizedBox(height: 36),

          // Centered "View all solutions →" link
          InkWell(
            onTap: () {},
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'View all solutions',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0D9488),
                  ),
                ),
                SizedBox(width: 6),
                Icon(Icons.arrow_forward_rounded, color: Color(0xFF0D9488), size: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSolutionCard(IconData icon, String title, String desc) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Color(0xFFCCFBF1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF0F766E), size: 22),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            desc,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 7. RESOURCES SECTION
  // ==========================================
  Widget _buildResourcesSection(BuildContext context, bool isMobile) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFF8FAFC),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20.0 : 64.0,
        vertical: isMobile ? 50.0 : 80.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resources.',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 36),

          // 3-column grid of resource/blog cards
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 768) {
                return Column(
                  children: [
                    _buildGuideCard(),
                    const SizedBox(height: 24),
                    _buildAtmosphericCard(),
                    const SizedBox(height: 24),
                    _buildComparisonCard(),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildGuideCard()),
                  const SizedBox(width: 24),
                  Expanded(child: _buildAtmosphericCard()),
                  const SizedBox(width: 24),
                  Expanded(child: _buildComparisonCard()),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // Card 1: Guide-style article with image of laptop + calculator
  Widget _buildGuideCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 180,
            width: double.infinity,
            child: Image.asset(
              'assets/images/guide_laptop.jpg',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Image.network(
                  'https://images.unsplash.com/photo-1554224155-6726b3ff858f?q=80&w=1000&auto=format&fit=crop',
                  fit: BoxFit.cover,
                  errorBuilder: (context, err, stack) => Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
                      ),
                    ),
                    child: const Center(
                      child: Icon(Icons.calculate_rounded, size: 54, color: Colors.white),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('GUIDE', style: TextStyle(color: Color(0xFF0D9488), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1)),
                SizedBox(height: 8),
                Text(
                  'Automating Rent Collection & M-Pesa Reconciliation in Kenya',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                ),
                SizedBox(height: 8),
                Text(
                  'A practical step-by-step playbook for Kenyan landlords looking to reduce rent default rates and eliminate manual payment matching.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Card 2: Blog teaser card with full-bleed atmospheric photo (sunset skyline)
  Widget _buildAtmosphericCard() {
    return Container(
      height: 340,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/nairobi_sunset.jpg',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Image.network(
                  'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?q=80&w=1000&auto=format&fit=crop',
                  fit: BoxFit.cover,
                  errorBuilder: (context, err, stack) => Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF0B132B), Color(0xFF1E293B)],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.2),
                    Colors.black.withValues(alpha: 0.85),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('INDUSTRY INSIGHTS', style: TextStyle(color: Color(0xFF5EEAD4), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1)),
                SizedBox(height: 8),
                Text(
                  'Navigating Kenya’s Rental Market & Arrears Trends in 2026',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white, height: 1.3),
                ),
                SizedBox(height: 8),
                Text(
                  'Key data on urban occupancy rates across Nairobi, Mombasa and Kisumu.',
                  style: TextStyle(fontSize: 13, color: Color(0xFFCBD5E1)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Card 3: Comparison-style article card showing split dashboard screenshot
  Widget _buildComparisonCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 180,
            width: double.infinity,
            child: Image.asset(
              'assets/images/split_comparison.jpg',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Image.network(
                  'https://images.unsplash.com/photo-1460925895917-afdab827c52f?q=80&w=1000&auto=format&fit=crop',
                  fit: BoxFit.cover,
                  errorBuilder: (context, err, stack) => Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                      ),
                    ),
                    child: const Center(
                      child: Icon(Icons.dashboard_rounded, size: 54, color: Colors.white),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('COMPARISON', style: TextStyle(color: Color(0xFF0D9488), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1)),
                SizedBox(height: 8),
                Text(
                  'Manual Excel Bookkeeping vs Cloud Software: ROI Analysis',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                ),
                SizedBox(height: 8),
                Text(
                  'Discover how switching from paper ledgers saves an average of 14 hours per week and boosts collection efficiency by 34%.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  // ==========================================
  // FOOTER
  // ==========================================
  Widget _buildFooter(BuildContext context, bool isMobile) {
    return Container(
      color: const Color(0xFF0F172A),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20.0 : 64.0,
        vertical: 48.0,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D9488),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.home_work_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'RentPro KE',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Text(
                '© 2026 RentPro Kenya. Built for real estate success in East Africa.',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Custom Painter for Hand-Drawn SVG Underline Effect
class HandDrawnUnderlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2DD4BF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(0, size.height * 0.5);
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.9,
      size.width * 0.5,
      size.height * 0.4,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.1,
      size.width,
      size.height * 0.6,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
