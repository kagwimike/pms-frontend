import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../ui/layouts/main_layout.dart';
import '../ui/screens/home.dart';
import '../ui/screens/placeholder_screen.dart';
import '../ui/screens/properties_screen.dart';
import '../ui/screens/units_screen.dart';
import '../ui/screens/dashboard_screen.dart';
import '../ui/screens/auth/login_screen.dart';
import '../ui/screens/auth/register_screen.dart';
import '../../providers/auth_provider.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey =
    GlobalKey<NavigatorState>();

GoRouter createAppRouter(AuthProvider authProvider) {
  return GoRouter(
    refreshListenable: authProvider,
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    redirect: (context, state) {
      final isPublicRoute =
          state.matchedLocation == '/' ||
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/about' ||
          state.matchedLocation == '/contact';

      if (authProvider.isLoading) return null;
      if (!authProvider.isAuthenticated && !isPublicRoute) {
        return '/login?redirect=${Uri.encodeComponent(state.uri.toString())}';
      }
      if (authProvider.isAuthenticated &&
          (state.matchedLocation == '/login' ||
              state.matchedLocation == '/register')) {
        return state.uri.queryParameters['redirect'] ?? '/dashboard';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return MainLayout(child: child);
        },
        routes: [
          GoRoute(
            path: '/properties',
            builder: (context, state) => const PropertiesScreen(),
          ),
          GoRoute(
            path: '/units',
            builder: (context, state) => const UnitsScreen(),
          ),
          GoRoute(
            path: '/leases',
            builder: (context, state) =>
                const PlaceholderScreen(title: 'Leases'),
          ),
          GoRoute(
            path: '/add-property',
            builder: (context, state) =>
                const PlaceholderScreen(title: 'Add Property'),
          ),
          GoRoute(
            path: '/create-lease',
            builder: (context, state) =>
                const PlaceholderScreen(title: 'Create Lease'),
          ),
          GoRoute(
            path: '/invoices',
            builder: (context, state) =>
                const PlaceholderScreen(title: 'Global Invoices'),
          ),
          GoRoute(
            path: '/payments',
            builder: (context, state) =>
                const PlaceholderScreen(title: 'Collected Payments'),
          ),
          GoRoute(
            path: '/refunds',
            builder: (context, state) =>
                const PlaceholderScreen(title: 'Process Deposit Refund'),
          ),
          GoRoute(
            path: '/inspections',
            builder: (context, state) =>
                const PlaceholderScreen(title: 'View Inspections'),
          ),
          GoRoute(
            path: '/new-inspection',
            builder: (context, state) =>
                const PlaceholderScreen(title: 'New Inspection'),
          ),
          GoRoute(
            path: '/record-damage',
            builder: (context, state) =>
                const PlaceholderScreen(title: 'Record Damage'),
          ),
          GoRoute(
            path: '/deposit-summary',
            builder: (context, state) =>
                const PlaceholderScreen(title: 'Deposit Summary'),
          ),
          GoRoute(
            path: '/maintenance-requests',
            builder: (context, state) =>
                const PlaceholderScreen(title: 'All Requests'),
          ),
          GoRoute(
            path: '/new-maintenance',
            builder: (context, state) =>
                const PlaceholderScreen(title: 'New Request'),
          ),
          GoRoute(
            path: '/vendors',
            builder: (context, state) =>
                const PlaceholderScreen(title: 'Vendors'),
          ),
          GoRoute(
            path: '/documents',
            builder: (context, state) =>
                const PlaceholderScreen(title: 'Documents'),
          ),
          GoRoute(
            path: '/notifications',
            builder: (context, state) =>
                const PlaceholderScreen(title: 'Notifications'),
          ),
          GoRoute(
            path: '/auditlogs',
            builder: (context, state) =>
                const PlaceholderScreen(title: 'Audit logs'),
          ),
          GoRoute(
            path: '/about',
            builder: (context, state) =>
                const PlaceholderScreen(title: 'About PMS Pro'),
          ),
          GoRoute(
            path: '/contact',
            builder: (context, state) =>
                const PlaceholderScreen(title: 'Contact'),
          ),
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
        ],
      ),
    ],
  );
}
