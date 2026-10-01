import 'package:flutter/material.dart';

import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/dashboard/presentation/screens/owner_dashboard_screen.dart';
import '../../features/properties/presentation/screens/add_property_screen.dart';
import '../../features/properties/presentation/screens/manage_units_screen.dart';
import '../../features/leases/presentation/screens/lease_form_screen.dart';
import '../../features/maintenance/presentation/screens/maintenance_form_screen.dart';
import '../../features/maintenance/presentation/screens/damage_form_screen.dart';

class AppRouter {
  static const String loginRoute = '/';
  static const String registerRoute = '/register';
  static const String ownerDashboardRoute = '/owner';
  static const String tenantDashboardRoute = '/tenant';
  static const String addPropertyRoute = '/add-property';
  static const String manageUnitsRoute = '/manage-units';
  static const String leaseFormRoute = '/lease-form';
  static const String maintenanceFormRoute = '/maintenance-form';
  static const String damageFormRoute = '/damage-form';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case loginRoute:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case registerRoute:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case ownerDashboardRoute:
        return MaterialPageRoute(builder: (_) => const OwnerDashboardScreen());
      case addPropertyRoute:
        return MaterialPageRoute(builder: (_) => const AddPropertyScreen());
      case manageUnitsRoute:
        return MaterialPageRoute(builder: (_) => const ManageUnitsScreen());
      case leaseFormRoute:
        return MaterialPageRoute(builder: (_) => const LeaseFormScreen());
      case maintenanceFormRoute:
        return MaterialPageRoute(builder: (_) => const MaintenanceFormScreen());
      case damageFormRoute:
        return MaterialPageRoute(builder: (_) => const DamageFormScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}
