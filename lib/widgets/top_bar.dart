import 'package:flutter/material.dart';
import '../config.dart';
import '../theme/app_theme.dart';

class TopBar extends StatelessWidget {
  const TopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 700) return const SizedBox.shrink();
        
        return Container(
          color: AppTheme.navy,
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Icon(Icons.access_time, color: AppTheme.border, size: 16),
              const SizedBox(width: 8),
              const Text('Mon–Sat 8am–8pm', style: TextStyle(color: AppTheme.border, fontSize: 12)),
              const SizedBox(width: 24),
              const Icon(Icons.phone, color: AppTheme.border, size: 16),
              const SizedBox(width: 8),
              Text(AppConfig.phone, style: const TextStyle(color: AppTheme.border, fontSize: 12)),
            ],
          ),
        );
      },
    );
  }
}
