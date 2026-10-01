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
            child: _submitted 
              ? const Column(
                  children: [
                    Icon(Icons.check_circle, color: AppTheme.whatsappGreen, size: 64),
                    SizedBox(height: 16),
                    Text('Thanks! We will reply on WhatsApp shortly.', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  ],
                )
              : Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Request a callback or setup', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 24),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
                    validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    onSaved: (val) => _name = val!,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Phone (e.g. 0700000000)', border: OutlineInputBorder()),
                    keyboardType: TextInputType.phone,
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Required';
                      if (!RegExp(r'^[0-9+]{9,15}$').hasMatch(val)) return 'Invalid phone';
                      return null;
                    },
                    onSaved: (val) => _phone = val!,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Number of Units', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Required';
                      if (int.tryParse(val) == null || int.parse(val) <= 0) return 'Must be a positive number';
                      return null;
                    },
                    onSaved: (val) => _units = val!,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.navy),
                    child: const Text('Send details via WhatsApp'),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () async {
                      final url = Uri.parse('https://wa.me/${AppConfig.whatsappNumber.replaceAll('+', '')}');
                      launchUrl(url);
                    },
                    child: const Text('Or just chat with us now'),
                  ),
                ],
              ),
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
