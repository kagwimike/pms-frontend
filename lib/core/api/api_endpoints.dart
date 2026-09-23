import 'package:flutter/foundation.dart';

class ApiEndpoints {
  static String get baseUrl {
    const configuredUrl = String.fromEnvironment('API_BASE_URL');
    if (configuredUrl.isNotEmpty) return configuredUrl;

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3005/api';
    }
    return 'http://127.0.0.1:3005/api';
  }

  static String get apiOrigin {
    final uri = Uri.parse(baseUrl);
    return '${uri.scheme}://${uri.authority}';
  }

  static String resolveMediaUrl(String path) {
    final value = path.trim();
    if (value.isEmpty || Uri.tryParse(value)?.hasScheme == true) return value;
    return '${apiOrigin}${value.startsWith('/') ? value : '/$value'}';
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
  static String get invoices => '$baseUrl/invoices';
  static String get payments => '$baseUrl/finance/payments';

  // Maintenance & Vendors
  static String get maintenance => '$baseUrl/maintenance';
  static String get vendors => '$baseUrl/maintenance/vendors';

  // Inspections & Documents
  static String get inspections => '$baseUrl/inspections';
  static String get documents => '$baseUrl/documents';
  static String get notifications => '$baseUrl/notifications';
  static String get auditLogs => '$baseUrl/auditlogs';
}
