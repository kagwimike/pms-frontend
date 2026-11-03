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
  bool _isNavigating = false;
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
    if (_isNavigating) return;
    _isNavigating = true;
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
      backgroundColor: const Color(0xFF0D1B17),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < AppBreakpoints.authSplit;
          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF091713),
                  Color(0xFF102820),
                  Color(0xFF16372C),
                ],
              ),
            ),
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 16 : 24,
                  vertical: 24,
                ),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 36,
                        offset: const Offset(0, 18),
                      ),
                    ],
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
          child: _buildFormPanel(isMobile: false),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildMobileBrandingStrip(),
        _buildFormPanel(isMobile: true),
      ],
    );
  }

  Widget _buildMobileBrandingStrip() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF091C17),
            Color(0xFF103026),
            Color(0xFF143F33),
          ],
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
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE8A317), Color(0xFFFBBF24)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE8A317).withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(Icons.domain_add, color: Color(0xFF10231D), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppConfig.brandName,
                      style: GoogleFonts.bricolageGrotesque(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.8,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Property Management System',
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Welcome back!',
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
          colors: [
            Color(0xFF091C17),
            Color(0xFF103026),
            Color(0xFF143F33),
          ],
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
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE8A317), Color(0xFFFBBF24)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE8A317).withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.domain_add, color: Color(0xFF10231D), size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppConfig.brandName,
                      style: GoogleFonts.bricolageGrotesque(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.8,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Property Management System',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
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
              color: Colors.white.withValues(alpha: 0.75),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 48),
          // Illustration / Stats card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
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
              color: const Color(0xFFFBBF24),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormPanel({bool isMobile = false}) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24 : 48,
        vertical: isMobile ? 32 : 44,
      ),
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
                    fontSize: 14,
                    color: AppTheme.mutedText,
                  ),
                ),
                const SizedBox(height: 32),

                // Email
                _buildLabel('Email Address'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    color: AppTheme.navy,
                    fontWeight: FontWeight.w500,
                  ),
                  cursorColor: AppTheme.teal,
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
                const SizedBox(height: 18),

                // Password
                _buildLabel('Password'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  focusNode: _passwordFocusNode ??= FocusNode(),
                  obscureText: _obscurePassword,
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    color: AppTheme.navy,
                    fontWeight: FontWeight.w500,
                  ),
                  cursorColor: AppTheme.teal,
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: InkWell(
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
                                  checkColor: Colors.white,
                                  side: const BorderSide(color: AppTheme.border, width: 1.5),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'Remember me',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 13,
                                    color: _rememberMe ? AppTheme.navy : AppTheme.mutedText,
                                    fontWeight: _rememberMe ? FontWeight.w600 : FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () {},
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Forgot password?',
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          color: AppTheme.teal,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // ─── Sign In Button ───
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _authService.isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.navy,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
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
                            style: GoogleFonts.dmSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),

                // ─── Divider with lines and 'or' ───
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 22),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Divider(
                          color: AppTheme.border,
                          thickness: 1.2,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'or',
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.mutedText,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      const Expanded(
                        child: Divider(
                          color: AppTheme.border,
                          thickness: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),

                // ─── Social Logins (Google & Facebook) ───
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Sign in with Google
                    GoogleSignInSection(
                      isDark: false,
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
                    // Sign in with Facebook
                    _buildFacebookButton(),
                  ],
                ),
                const SizedBox(height: 28),

                // Sign up prompt
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

  Widget _buildFacebookButton() {
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Facebook sign-in will be available in the next release.'),
              backgroundColor: const Color(0xFF1877F2),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        },
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppTheme.border, width: 1.2),
          shape: const StadiumBorder(),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.facebook, size: 22, color: Color(0xFF1877F2)),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                'Sign in with Facebook',
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1F2937),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
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
      hintStyle: GoogleFonts.dmSans(
        fontSize: 14,
        color: AppTheme.mutedText.withValues(alpha: 0.6),
      ),
      prefixIcon: Icon(icon, size: 20, color: AppTheme.mutedText),
      filled: true,
      fillColor: AppTheme.bgGreyGreen,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppTheme.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppTheme.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppTheme.teal, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.red.shade600, width: 1.8),
      ),
    );
  }
}
