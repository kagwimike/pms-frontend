// Stub for non-web platforms where google_sign_in_web is not available.
import 'package:flutter/widgets.dart';

void ensureGoogleSignInWebPlugin() {}

Widget renderGsiButton({
  double? width,
  bool isSignUp = false,
  bool isDark = true,
  bool isPill = true,
}) {
  return const SizedBox.shrink();
}

