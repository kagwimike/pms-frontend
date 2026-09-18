import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../ui/layouts/main_layout.dart';
import '../ui/screens/home.dart';
import '../ui/screens/placeholder_screen.dart';
import '../ui/screens/auth/login_screen.dart';
import '../ui/screens/auth/register_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return MainLayout(child: child);
      },
      routes: [
        GoRoute(
          path: '/properties',
          builder: (context, state) => const PlaceholderScreen(title: 'Properties'),
        ),
        GoRoute(
          path: '/leases',
          builder: (context, state) => const PlaceholderScreen(title: 'Leases'),
        ),
        GoRoute(
          path: '/add-property',
          builder: (context, state) => const PlaceholderScreen(title: 'Add Property'),
        ),
        GoRoute(
          path: '/create-lease',
          builder: (context, state) => const PlaceholderScreen(title: 'Create Lease'),
        ),
        GoRoute(
          path: '/invoices',
          builder: (context, state) => const PlaceholderScreen(title: 'Global Invoices'),
        ),
        GoRoute(
          path: '/payments',
          builder: (context, state) => const PlaceholderScreen(title: 'Collected Payments'),
        ),
        GoRoute(
          path: '/refunds',
          builder: (context, state) => const PlaceholderScreen(title: 'Process Deposit Refund'),
        ),
        GoRoute(
          path: '/inspections',
          builder: (context, state) => const PlaceholderScreen(title: 'View Inspections'),
        ),
        GoRoute(
          path: '/new-inspection',
          builder: (context, state) => const PlaceholderScreen(title: 'New Inspection'),
        ),
        GoRoute(
          path: '/record-damage',
          builder: (context, state) => const PlaceholderScreen(title: 'Record Damage'),
        ),
        GoRoute(
          path: '/deposit-summary',
          builder: (context, state) => const PlaceholderScreen(title: 'Deposit Summary'),
        ),
        GoRoute(
          path: '/maintenance-requests',
          builder: (context, state) => const PlaceholderScreen(title: 'All Requests'),
        ),
        GoRoute(
          path: '/new-maintenance',
          builder: (context, state) => const PlaceholderScreen(title: 'New Request'),
        ),
        GoRoute(
          path: '/vendors',
          builder: (context, state) => const PlaceholderScreen(title: 'Vendors'),
        ),
        GoRoute(
          path: '/about',
          builder: (context, state) => const PlaceholderScreen(title: 'About PMS Pro'),
        ),
        GoRoute(
          path: '/contact',
          builder: (context, state) => const PlaceholderScreen(title: 'Contact'),
        ),
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const PlaceholderScreen(title: 'Dashboard'),
        ),
      ],
    ),
  ],
);
