import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/theme_provider.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'settings/account_profile_section.dart';
import 'settings/organization_settings_section.dart';
import 'settings/rental_finance_settings_section.dart';
import 'settings/integrations_settings_section.dart';
import 'settings/security_audit_settings_section.dart';
import 'settings/notifications_settings_section.dart';

class SettingsScreen extends StatefulWidget {
  final bool isOwner;

  const SettingsScreen({super.key, this.isOwner = true});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _api = ApiService();
  final _auth = AuthService();

  String _selectedCategory = 'account';
  bool _isLoading = true;
  String? _errorMessage;

  Map<String, dynamic> _profileData = {};
  Map<String, dynamic> _orgConfig = {};
  Map<String, dynamic> _rentalConfig = {};
  Map<String, dynamic> _financeConfig = {};
  Map<String, dynamic> _integrationsConfig = {};
  Map<String, dynamic> _notificationsConfig = {};
  Map<String, dynamic> _securityConfig = {};

  @override
  void initState() {
    super.initState();
    _loadAllSettings();
  }

  Future<void> _loadAllSettings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final isStaff = ['ADMIN', 'OWNER'].contains(_auth.user?.role);

      // Load Profile & Preferences
      final profileRes = await _api.getProfilePreferences();
      _profileData = ApiService.extractMap(profileRes);

      if (isStaff) {
        final orgRes = await _api.getSettings('ORGANIZATION');
        _orgConfig = ApiService.extractMap(orgRes);

        final rentalRes = await _api.getSettings('RENTAL');
        _rentalConfig = ApiService.extractMap(rentalRes);

        final financeRes = await _api.getSettings('FINANCE');
        _financeConfig = ApiService.extractMap(financeRes);

        final integrationsRes = await _api.getSettings('INTEGRATIONS');
        _integrationsConfig = ApiService.extractMap(integrationsRes);

        final notificationsRes = await _api.getSettings('NOTIFICATIONS');
        _notificationsConfig = ApiService.extractMap(notificationsRes);

        final securityRes = await _api.getSettings('SECURITY');
        _securityConfig = ApiService.extractMap(securityRes);
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderColor = isDark ? const Color(0xFF27272A) : AppTheme.border;
    final textColor = isDark ? Colors.white : AppTheme.navy;
    final muted = isDark ? AppTheme.darkMutedText : AppTheme.mutedText;

    final isStaff = ['ADMIN', 'OWNER'].contains(_auth.user?.role);

    final categories = [
      _Category('account', 'Profile & Account', Icons.person_outline),
      _Category('appearance', 'Theme & Display', Icons.palette_outlined),
      _Category('security', 'Security & Audit', Icons.shield_outlined),
      if (isStaff) _Category('organization', 'Organization', Icons.business_outlined),
      if (isStaff) _Category('rental_finance', 'Rental & Finance', Icons.account_balance_wallet_outlined),
      if (isStaff) _Category('notifications', 'Notifications', Icons.notifications_none_outlined),
      if (isStaff) _Category('integrations', 'Integrations', Icons.hub_outlined),
    ];

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.teal));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 800;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Settings & System Management',
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Configure your profile, security, policies, and role-scoped settings.',
                style: GoogleFonts.dmSans(fontSize: 14, color: muted),
              ),
              const SizedBox(height: 24),

              if (isMobile)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCategoryPills(categories, isDark),
                    const SizedBox(height: 20),
                    _buildActiveCategoryContent(cardBg, borderColor, textColor, muted, isDark),
                  ],
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 240,
                      child: _buildCategorySidebar(categories, cardBg, borderColor, isDark),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: _buildActiveCategoryContent(cardBg, borderColor, textColor, muted, isDark),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategorySidebar(List<_Category> categories, Color cardBg, Color borderColor, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: categories.map((cat) {
          final isSelected = _selectedCategory == cat.id;
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              tileColor: isSelected ? AppTheme.teal.withValues(alpha: 0.12) : Colors.transparent,
              leading: Icon(cat.icon, color: isSelected ? AppTheme.teal : (isDark ? Colors.white70 : AppTheme.navy), size: 20),
              title: Text(
                cat.title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppTheme.teal : (isDark ? Colors.white : AppTheme.navy),
                ),
              ),
              onTap: () => setState(() => _selectedCategory = cat.id),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCategoryPills(List<_Category> categories, bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((cat) {
          final isSelected = _selectedCategory == cat.id;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              avatar: Icon(cat.icon, size: 16, color: isSelected ? Colors.white : (isDark ? Colors.white70 : AppTheme.navy)),
              label: Text(cat.title),
              selected: isSelected,
              selectedColor: AppTheme.teal,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : (isDark ? Colors.white : AppTheme.navy),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              onSelected: (selected) {
                if (selected) setState(() => _selectedCategory = cat.id);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActiveCategoryContent(Color cardBg, Color borderColor, Color textColor, Color muted, bool isDark) {
    switch (_selectedCategory) {
      case 'account':
        return AccountProfileSection(
          initialProfile: _profileData,
          onSaved: _loadAllSettings,
        );
      case 'appearance':
        return _buildAppearanceSection(cardBg, borderColor, textColor, muted, isDark);
      case 'organization':
        return OrganizationSettingsSection(
          initialConfig: _orgConfig,
          onSaved: _loadAllSettings,
        );
      case 'rental_finance':
        return RentalFinanceSettingsSection(
          rentalConfig: _rentalConfig,
          financeConfig: _financeConfig,
          onSaved: _loadAllSettings,
        );
      case 'notifications':
        return NotificationsSettingsSection(
          notificationsConfig: _notificationsConfig,
          onSaved: _loadAllSettings,
        );
      case 'integrations':
        return IntegrationsSettingsSection(
          integrationsConfig: _integrationsConfig,
          onSaved: _loadAllSettings,
        );
      case 'security':
        return SecurityAuditSettingsSection(
          securityConfig: _securityConfig,
          onSaved: _loadAllSettings,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildAppearanceSection(Color cardBg, Color borderColor, Color textColor, Color muted, bool isDark) {
    return Container(
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
                  Text('Appearance & Theme',
                      style: GoogleFonts.bricolageGrotesque(fontSize: 18, fontWeight: FontWeight.w700, color: textColor)),
                  Text('Personal color theme and responsive presentation mode',
                      style: GoogleFonts.dmSans(fontSize: 13, color: muted)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, _) {
              final options = [
                _ThemeCardOption('System Default', 'Follow system device mode', Icons.brightness_auto_outlined,
                    ThemeMode.system, themeProvider.themeMode == ThemeMode.system, () => themeProvider.setThemeMode(ThemeMode.system)),
                _ThemeCardOption('Light Mode', 'Crisp bright workspace', Icons.light_mode_outlined,
                    ThemeMode.light, themeProvider.themeMode == ThemeMode.light, () => themeProvider.setThemeMode(ThemeMode.light)),
                _ThemeCardOption('Dark Mode', 'Easy on the eyes', Icons.dark_mode_outlined,
                    ThemeMode.dark, themeProvider.themeMode == ThemeMode.dark, () => themeProvider.setThemeMode(ThemeMode.dark)),
              ];

              return Row(
                children: options
                    .map((opt) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: InkWell(
                              onTap: opt.onTap,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: opt.isSelected
                                      ? AppTheme.teal.withValues(alpha: isDark ? 0.2 : 0.08)
                                      : (isDark ? const Color(0xFF27272A) : const Color(0xFFF8FAFC)),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: opt.isSelected ? AppTheme.teal : borderColor,
                                    width: opt.isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(opt.icon, color: opt.isSelected ? AppTheme.teal : (isDark ? Colors.white70 : AppTheme.navy)),
                                    const SizedBox(height: 12),
                                    Text(opt.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                    const SizedBox(height: 4),
                                    Text(opt.subtitle, style: TextStyle(fontSize: 11, color: muted)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Category {
  final String id;
  final String title;
  final IconData icon;
  const _Category(this.id, this.title, this.icon);
}

class _ThemeCardOption {
  final String title;
  final String subtitle;
  final IconData icon;
  final ThemeMode mode;
  final bool isSelected;
  final VoidCallback onTap;
  const _ThemeCardOption(this.title, this.subtitle, this.icon, this.mode, this.isSelected, this.onTap);
}
