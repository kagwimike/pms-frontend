class ApiEndpoints {
  static const String baseUrl = 'http://localhost:5000/api';

  // Auth
  static const String login = '$baseUrl/auth/login';
  static const String register = '$baseUrl/auth/register';
  static const String googleAuth = '$baseUrl/auth/google';

  // Properties & Units
  static const String properties = '$baseUrl/properties';
  static const String units = '$baseUrl/units';

  // Users
  static const String users = '$baseUrl/users';

  // Bookings & Leases
  static const String bookings = '$baseUrl/bookings';
  static const String leases = '$baseUrl/leases';

  // Finance
  static const String finance = '$baseUrl/finance';
  static const String invoices = '$baseUrl/finance/invoices';
  static const String payments = '$baseUrl/finance/payments';
  static const String refunds = '$baseUrl/finance/refunds';

  // Maintenance & Vendors
  static const String maintenance = '$baseUrl/maintenance';
  static const String vendors = '$baseUrl/maintenance/vendors';

  // Inspections & Documents
  static const String inspections = '$baseUrl/inspections';
  static const String documents = '$baseUrl/documents';
  static const String notifications = '$baseUrl/notifications';
  static const String auditLogs = '$baseUrl/auditlogs';
}
