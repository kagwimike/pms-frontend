import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/theme_provider.dart';
import '../services/auth_service.dart';

class SettingsScreen extends StatefulWidget {
  final bool isOwner;

  const SettingsScreen({super.key, this.isOwner = true});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _auth = AuthService();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderColor = isDark ? const Color(0xFF27272A) : AppTheme.border;
    final textColor = isDark ? Colors.white : AppTheme.navy;
    final mutedTextColor = isDark ? AppTheme.darkMutedText : AppTheme.mutedText;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Settings & Preferences',
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Customize your appearance, profile, and application preferences.',
            style: GoogleFonts.dmSans(
              fontSize: 14,
              color: mutedTextColor,
            ),
          ),
          const SizedBox(height: 28),

          // ── Appearance Section ──
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.teal.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.palette_outlined, color: AppTheme.teal, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Appearance & Theme',
                          style: GoogleFonts.bricolageGrotesque(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                        Text(
                          'Select your preferred color theme or match your device system settings',
                          style: GoogleFonts.dmSans(fontSize: 13, color: mutedTextColor),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                Consumer<ThemeProvider>(
                  builder: (context, themeProvider, _) {
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final isCompact = constraints.maxWidth < 650;
                        final options = [
                          _ThemeOption(
                            title: 'System Default',
                            description: 'Follow system appearance',
                            icon: Icons.brightness_auto_outlined,
                            mode: ThemeMode.system,
                            isSelected: themeProvider.themeMode == ThemeMode.system,
                            onTap: () => themeProvider.setThemeMode(ThemeMode.system),
                          ),
                          _ThemeOption(
                            title: 'Light Mode',
                            description: 'Clean & crisp bright theme',
                            icon: Icons.light_mode_outlined,
                            mode: ThemeMode.light,
                            isSelected: themeProvider.themeMode == ThemeMode.light,
                            onTap: () => themeProvider.setThemeMode(ThemeMode.light),
                          ),
                          _ThemeOption(
                            title: 'Dark Mode',
                            description: 'Easy on the eyes at night',
                            icon: Icons.dark_mode_outlined,
                            mode: ThemeMode.dark,
                            isSelected: themeProvider.themeMode == ThemeMode.dark,
                            onTap: () => themeProvider.setThemeMode(ThemeMode.dark),
                          ),
                        ];

                        if (isCompact) {
                          return Column(
                            children: options
                                .map((opt) => Padding(
                                      padding: const EdgeInsets.only(bottom: 12),
                                      child: _buildThemeCard(opt, isDark, borderColor),
                                    ))
                                .toList(),
                          );
                        }

                        return Row(
                          children: options
                              .map((opt) => Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 6),
                                      child: _buildThemeCard(opt, isDark, borderColor),
                                    ),
                                  ))
                              .toList(),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Account Info Section ──
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.brass.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.person_outline, color: AppTheme.brass, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Account Information',
                          style: GoogleFonts.bricolageGrotesque(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                        Text(
                          'Logged in account details and active permissions',
                          style: GoogleFonts.dmSans(fontSize: 13, color: mutedTextColor),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.teal,
                    foregroundColor: Colors.white,
                    child: Text(
                      (_auth.user?.username.isNotEmpty ?? false)
                          ? _auth.user!.username[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(
                    _auth.user?.username ?? 'User',
                    style: TextStyle(fontWeight: FontWeight.w600, color: textColor),
                  ),
                  subtitle: Text(
                    _auth.user?.email ?? 'No email provided',
                    style: TextStyle(color: mutedTextColor),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.teal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _auth.user?.role ?? (widget.isOwner ? 'OWNER' : 'TENANT'),
                      style: const TextStyle(
                        color: AppTheme.teal,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeCard(_ThemeOption option, bool isDark, Color borderColor) {
    const activeColor = AppTheme.teal;

    return InkWell(
      onTap: option.onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: option.isSelected
              ? activeColor.withValues(alpha: isDark ? 0.2 : 0.08)
              : (isDark ? const Color(0xFF27272A) : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: option.isSelected ? activeColor : borderColor,
            width: option.isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  option.icon,
                  size: 24,
                  color: option.isSelected ? activeColor : (isDark ? Colors.white70 : const Color(0xFF475569)),
                ),
                if (option.isSelected)
                  const Icon(Icons.check_circle, size: 20, color: activeColor)
                else
                  Icon(Icons.radio_button_unchecked, size: 20, color: borderColor),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              option.title,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: isDark ? Colors.white : AppTheme.navy,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              option.description,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppTheme.darkMutedText : AppTheme.mutedText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeOption {
  final String title;
  final String description;
  final IconData icon;
  final ThemeMode mode;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.title,
    required this.description,
    required this.icon,
    required this.mode,
    required this.isSelected,
    required this.onTap,
  });
}
