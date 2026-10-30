import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../config.dart';
import 'package:google_fonts/google_fonts.dart';

class SubNavOption {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;

  const SubNavOption({
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
  });
}

class NavBarWidget extends StatelessWidget {
  final VoidCallback onLoginTap;
  final VoidCallback onGetStartedTap;
  final VoidCallback? onBrandTap;
  final VoidCallback? onProductTap;
  final VoidCallback? onSolutionsTap;
  final VoidCallback? onFeaturesTap;
  final VoidCallback? onResourcesTap;
  final VoidCallback? onPricingTap;
  final ValueChanged<int>? onSelectRole;

  const NavBarWidget({
    super.key,
    required this.onLoginTap,
    required this.onGetStartedTap,
    this.onBrandTap,
    this.onProductTap,
    this.onSolutionsTap,
    this.onFeaturesTap,
    this.onResourcesTap,
    this.onPricingTap,
    this.onSelectRole,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 960;

        return Container(
          height: 76,
          padding: const EdgeInsets.symmetric(horizontal: 28),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(
                color: Colors.black.withValues(alpha: 0.06),
                width: 1,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Logo + Brand
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: onBrandTap,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppTheme.teal,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.teal.withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.maps_home_work_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        AppConfig.brandName,
                        style: GoogleFonts.bricolageGrotesque(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.navy,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Desktop Navigation Links
              if (isDesktop)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _NavItemWithDropdown(
                      title: 'Product',
                      onTap: onProductTap,
                      options: [
                        SubNavOption(
                          title: 'How It Works',
                          description: '4-step workflow to operational excellence',
                          icon: Icons.alt_route_rounded,
                          onTap: () => onProductTap?.call(),
                        ),
                        SubNavOption(
                          title: 'Device Showcase',
                          description: 'Responsive desktop web and mobile apps',
                          icon: Icons.devices_rounded,
                          onTap: () => onProductTap?.call(),
                        ),
                        SubNavOption(
                          title: 'Platform Overview',
                          description: 'Unified management of rent, units & leases',
                          icon: Icons.dashboard_customize_rounded,
                          onTap: () => onProductTap?.call(),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    _NavItemWithDropdown(
                      title: 'Solutions',
                      onTap: onSolutionsTap,
                      options: [
                        SubNavOption(
                          title: 'Property Managers',
                          description: 'Complete portfolio automation & dispatch',
                          icon: Icons.business_center_rounded,
                          onTap: () {
                            onSelectRole?.call(0);
                            onSolutionsTap?.call();
                          },
                        ),
                        SubNavOption(
                          title: 'Property Owners',
                          description: 'Real-time income yield & occupancy reports',
                          icon: Icons.account_balance_rounded,
                          onTap: () {
                            onSelectRole?.call(1);
                            onSolutionsTap?.call();
                          },
                        ),
                        SubNavOption(
                          title: 'Caretakers',
                          description: 'On-ground operations & unit inspections',
                          icon: Icons.vpn_key_rounded,
                          onTap: () {
                            onSelectRole?.call(2);
                            onSolutionsTap?.call();
                          },
                        ),
                        SubNavOption(
                          title: 'Tenants',
                          description: 'Online rent payments & repair requests',
                          icon: Icons.home_rounded,
                          onTap: () {
                            onSelectRole?.call(3);
                            onSolutionsTap?.call();
                          },
                        ),
                        SubNavOption(
                          title: 'Maintenance Vendors',
                          description: 'Assigned work orders & completion invoices',
                          icon: Icons.handyman_rounded,
                          onTap: () {
                            onSelectRole?.call(4);
                            onSolutionsTap?.call();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    _NavItemWithDropdown(
                      title: 'Features',
                      onTap: onFeaturesTap,
                      options: [
                        SubNavOption(
                          title: 'Properties & Units',
                          description: 'Directory, units, tenancy & landlords',
                          icon: Icons.apartment_rounded,
                          onTap: () => onFeaturesTap?.call(),
                        ),
                        SubNavOption(
                          title: 'Rent & Automated Billing',
                          description: 'Invoicing, receipts & M-Pesa sync',
                          icon: Icons.receipt_long_rounded,
                          onTap: () => onFeaturesTap?.call(),
                        ),
                        SubNavOption(
                          title: 'Maintenance Dispatch',
                          description: 'Tenant requests, vendor quotes & tracking',
                          icon: Icons.build_circle_rounded,
                          onTap: () => onFeaturesTap?.call(),
                        ),
                        SubNavOption(
                          title: 'Tenant Management',
                          description: 'Digital leases, profiles & notifications',
                          icon: Icons.badge_rounded,
                          onTap: () => onFeaturesTap?.call(),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    _NavItemWithDropdown(
                      title: 'Resources',
                      onTap: onResourcesTap,
                      options: [
                        SubNavOption(
                          title: 'Frequently Asked Questions',
                          description: 'Answers to common property queries',
                          icon: Icons.help_outline_rounded,
                          onTap: () => onResourcesTap?.call(),
                        ),
                        SubNavOption(
                          title: 'Enterprise Security',
                          description: 'Encrypted storage, RBAC & audit logs',
                          icon: Icons.verified_user_rounded,
                          onTap: () => onResourcesTap?.call(),
                        ),
                        SubNavOption(
                          title: 'Testimonials',
                          description: 'Stories from thriving property teams',
                          icon: Icons.format_quote_rounded,
                          onTap: () => onResourcesTap?.call(),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    _NavItemWithDropdown(
                      title: 'Pricing',
                      onTap: onPricingTap,
                      options: null, // Direct click to pricing
                    ),
                  ],
                ),

              // Desktop Actions
              if (isDesktop)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: onLoginTap,
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.navy,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        textStyle: GoogleFonts.dmSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      child: const Text('Log in'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: onGetStartedTap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.teal,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        textStyle: GoogleFonts.dmSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      child: const Text('Get Started'),
                    ),
                  ],
                )
              else
                IconButton(
                  icon: const Icon(Icons.menu_rounded, color: AppTheme.navy, size: 28),
                  onPressed: () {
                    Scaffold.of(context).openDrawer();
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

class _NavItemWithDropdown extends StatefulWidget {
  final String title;
  final VoidCallback? onTap;
  final List<SubNavOption>? options;

  const _NavItemWithDropdown({
    required this.title,
    required this.onTap,
    this.options,
  });

  @override
  State<_NavItemWithDropdown> createState() => _NavItemWithDropdownState();
}

class _NavItemWithDropdownState extends State<_NavItemWithDropdown> {
  final OverlayPortalController _portalController = OverlayPortalController();
  final LayerLink _layerLink = LayerLink();
  bool _isHovered = false;
  Timer? _closeTimer;

  void _openMenu() {
    if (widget.options == null || widget.options!.isEmpty) return;
    _closeTimer?.cancel();
    if (!_portalController.isShowing) {
      _portalController.show();
    }
  }

  void _startCloseTimer() {
    _closeTimer?.cancel();
    _closeTimer = Timer(const Duration(milliseconds: 180), () {
      if (mounted && _portalController.isShowing) {
        _portalController.hide();
      }
    });
  }

  void _cancelCloseTimer() {
    _closeTimer?.cancel();
  }

  @override
  void dispose() {
    _closeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return OverlayPortal(
      controller: _portalController,
      overlayChildBuilder: (context) {
        return Positioned(
          width: 320,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            targetAnchor: Alignment.bottomLeft,
            followerAnchor: Alignment.topLeft,
            offset: const Offset(-12, 10),
            child: MouseRegion(
              onEnter: (_) => _cancelCloseTimer(),
              onExit: (_) => _startCloseTimer(),
              child: _buildDropdownCard(context),
            ),
          ),
        );
      },
      child: CompositedTransformTarget(
        link: _layerLink,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) {
            setState(() => _isHovered = true);
            _openMenu();
          },
          onExit: (_) {
            setState(() => _isHovered = false);
            _startCloseTimer();
          },
          child: Material(
            color: _isHovered ? AppTheme.bgGreyGreen : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                if (_portalController.isShowing) {
                  _portalController.hide();
                }
                widget.onTap?.call();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Text(
                  widget.title,
                  style: GoogleFonts.dmSans(
                    color: _isHovered ? AppTheme.navy : const Color(0xFF475569),
                    fontWeight: _isHovered ? FontWeight.w700 : FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownCard(BuildContext context) {
    final opts = widget.options;
    if (opts == null || opts.isEmpty) return const SizedBox.shrink();

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...opts.map((opt) => _buildOptionRow(opt)),
            const Divider(color: AppTheme.border, height: 16),
            InkWell(
              onTap: () {
                _portalController.hide();
                widget.onTap?.call();
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Text(
                      'Explore ${widget.title} Overview',
                      style: GoogleFonts.dmSans(
                        color: AppTheme.teal,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.arrow_forward_rounded, color: AppTheme.teal, size: 14),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionRow(SubNavOption opt) {
    return InkWell(
      onTap: () {
        _portalController.hide();
        opt.onTap();
      },
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                color: AppTheme.bgGreyGreen,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(opt.icon, color: AppTheme.teal, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    opt.title,
                    style: GoogleFonts.dmSans(
                      color: AppTheme.navy,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    opt.description,
                    style: GoogleFonts.dmSans(
                      color: AppTheme.mutedText,
                      fontSize: 12,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
