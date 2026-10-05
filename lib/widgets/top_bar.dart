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
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(Icons.access_time, color: AppTheme.border, size: 16),
              SizedBox(width: 8),
              Text('Mon–Sat 8am–8pm', style: TextStyle(color: AppTheme.border, fontSize: 12)),
              SizedBox(width: 24),
              Icon(Icons.phone, color: AppTheme.border, size: 16),
              SizedBox(width: 8),
              Text(AppConfig.phone, style: TextStyle(color: AppTheme.border, fontSize: 12)),
            ],
          ),
        );
      },
    );
  }
}
