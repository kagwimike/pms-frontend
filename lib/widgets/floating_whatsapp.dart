import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../config.dart';

class FloatingWhatsapp extends StatelessWidget {
  const FloatingWhatsapp({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 32,
      right: 32,
      child: SafeArea(
        child: FloatingActionButton(
          backgroundColor: AppTheme.whatsappGreen,
          onPressed: () async {
            final url = Uri.parse('https://wa.me/${AppConfig.whatsappNumber.replaceAll('+', '')}?text=${Uri.encodeComponent(AppConfig.whatsappMessage)}');
            if (await canLaunchUrl(url)) {
              await launchUrl(url);
            }
          },
          child: const Icon(Icons.chat, color: Colors.white),
        ),
      ),
    );
  }
}
