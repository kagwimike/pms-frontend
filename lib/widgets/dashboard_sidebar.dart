import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../config.dart';
import '../services/auth_service.dart';

class SidebarItem {
  final IconData icon;
  final String label;
  final String key;

  const SidebarItem({required this.icon, required this.label, required this.key});
}

class DashboardSidebar extends StatelessWidget {
  final List<SidebarItem> items;
  final String selectedKey;
  final ValueChanged<String> onItemSelected;
  final String roleBadge;
  final Color roleBadgeColor;

  const DashboardSidebar({
    super.key,
    required this.items,
    required this.selectedKey,
    required this.onItemSelected,
    this.roleBadge = 'OWNER',
    this.roleBadgeColor = AppTheme.teal,
  });

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();
    return Container(
      width: 260,
      decoration: const BoxDecoration(
        color: AppTheme.navy,
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 32),
          // Logo
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.brass,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.apartment, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Text(
                  AppConfig.brandName,
                  style: GoogleFonts.bricolageGrotesque(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Version
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Property Management • v1.0',
                style: GoogleFonts.dmSans(fontSize: 10, color: Colors.white38),
              ),
            ),
          ),
          const SizedBox(height: 32),
          // Nav items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: items.map((item) {
                final isSelected = item.key == selectedKey;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => onItemSelected(item.key),
                      borderRadius: BorderRadius.circular(12),
                      hoverColor: Colors.white.withValues(alpha: 0.06),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white.withValues(alpha: 0.12) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              item.icon,
                              size: 20,
                              color: isSelected ? AppTheme.brass : Colors.white54,
                            ),
                            const SizedBox(width: 14),
                            Text(
                              item.label,
                              style: GoogleFonts.dmSans(
                                fontSize: 14,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                color: isSelected ? Colors.white : Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          // User info + logout removed
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
