import 'package:flutter/material.dart';

import '../widgets/sidebar.dart';

class MainLayout extends StatelessWidget {
  final Widget child;

  const MainLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 900;
        return Scaffold(
          body: compact
              ? child
              : Row(
                  children: [
                    const Sidebar(),
                    Expanded(child: child),
                  ],
                ),
        );
      },
    );
  }
}
