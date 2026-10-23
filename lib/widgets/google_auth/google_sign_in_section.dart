import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import 'web_wrapper.dart' as gsi;

/// Production-ready Google Sign-In & Sign-Up widget
/// Handles web Google Identity Services (GIS), native mobile/desktop OAuth,
/// role assignment for fast-track onboarding, and reactive state feedback.
class GoogleSignInSection extends StatefulWidget {
  final bool isSignUp;
  final String? role;
  final VoidCallback? onSuccess;
  final Function(String message)? onError;

  const GoogleSignInSection({
    super.key,
    this.isSignUp = false,
    this.role,
    this.onSuccess,
    this.onError,
  });

  @override
  State<GoogleSignInSection> createState() => _GoogleSignInSectionState();
}

class _GoogleSignInSectionState extends State<GoogleSignInSection> {
  final AuthService _authService = AuthService();
  bool _localProcessing = false;

  bool get _isLoading => _localProcessing || _authService.isLoading;

  @override
  void initState() {
    super.initState();
    _authService.setPendingRole(widget.role);
    _authService.addListener(_onAuthStateChanged);
  }

  @override
  void didUpdateWidget(covariant GoogleSignInSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.role != oldWidget.role) {
      _authService.setPendingRole(widget.role);
    }
  }

  @override
  void dispose() {
    _authService.removeListener(_onAuthStateChanged);
    super.dispose();
  }

  void _onAuthStateChanged() {
    if (!mounted) return;
    if (_authService.isLoggedIn) {
      widget.onSuccess?.call();
    } else if (_authService.error != null && _authService.error!.isNotEmpty) {
      widget.onError?.call(_authService.error!);
    }
    setState(() {});
  }

  Future<void> _handleDevLogin() async {
    setState(() => _localProcessing = true);
    final role = widget.role ?? 'OWNER';
    final success = await _authService.signInWithGoogle(
      devToken: 'dev_google_user@pmspro.co.ke',
      role: role,
    );
    if (!mounted) return;
    setState(() => _localProcessing = false);

    if (success) {
      widget.onSuccess?.call();
    } else {
      widget.onError?.call(_authService.error ?? 'Demo Google Sign-In failed');
    }
  }

  Future<void> _handleNativeGoogleSignIn() async {
    setState(() => _localProcessing = true);
    final success = await _authService.signInWithGoogle(role: widget.role);
    if (!mounted) return;
    setState(() => _localProcessing = false);

    if (success) {
      widget.onSuccess?.call();
    } else {
      widget.onError?.call(_authService.error ?? 'Google Sign-In failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    final buttonLabel = widget.isSignUp ? 'Sign up with Google' : 'Sign in with Google';

    if (kIsWeb) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Web Google Identity Services (GIS) Button Container with Loading Overlay
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.border),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0A000000),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: gsi.renderGsiButton(
                  width: 320,
                  isSignUp: widget.isSignUp,
                ),
              ),

              // Smooth Loading Overlay while authenticating with PMS Pro backend
              if (_isLoading)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xF0FFFFFF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.navy),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Connecting with Google...',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.navy,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          // Developer Quick-Test Option (Only visible in Debug Mode)
          if (kDebugMode) ...[
            const SizedBox(height: 8),
            Center(
              child: TextButton.icon(
                onPressed: _isLoading ? null : _handleDevLogin,
                icon: const Icon(Icons.flash_on_rounded, size: 14, color: AppTheme.mutedText),
                label: Text(
                  'Quick-test Google OAuth (Localhost Dev Mode)',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: AppTheme.mutedText,
                    decoration: TextDecoration.underline,
                  ),
                ),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
              ),
            ),
          ],
        ],
      );
    }

    // Native Mobile (Android/iOS) and Desktop Button
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        onPressed: _isLoading ? null : _handleNativeGoogleSignIn,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppTheme.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.navy),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomPaint(
                    size: const Size(20, 20),
                    painter: GoogleLogoPainter(),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    buttonLabel,
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Crisp, standalone vector painter for official 4-color Google "G" logo
class GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double stroke = w * 0.22;
    final center = Offset(w / 2, h / 2);
    final radius = (w / 2) - (stroke / 2);

    final rect = Rect.fromCircle(center: center, radius: radius);

    final paintBlue = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.square;

    final paintRed = Paint()
      ..color = const Color(0xFFEA4335)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;

    final paintYellow = Paint()
      ..color = const Color(0xFFFBBC05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;

    final paintGreen = Paint()
      ..color = const Color(0xFF34A853)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;

    // Draw Blue bar from center towards right
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTRB(w * 0.45, h * 0.5 - stroke / 2, w - stroke / 2 + 1, h * 0.5 + stroke / 2),
      barPaint,
    );

    // Arcs
    canvas.drawArc(rect, 0, -math.pi / 4, false, paintBlue);
    canvas.drawArc(rect, -math.pi / 4, -math.pi / 2, false, paintRed);
    canvas.drawArc(rect, -3 * math.pi / 4, -math.pi / 2, false, paintYellow);
    canvas.drawArc(rect, -5 * math.pi / 4, -math.pi / 2, false, paintGreen);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
