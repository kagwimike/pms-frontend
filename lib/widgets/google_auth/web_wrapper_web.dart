import 'package:flutter/widgets.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:google_sign_in_web/google_sign_in_web.dart';
import 'package:google_sign_in_web/web_only.dart' as gsi_web;

/// Ensure the Google Sign-In web plugin instance is registered on the platform interface
void ensureGoogleSignInWebPlugin() {
  try {
    if (GoogleSignInPlatform.instance is! GoogleSignInPlugin) {
      GoogleSignInPlatform.instance = GoogleSignInPlugin();
    }
  } catch (e) {
    debugPrint('Could not initialize GoogleSignInPlugin: $e');
  }
}

/// Web implementation using the official Google Identity Services (GIS) button renderer
Widget renderGsiButton({
  double? width,
  bool isSignUp = false,
}) {
  try {
    ensureGoogleSignInWebPlugin();
    return gsi_web.renderButton(
      configuration: gsi_web.GSIButtonConfiguration(
        type: gsi_web.GSIButtonType.standard,
        theme: gsi_web.GSIButtonTheme.outline,
        size: gsi_web.GSIButtonSize.large,
        text: isSignUp ? gsi_web.GSIButtonText.signupWith : gsi_web.GSIButtonText.signinWith,
        shape: gsi_web.GSIButtonShape.rectangular,
        logoAlignment: gsi_web.GSIButtonLogoAlignment.left,
        minimumWidth: width ?? 320,
      ),
    );
  } catch (e) {
    debugPrint('Google Sign-In Web button rendering error: $e');
    return const SizedBox.shrink();
  }
}
