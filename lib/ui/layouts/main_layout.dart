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
          drawer: compact ? const Drawer(child: Sidebar()) : null,
          body: compact
              ? Stack(
                  children: [
                    child,
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Builder(
                        builder: (context) => IconButton.filledTonal(
                          tooltip: 'Open navigation',
                          onPressed: () => Scaffold.of(context).openDrawer(),
                          icon: const Icon(Icons.menu_rounded),
                        ),
                      ),
                    ),
                  ],
                )
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
