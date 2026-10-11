import 'package:flutter/material.dart';

import '../widgets/sidebar.dart';
import '../widgets/top_nav_bar.dart';

import 'package:flutter/services.dart';
import '../../widgets/search_overlay.dart';

class MainLayout extends StatelessWidget {
  final Widget child;

  const MainLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyK, control: true): () {
          showDialog(
            context: context,
            barrierColor: Colors.black.withValues(alpha: 0.4),
            builder: (context) => const SearchOverlay(),
          );
        },
        const SingleActivator(LogicalKeyboardKey.keyK, meta: true): () {
          showDialog(
            context: context,
            barrierColor: Colors.black.withValues(alpha: 0.4),
            builder: (context) => const SearchOverlay(),
          );
        },
      },
      child: Focus(
        autofocus: true,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 900;
            return Scaffold(
              drawer: compact ? const Drawer(child: Sidebar()) : null,
              body: compact
                  ? Column(
                      children: [
                        const TopNavBar(isCompact: true),
                        Expanded(child: child),
                      ],
                    )
                  : Row(
                      children: [
                        const Sidebar(),
                        Expanded(
                          child: Column(
                            children: [
                              const TopNavBar(isCompact: false),
                              Expanded(child: child),
                            ],
                          ),
                        ),
                      ],
                    ),
            );
          },
        ),
      ),
    );
  }
}
