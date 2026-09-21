import 'package:flutter/foundation.dart';

class ApiEndpoints {
  static String get baseUrl {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3005/api';
    }
    return 'http://localhost:3005/api';
  }

  // Auth
  static String get login => '$baseUrl/auth/login';
  static String get register => '$baseUrl/auth/register';
  static String get googleAuth => '$baseUrl/auth/google';

  // Properties & Units
  static String get properties => '$baseUrl/properties';
  static String get units => '$baseUrl/units';

  // Users
  static String get users => '$baseUrl/users';

  // Bookings & Leases
  static String get bookings => '$baseUrl/bookings';
  static String get leases => '$baseUrl/leases';

  // Finance
  static String get finance => '$baseUrl/finance';
  static String get invoices => '$baseUrl/finance/invoices';
  static String get payments => '$baseUrl/finance/payments';
  static String get refunds => '$baseUrl/finance/refunds';

  // Maintenance & Vendors
  static String get maintenance => '$baseUrl/maintenance';
  static String get vendors => '$baseUrl/maintenance/vendors';

  // Inspections & Documents
  static String get inspections => '$baseUrl/inspections';
  static String get documents => '$baseUrl/documents';
  static String get notifications => '$baseUrl/notifications';
  static String get auditLogs => '$baseUrl/auditlogs';
}

