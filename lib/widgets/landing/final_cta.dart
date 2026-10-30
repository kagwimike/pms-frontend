import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class FinalCTA extends StatelessWidget {
  final VoidCallback onGetStartedTap;
  final VoidCallback onTalkToUsTap;

  const FinalCTA({
    super.key,
    required this.onGetStartedTap,
    required this.onTalkToUsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Container(
            padding: EdgeInsets.all(MediaQuery.of(context).size.width > 768 ? 44 : 24),
            decoration: BoxDecoration(
              color: AppTheme.teal,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.teal.withValues(alpha: 0.25),
                  blurRadius: 28,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  'Ready to run your properties better?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.bricolageGrotesque(
                    fontSize: MediaQuery.of(context).size.width > 768 ? 32 : 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Bring your properties, tenants, payments, maintenance, and operations into one platform.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white70,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 24),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isMobile = constraints.maxWidth < 600;
                    
                    final btn1 = ElevatedButton(
                      onPressed: onGetStartedTap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.teal,
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Text('Get Started', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    );

                    final btn2 = OutlinedButton(
                      onPressed: onTalkToUsTap,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white, width: 1.5),
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Talk to Us', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    );

                    if (isMobile) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          btn1,
                          const SizedBox(height: 12),
                          btn2,
                        ],
                      );
                    }
                    
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        btn1,
                        const SizedBox(width: 16),
                        btn2,
                      ],
                    );
                  }
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
