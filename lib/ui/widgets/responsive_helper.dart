import 'package:flutter/material.dart';

/// Standard device screen categories for PMS Pro
enum DeviceScreenType {
  extraSmall, // Compact phones (< 480px)
  mobile,     // Standard & large phones (480px - 767px)
  tablet,     // Tablets & small laptops (768px - 1023px)
  desktop,    // Standard desktop monitors (1024px - 1439px)
  extraLarge, // Large displays & 4K (>= 1440px)
}

/// Centralized Responsive Breakpoints System
/// Single source of truth across mobile, tablet, desktop, and large displays.
class AppBreakpoints {
  // ─── 1. Core 5-Tier Responsive Spectrum ───
  static const double xs = 480.0;   // Extra Small Phone threshold
  static const double sm = 768.0;   // Mobile / Phone threshold
  static const double md = 1024.0;  // Tablet threshold
  static const double lg = 1440.0;  // Desktop threshold
  static const double xl = 1920.0;  // Extra Large / 4K threshold

  // ─── 2. Dedicated Component Thresholds ───
  static const double sidebarCollapse = 900.0; // Collapses left dashboard sidebar into hamburger drawer
  static const double authSplit = 800.0;        // Collapses 2-column auth screen into single card
  static const double modalSheet = 600.0;       // Transitions floating dialog into mobile bottom sheet
  static const double tableToCard = 768.0;      // Morphs desktop DataTable into mobile Card list

  // ─── 3. Context-Based Boolean Helpers ───
  static bool isExtraSmall(BuildContext context) =>
      MediaQuery.sizeOf(context).width < xs;

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < sm;

  static bool isTablet(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return w >= sm && w < md;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= md;

  static bool isExtraLarge(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= lg;

  // ─── 4. Width-Based Boolean Helpers (for LayoutBuilder) ───
  static bool isExtraSmallWidth(double width) => width < xs;
  static bool isMobileWidth(double width) => width < sm;
  static bool isTabletWidth(double width) => width >= sm && width < md;
  static bool isDesktopWidth(double width) => width >= md;
  static bool isExtraLargeWidth(double width) => width >= lg;

  // ─── 5. Screen Type Resolver ───
  static DeviceScreenType getScreenType(BuildContext context) {
    return getScreenTypeFromWidth(MediaQuery.sizeOf(context).width);
  }

  static DeviceScreenType getScreenTypeFromWidth(double width) {
    if (width < xs) return DeviceScreenType.extraSmall;
    if (width < sm) return DeviceScreenType.mobile;
    if (width < md) return DeviceScreenType.tablet;
    if (width < lg) return DeviceScreenType.desktop;
    return DeviceScreenType.extraLarge;
  }

  // ─── 6. Responsive Value Picker (CSS / Tailwind Style) ───
  /// Easily resolve different values (e.g. grid counts, padding, font sizes)
  /// according to the current screen size.
  static T value<T>({
    required BuildContext context,
    required T mobile,
    T? extraSmall,
    T? tablet,
    T? desktop,
    T? extraLarge,
  }) {
    return valueFromWidth<T>(
      width: MediaQuery.sizeOf(context).width,
      mobile: mobile,
      extraSmall: extraSmall,
      tablet: tablet,
      desktop: desktop,
      extraLarge: extraLarge,
    );
  }

  static T valueFromWidth<T>({
    required double width,
    required T mobile,
    T? extraSmall,
    T? tablet,
    T? desktop,
    T? extraLarge,
  }) {
    if (width >= lg && extraLarge != null) return extraLarge;
    if (width >= md && desktop != null) return desktop;
    if (width >= sm && tablet != null) return tablet;
    if (width < xs && extraSmall != null) return extraSmall;
    return mobile;
  }
}

/// Adaptive Layout Builder that provides the current [DeviceScreenType]
class ResponsiveLayoutBuilder extends StatelessWidget {
  final Widget Function(
    BuildContext context,
    DeviceScreenType screenType,
    BoxConstraints constraints,
  ) builder;

  const ResponsiveLayoutBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenType = AppBreakpoints.getScreenTypeFromWidth(constraints.maxWidth);
        return builder(context, screenType, constraints);
      },
    );
  }
}

/// Backward-compatible Form/Modal & Dialog Helper
class ResponsiveHelper extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;

  /// Constrains form or modal width, keeping it centered and readable on large screens.
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

  /// Use this for Modals and Dialogs that adapt into bottom sheets on mobile
  /// and centered floating dialogs on desktop/web.
  static Future<T?> showResponsiveDialog<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    double maxWidth = 500,
    double? customBreakpoint,
  }) {
    final threshold = customBreakpoint ?? AppBreakpoints.modalSheet;
    final isMobile = MediaQuery.sizeOf(context).width < threshold;

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
            constraints: BoxConstraints(
              maxWidth: maxWidth,
              maxHeight: MediaQuery.sizeOf(context).height * 0.9,
            ),
            child: builder(ctx),
          ),
        ),
      );
    }
  }

  // Quick helper aliases
  static bool isMobile(BuildContext context) => AppBreakpoints.isMobile(context);
  static bool isTablet(BuildContext context) => AppBreakpoints.isTablet(context);
  static bool isDesktop(BuildContext context) => AppBreakpoints.isDesktop(context);
}
