import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'widgets/landing_page.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/owner_dashboard.dart';
import 'screens/tenant_dashboard.dart';
import 'screens/communication/communication_inbox_screen.dart';
import 'features/caretaker/caretaker_dashboard_screen.dart';
import 'features/vendor/vendor_dashboard_screen.dart';

import 'package:provider/provider.dart';
import 'providers/chat_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PmsProApp());
}

class PmsProApp extends StatelessWidget {
  const PmsProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: MaterialApp(
        title: 'PMS Pro - Property Management',
        theme: AppTheme.theme,
        debugShowCheckedModeBanner: false,
        home: const LandingPage(),
        routes: {
          '/login': (_) => const LoginScreen(),
          '/register': (_) => const RegisterScreen(),
          '/owner-dashboard': (_) => const OwnerDashboard(),
          '/tenant-dashboard': (_) => const TenantDashboard(),
          '/caretaker-dashboard': (_) => const CaretakerDashboardScreen(),
          '/vendor-dashboard': (_) => const VendorDashboardScreen(),
          '/communication-inbox': (_) => const CommunicationInboxScreen(),
        },
      ),
    );
  }
}
