import 'package:flutter/material.dart';

class ResponsiveHelper extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;

  /// A helper to constrain the width of forms or modals, keeping them centered 
  /// and appropriately sized on large screens (e.g., desktop/web).
  const ResponsiveHelper({
    super.key,
    required this.child,
    this.maxWidth = 600.0,
    this.padding = const EdgeInsets.all(16.0),
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }

  /// Use this for Modals and Dialogs that should look like bottom sheets on mobile
  /// but float like dialogs on web/desktop.
  static Future<T?> showResponsiveDialog<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    double maxWidth = 500,
  }) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    if (isMobile) {
      return showModalBottomSheet<T>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: builder(ctx),
        ),
      );
    } else {
      return showDialog<T>(
        context: context,
        builder: (ctx) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: MediaQuery.of(context).size.height * 0.9),
            child: builder(ctx),
          ),
        ),
      );
    }
  }
}
