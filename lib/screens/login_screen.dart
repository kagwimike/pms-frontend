import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../config.dart';
import '../services/auth_service.dart';
import '../widgets/google_auth/google_sign_in_section.dart';
import '../ui/widgets/responsive_helper.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  FocusNode? _passwordFocusNode = FocusNode();
  bool _obscurePassword = true;
  bool _rememberMe = false;
  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _authService.addListener(_onAuthStateChanged);
    _loadRememberedCredentials();
  }

  Future<void> _loadRememberedCredentials() async {
    final rememberMe = await _authService.getRememberMePreference();
    final savedEmail = await _authService.getRememberedEmail();
    if (mounted) {
      setState(() {
        _rememberMe = rememberMe;
        if (savedEmail != null && savedEmail.isNotEmpty) {
          _emailController.text = savedEmail;
        }
      });
      if (savedEmail != null && savedEmail.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _emailController.text.isNotEmpty) {
            _passwordFocusNode?.requestFocus();
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _authService.removeListener(_onAuthStateChanged);
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocusNode?.dispose();
    super.dispose();
  }

  void _onAuthStateChanged() {
    if (_authService.isLoggedIn && mounted) {
      _navigateToDashboard();
    }
  }

  void _navigateToDashboard() {
    final role = _authService.user?.role ?? 'OWNER';
    if (role == 'OWNER' || role == 'ADMIN') {
      Navigator.of(context).pushReplacementNamed('/owner-dashboard');
    } else if (role == 'TENANT') {
      Navigator.of(context).pushReplacementNamed('/tenant-dashboard');
    } else if (role == 'CARETAKER') {
      Navigator.of(context).pushReplacementNamed('/caretaker-dashboard');
    } else if (role == 'VENDOR') {
      Navigator.of(context).pushReplacementNamed('/vendor-dashboard');
    } else {
      Navigator.of(context).pushReplacementNamed('/owner-dashboard');
    }
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await _authService.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      rememberMe: _rememberMe,
    );

    if (!mounted) return;

    if (success) {
      _navigateToDashboard();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_authService.error ?? 'Login failed'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < AppBreakpoints.authSplit;
          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0F766E), Color(0xFF14233B)],
              ),
            ),
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: isMobile ? _buildMobileLayout() : _buildDesktopLayout(),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Left branding panel
        Expanded(
          flex: 4,
          child: _buildBrandingPanel(),
        ),
        // Right form panel
        Expanded(
          flex: 5,
          child: _buildFormPanel(),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildMobileBrandingStrip(),
        _buildFormPanel(),
      ],
    );
  }

  Widget _buildMobileBrandingStrip() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F766E), Color(0xFF14233B)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo
          Row(
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
          const SizedBox(height: 24),
          Text(
            'Welcome\nback!',
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.1,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.1);
  }

  Widget _buildBrandingPanel() {
    return Container(
      padding: const EdgeInsets.all(48),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F766E), Color(0xFF14233B)],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.brass,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.apartment, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),
              Text(
                AppConfig.brandName,
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 48),
          // Headline
          Text(
            'Manage your\nproperties\nthe smart way',
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 38,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Collect rent, track tenants, and manage\nmaintenance — all from one dashboard.',
            style: GoogleFonts.dmSans(
              fontSize: 15,
              color: Colors.white.withValues(alpha: 0.7),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 48),
          // Illustration / Stats card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                _buildMiniStat('10K+', 'Units'),
                const SizedBox(width: 20),
                _buildMiniStat('99%', 'Collection'),
                const SizedBox(width: 20),
                _buildMiniStat('24/7', 'Support'),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.1);
  }

  Widget _buildMiniStat(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppTheme.brass,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormPanel() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 48),
      child: ListenableBuilder(
        listenable: _authService,
        builder: (context, _) {
          return Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title
                Text(
                  'Login',
                  style: GoogleFonts.bricolageGrotesque(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.navy,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Welcome back! Sign in to your account.',
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    color: AppTheme.mutedText,
                  ),
                ),
                const SizedBox(height: 36),

                // Email
                _buildLabel('Email Address'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _inputDecoration(
                    hint: 'you@example.com',
                    icon: Icons.email_outlined,
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Email is required';
                    if (!val.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Password
                _buildLabel('Password'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  focusNode: _passwordFocusNode ??= FocusNode(),
                  obscureText: _obscurePassword,
                  decoration: _inputDecoration(
                    hint: '••••••••',
                    icon: Icons.lock_outline,
                  ).copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: AppTheme.mutedText,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Password is required';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Remember me + Forgot
                Row(
                  children: [
                    InkWell(
                      onTap: () => setState(() => _rememberMe = !_rememberMe),
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: Checkbox(
                                value: _rememberMe,
                                onChanged: (val) => setState(() => _rememberMe = val ?? false),
                                activeColor: AppTheme.teal,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Remember me',
                              style: GoogleFonts.dmSans(
                                fontSize: 13,
                                color: _rememberMe ? AppTheme.navy : AppTheme.mutedText,
                                fontWeight: _rememberMe ? FontWeight.w600 : FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {},
                      style: TextButton.styleFrom(padding: EdgeInsets.zero),
                      child: Text(
                        'Forgot password?',
                        style: GoogleFonts.dmSans(fontSize: 13, color: AppTheme.teal, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Login button
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _authService.isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.navy,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: _authService.isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Sign In',
                            style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
                const SizedBox(height: 24),

                // Divider
                Row(
                  children: [
                    const Expanded(child: Divider(color: AppTheme.border)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'or',
                        style: GoogleFonts.dmSans(fontSize: 13, color: AppTheme.mutedText),
                      ),
                    ),
                    const Expanded(child: Divider(color: AppTheme.border)),
                  ],
                ),
                const SizedBox(height: 24),

                // Social logins arranged vertically
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    GoogleSignInSection(
                      onSuccess: () => _navigateToDashboard(),
                      onError: (msg) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(msg),
                            backgroundColor: Colors.red.shade600,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildSocialButton(
                      Icons.facebook,
                      'Sign in with Facebook',
                      iconColor: const Color(0xFF1877F2),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Sign up prompt (Question on top, Create Account link below)
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account?",
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        color: AppTheme.mutedText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const RegisterScreen()),
                          );
                        },
                        child: Text(
                          'Create Account',
                          style: GoogleFonts.dmSans(
                            fontSize: 15,
                            color: AppTheme.teal,
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    ).animate().fadeIn(duration: 500.ms, delay: 200.ms).slideX(begin: 0.05);
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.dmSans(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppTheme.navy,
      ),
    );
  }

  InputDecoration _inputDecoration({required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.dmSans(fontSize: 14, color: AppTheme.mutedText.withValues(alpha: 0.5)),
      prefixIcon: Icon(icon, size: 20, color: AppTheme.mutedText),
      filled: true,
      fillColor: AppTheme.bgGreyGreen,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.teal, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade300, width: 1.5),
      ),
    );
  }

  Widget _buildSocialButton(IconData icon, String label, {Color? iconColor, VoidCallback? onPressed}) {
    return SizedBox(
      height: 48,
      child: OutlinedButton.icon(
        onPressed: onPressed ?? () {},
        icon: Icon(icon, size: 22, color: iconColor ?? AppTheme.navy),
        label: Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.navy,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppTheme.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
      ),
    );
  }
}
