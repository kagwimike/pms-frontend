import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../config.dart';

class ClosingBanner extends StatefulWidget {
  const ClosingBanner({super.key});

  @override
  State<ClosingBanner> createState() => _ClosingBannerState();
}

class _ClosingBannerState extends State<ClosingBanner> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _phone = '';
  String _units = '';
  bool _submitted = false;

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      final msg = 'Hi, I am $_name. I manage $_units units and my phone is $_phone. I would like to get started with ${AppConfig.brandName}.';
      final url = Uri.parse('https://wa.me/${AppConfig.whatsappNumber.replaceAll('+', '')}?text=${Uri.encodeComponent(msg)}');
      
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
        setState(() {
          _submitted = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 80),
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.navy, AppTheme.teal],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 800;

          final content = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ready to modernize your property management?',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 16),
              const Text(
                'Join top Kenyan landlords and agents saving time every month. Set up your first building for free.',
                style: TextStyle(color: Colors.white70, fontSize: 18),
              ),
            ],
          );

          final form = Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Get started in minutes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: AppTheme.navy), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                const Text('Create your account and start managing your properties effectively.', style: TextStyle(color: AppTheme.mutedText, fontSize: 16), textAlign: TextAlign.center),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pushNamed('/login'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Create Free Account', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.of(context).pushNamed('/login'),
                  child: const Text('Already have an account? Log in', style: TextStyle(color: AppTheme.navy)),
                ),
              ],
            ),
          );

          if (isMobile) {
            return Column(
              children: [
                content,
                const SizedBox(height: 40),
                form,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: content),
              const SizedBox(width: 60),
              Expanded(child: form),
            ],
          );
        },
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0);
  }
}
