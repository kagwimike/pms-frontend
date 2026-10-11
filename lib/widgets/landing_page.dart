import 'package:flutter/material.dart';
import '../../config.dart';
import 'landing/landing_components.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final _featuresKey = GlobalKey();
  final _solutionsKey = GlobalKey();
  final _pricingKey = GlobalKey();
  final _resourcesKey = GlobalKey();

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
          if (constraints.maxWidth >= 900) return const SizedBox.shrink();
          return Drawer(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const SizedBox(height: 40),
                Text(AppConfig.brandName, style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 40),
                ListTile(title: const Text('Product'), onTap: () { Navigator.pop(context); }),
                ListTile(title: const Text('Solutions'), onTap: () { Navigator.pop(context); _scrollTo(_solutionsKey); }),
                ListTile(title: const Text('Features'), onTap: () { Navigator.pop(context); _scrollTo(_featuresKey); }),
                ListTile(title: const Text('Resources'), onTap: () { Navigator.pop(context); _scrollTo(_resourcesKey); }),
                ListTile(title: const Text('Pricing'), onTap: () { Navigator.pop(context); _scrollTo(_pricingKey); }),
              ],
            ),
          );
        },
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.white,
            automaticallyImplyLeading: false, // Hide default drawer button
            flexibleSpace: FlexibleSpaceBar(
              background: NavBarWidget(
                onLoginTap: () => Navigator.pushNamed(context, '/login'),
                onGetStartedTap: () => Navigator.pushNamed(context, '/login'),
              ),
            ),
            toolbarHeight: 80,
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              const HeroCollageSection(),
              const PropertiesSliderSection(),
              const LocationsGridSection(),
              const LandingFooterSection(),
            ]),
          ),
        ],
      ),
    );
  }
}
