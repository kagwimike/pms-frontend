import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import 'shared_widgets.dart';
import 'rent_board_animation.dart';

class HeroSection extends StatelessWidget {
  const HeroSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 80),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 800;
          
          final content = Column(
            crossAxisAlignment: isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Stop chasing tenants for rent every month.',
                style: isMobile 
                  ? Theme.of(context).textTheme.displayMedium 
                  : Theme.of(context).textTheme.displayLarge,
                textAlign: isMobile ? TextAlign.center : TextAlign.left,
              ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0),
              const SizedBox(height: 24),
              Text(
                'Automate M-Pesa matching, send SMS reminders, and know exactly who hasn\'t paid in real-time. Built specifically for Kenyan landlords and property managers.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: isMobile ? TextAlign.center : TextAlign.left,
              ).animate().fadeIn(duration: 600.ms, delay: 200.ms).slideY(begin: 0.2, end: 0),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: isMobile ? MainAxisAlignment.center : MainAxisAlignment.start,
                children: [
                  const WhatsappButton().animate().fadeIn(duration: 600.ms, delay: 400.ms),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                '⚡ We reply the same day',
                style: const TextStyle(color: AppTheme.teal, fontWeight: FontWeight.w600),
              ).animate().fadeIn(duration: 600.ms, delay: 600.ms),
            ],
          );

          final animation = const RentBoardAnimation().animate().fadeIn(duration: 800.ms, delay: 400.ms).scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1));

          if (isMobile) {
            return Column(
              children: [
                content,
                const SizedBox(height: 60),
                animation,
              ],
            );
          }

          return Row(
            children: [
              Expanded(flex: 5, child: content),
              const SizedBox(width: 40),
              Expanded(flex: 4, child: Center(child: animation)),
            ],
          );
        },
      ),
    );
  }
}
