import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';

class RentBoardAnimation extends StatefulWidget {
  const RentBoardAnimation({super.key});

  @override
  State<RentBoardAnimation> createState() => _RentBoardAnimationState();
}

class _RentBoardAnimationState extends State<RentBoardAnimation> {
  final List<String> statuses = ['overdue', 'due', 'due', 'due', 'due', 'overdue', 'due', 'due', 'due'];
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _playAnimation();
  }

  void _playAnimation() async {
    while (mounted) {
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      setState(() {
        if (_currentStep < 3) {
          int index = statuses.indexOf('due');
          if (index != -1) statuses[index] = 'paid';
          _currentStep++;
        } else {
          for (int i = 0; i < statuses.length; i++) {
             if (statuses[i] == 'paid') statuses[i] = 'due';
          }
          _currentStep = 0;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      height: 350,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.navy.withValues(alpha: 0.1),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Rent Collection', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 16),
                Expanded(
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: 9,
                    itemBuilder: (context, index) {
                      final status = statuses[index];
                      Color color = AppTheme.border;
                      if (status == 'paid') color = AppTheme.whatsappGreen;
                      if (status == 'overdue') color = Colors.red.shade300;
                      if (status == 'due') color = AppTheme.brass;

                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: color, width: 2),
                        ),
                        child: Center(
                          child: Text(
                            'Unit ${index + 1}',
                            style: TextStyle(
                              color: color == AppTheme.border ? AppTheme.mutedText : color,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          if (_currentStep > 0 && _currentStep < 4)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.whatsappGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'M-Pesa payment received!',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ).animate().slideY(begin: 1, end: 0).fadeIn(),
            ),
        ],
      ),
    );
  }
}
