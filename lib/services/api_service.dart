import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import 'auth_service.dart';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final _auth = AuthService();

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_auth.accessToken != null) 'Authorization': 'Bearer ${_auth.accessToken}',
      };

  Map<String, dynamic> _processResponse(http.Response res) {
    try {
      final body = jsonDecode(res.body);
      if (res.statusCode >= 400) {
        final message = body['message'] ?? 'An error occurred (Status ${res.statusCode})';
        throw ApiException(message);
      }
      return body;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to parse server response');
    }
  }

  // ─── Properties ───
  Future<Map<String, dynamic>> getProperties({int limit = 10, String? cursor}) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/properties/?limit=$limit${cursor != null ? '&cursor=$cursor' : ''}');
    final res = await http.get(uri, headers: _headers);
    return _processResponse(res);
  }

  Future<Map<String, dynamic>> getProperty(int id) async {
    final res = await http.get(Uri.parse('${AppConfig.apiBaseUrl}/properties/$id'), headers: _headers);
    return _processResponse(res);
  }

  Future<Map<String, dynamic>> createProperty(Map<String, dynamic> data, {List<http.MultipartFile>? images}) async {
    if (images == null || images.isEmpty) {
      final res = await http.post(Uri.parse('${AppConfig.apiBaseUrl}/properties/'), headers: _headers, body: jsonEncode(data));
      return _processResponse(res);
    }

    final req = http.MultipartRequest('POST', Uri.parse('${AppConfig.apiBaseUrl}/properties/'));
    req.headers.addAll({
      if (_auth.accessToken != null) 'Authorization': 'Bearer ${_auth.accessToken}',
    });

    data.forEach((key, value) {
      if (value != null) {
        req.fields[key] = value.toString();
      }
    });

    req.files.addAll(images);

    final streamedResponse = await req.send();
    final res = await http.Response.fromStream(streamedResponse);
    return _processResponse(res);
  }

  Future<Map<String, dynamic>> updateProperty(int id, Map<String, dynamic> data) async {
    final res = await http.put(Uri.parse('${AppConfig.apiBaseUrl}/properties/$id'), headers: _headers, body: jsonEncode(data));
    return _processResponse(res);
  }

  Future<void> deleteProperty(int id) async {
    final res = await http.delete(Uri.parse('${AppConfig.apiBaseUrl}/properties/$id'), headers: _headers);
    _processResponse(res);
  }

  // ─── Units ───
  Future<Map<String, dynamic>> getUnits({int limit = 10, String? cursor, int? propertyId, String? status}) async {
    var url = '${AppConfig.apiBaseUrl}/units/?limit=$limit';
    if (cursor != null) url += '&cursor=$cursor';
    if (propertyId != null) url += '&property_id=$propertyId';
    if (status != null) url += '&status=$status';
    final res = await http.get(Uri.parse(url), headers: _headers);
    return _processResponse(res);
  }
  Future<Map<String, dynamic>> getUnit(int id) async {
    final res = await http.get(Uri.parse('${AppConfig.apiBaseUrl}/units/$id'), headers: _headers);
    return _processResponse(res);
  }

  Future<Map<String, dynamic>> createUnit(Map<String, dynamic> data) async {
    final res = await http.post(Uri.parse('${AppConfig.apiBaseUrl}/units/'), headers: _headers, body: jsonEncode(data));
    return _processResponse(res);
  }

  Future<Map<String, dynamic>> updateUnit(int id, Map<String, dynamic> data) async {
    final res = await http.put(Uri.parse('${AppConfig.apiBaseUrl}/units/$id'), headers: _headers, body: jsonEncode(data));
    return _processResponse(res);
  }

  Future<void> deleteUnit(int id) async {
    final res = await http.delete(Uri.parse('${AppConfig.apiBaseUrl}/units/$id'), headers: _headers);
    _processResponse(res);
  }

  // ─── Tenants (Users with role TENANT) ───
  Future<Map<String, dynamic>> getUsers({int limit = 10, String? cursor}) async {
    final res = await http.get(Uri.parse('${AppConfig.apiBaseUrl}/users/?limit=$limit${cursor != null ? '&cursor=$cursor' : ''}'), headers: _headers);
    return _processResponse(res);
  }
  Future<Map<String, dynamic>> getUser(int id) async {
    final res = await http.get(Uri.parse('${AppConfig.apiBaseUrl}/users/$id'), headers: _headers);
    return _processResponse(res);
  }

  Future<Map<String, dynamic>> createTenant(Map<String, dynamic> data) async {
    // Send to auth register endpoint to create a user account for the tenant
    data['role'] = 'TENANT';
    final res = await http.post(Uri.parse('${AppConfig.apiBaseUrl}/auth/register'), headers: _headers, body: jsonEncode(data));
    return _processResponse(res);
  }

  Future<Map<String, dynamic>> createTeamMember(Map<String, dynamic> data) async {
    final res = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/auth/register'),
      headers: _headers,
      body: jsonEncode(data),
    );
    return _processResponse(res);
  }

  // ─── Leases ───
  Future<Map<String, dynamic>> getLeases({int limit = 10, String? cursor, String? status}) async {
    var url = '${AppConfig.apiBaseUrl}/leases/?limit=$limit';
    if (cursor != null) url += '&cursor=$cursor';
    if (status != null) url += '&status=$status';
    final res = await http.get(Uri.parse(url), headers: _headers);
    return _processResponse(res);
  }
  Future<Map<String, dynamic>> getLease(int id) async {
    final res = await http.get(Uri.parse('${AppConfig.apiBaseUrl}/leases/$id'), headers: _headers);
    return _processResponse(res);
  }

  Future<Map<String, dynamic>> createLease(Map<String, dynamic> data) async {
    final res = await http.post(Uri.parse('${AppConfig.apiBaseUrl}/leases/'), headers: _headers, body: jsonEncode(data));
    return _processResponse(res);
  }

  Future<Map<String, dynamic>> updateLease(int id, Map<String, dynamic> data) async {
    final res = await http.put(Uri.parse('${AppConfig.apiBaseUrl}/leases/$id'), headers: _headers, body: jsonEncode(data));
    return _processResponse(res);
  }

  Future<void> deleteLease(int id) async {
    final res = await http.delete(Uri.parse('${AppConfig.apiBaseUrl}/leases/$id'), headers: _headers);
    _processResponse(res);
  }

  // ─── Invoices ───
  Future<Map<String, dynamic>> getInvoices({int limit = 10, String? cursor, String? status}) async {
    var url = '${AppConfig.apiBaseUrl}/invoices/?limit=$limit';
    if (cursor != null) url += '&cursor=$cursor';
    if (status != null) url += '&status=$status';
    final res = await http.get(Uri.parse(url), headers: _headers);
    return _processResponse(res);
  }

  Future<Map<String, dynamic>> createInvoice(Map<String, dynamic> data) async {
    final res = await http.post(Uri.parse('${AppConfig.apiBaseUrl}/invoices/'), headers: _headers, body: jsonEncode(data));
    return _processResponse(res);
  }

  Future<Map<String, dynamic>> updateInvoice(int id, Map<String, dynamic> data) async {
    final res = await http.put(Uri.parse('${AppConfig.apiBaseUrl}/invoices/$id'), headers: _headers, body: jsonEncode(data));
    return _processResponse(res);
  }

  Future<void> deleteInvoice(int id) async {
    final res = await http.delete(Uri.parse('${AppConfig.apiBaseUrl}/invoices/$id'), headers: _headers);
    _processResponse(res);
  }

  // ─── Payments ───
  Future<Map<String, dynamic>> getPayments({int limit = 10, String? cursor, String? status}) async {
    var url = '${AppConfig.apiBaseUrl}/finance/payments?limit=$limit';
    if (cursor != null) url += '&cursor=$cursor';
    if (status != null) url += '&status=$status';
    final res = await http.get(Uri.parse(url), headers: _headers);
    return _processResponse(res);
  }

  Future<Map<String, dynamic>> createPayment(Map<String, dynamic> data) async {
    final res = await http.post(Uri.parse('${AppConfig.apiBaseUrl}/finance/payments'), headers: _headers, body: jsonEncode(data));
    return _processResponse(res);
  }

  Future<Map<String, dynamic>> initiateMpesaPayment(int invoiceId, String phone, double amount) async {
    final res = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/finance/payments/mpesa/stk-push'),
      headers: _headers,
      body: jsonEncode({
        'invoice_id': invoiceId,
        'phone': phone,
        'amount': amount,
      }),
    );
    return _processResponse(res);
  }

  Future<Map<String, dynamic>> getPaymentGateways({int? invoiceId, int? propertyId}) async {
    var url = '${AppConfig.apiBaseUrl}/finance/payments/gateways';
    final params = <String>[];
    if (invoiceId != null) params.add('invoice_id=$invoiceId');
    if (propertyId != null) params.add('property_id=$propertyId');
    if (params.isNotEmpty) url += '?${params.join('&')}';

    final res = await http.get(Uri.parse(url), headers: _headers);
    return _processResponse(res);
  }

  Future<Map<String, dynamic>> submitBankPaymentProof({
    required int invoiceId,
    required double amount,
    required String reference,
    int? bankAccountId,
    String? notes,
  }) async {
    final res = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/finance/payments'),
      headers: _headers,
      body: jsonEncode({
        'invoice_id': invoiceId,
        'amount': amount,
        'payment_method': 'BANK_TRANSFER',
        'transaction_reference': reference,
        if (bankAccountId != null) 'bank_account_id': bankAccountId,
        if (notes != null) 'notes': notes,
      }),
    );
    return _processResponse(res);
  }

  // ─── Unmatched Deposits Queue (Phase 3) ───
  Future<Map<String, dynamic>> getUnmatchedPayments({
    String? query,
    int? bankAccountId,
    int? uploadId,
    double? minAmount,
    double? maxAmount,
    int page = 1,
    int limit = 20,
  }) async {
    var url = '${AppConfig.apiBaseUrl}/finance/payments/unmatched?page=$page&limit=$limit';
    if (query != null && query.isNotEmpty) url += '&q=${Uri.encodeComponent(query)}';
    if (bankAccountId != null) url += '&bank_account_id=$bankAccountId';
    if (uploadId != null) url += '&statement_upload_id=$uploadId';
    if (minAmount != null) url += '&min_amount=$minAmount';
    if (maxAmount != null) url += '&max_amount=$maxAmount';

    final res = await http.get(Uri.parse(url), headers: _headers);
    return _processResponse(res);
  }

  Future<Map<String, dynamic>> getUnmatchedStats() async {
    final res = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/finance/payments/unmatched/stats'),
      headers: _headers,
    );
    return _processResponse(res);
  }

  Future<Map<String, dynamic>> assignUnmatchedPayment(
    int paymentId,
    int invoiceId, {
    String? notes,
  }) async {
    final res = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/finance/payments/unmatched/$paymentId/assign'),
      headers: _headers,
      body: jsonEncode({
        'invoice_id': invoiceId,
        if (notes != null) 'notes': notes,
      }),
    );
    return _processResponse(res);
  }

  Future<Map<String, dynamic>> resolveUnmatchedPayment(
    int paymentId,
    String resolution, {
    String? reason,
  }) async {
    final res = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/finance/payments/unmatched/$paymentId/resolve'),
      headers: _headers,
      body: jsonEncode({
        'resolution': resolution,
        if (reason != null) 'reason': reason,
      }),
    );
    return _processResponse(res);
  }

  Future<Map<String, dynamic>> getPaymentCandidates(int paymentId) async {
    final res = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/finance/payments/unmatched/$paymentId/candidates'),
      headers: _headers,
    );
    return _processResponse(res);
  }

  // ─── Bank Accounts Management (Phase 4) ───
  Future<Map<String, dynamic>> getBankAccounts({int? propertyId, bool? isActive}) async {
    var url = '${AppConfig.apiBaseUrl}/finance/payments/bank-accounts';
    final params = <String>[];
    if (propertyId != null) params.add('property_id=$propertyId');
    if (isActive != null) params.add('is_active=$isActive');
    if (params.isNotEmpty) url += '?${params.join('&')}';

    final res = await http.get(Uri.parse(url), headers: _headers);
    return _processResponse(res);
  }

  Future<Map<String, dynamic>> getSupportedBanks() async {
    final res = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/finance/payments/bank-accounts/banks'),
      headers: _headers,
    );
    return _processResponse(res);
  }

  Future<Map<String, dynamic>> createBankAccount(Map<String, dynamic> data) async {
    final res = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/finance/payments/bank-accounts'),
      headers: _headers,
      body: jsonEncode(data),
    );
    return _processResponse(res);
  }

  Future<Map<String, dynamic>> updateBankAccount(int id, Map<String, dynamic> data) async {
    final res = await http.patch(
      Uri.parse('${AppConfig.apiBaseUrl}/finance/payments/bank-accounts/$id'),
      headers: _headers,
      body: jsonEncode(data),
    );
    return _processResponse(res);
  }

  Future<Map<String, dynamic>> deleteBankAccount(int id) async {
    final res = await http.delete(
      Uri.parse('${AppConfig.apiBaseUrl}/finance/payments/bank-accounts/$id'),
      headers: _headers,
    );
    return _processResponse(res);
  }

  Future<Map<String, dynamic>> setPrimaryBankAccount(int id) async {
    final res = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/finance/payments/bank-accounts/$id/primary'),
      headers: _headers,
    );
    return _processResponse(res);
  }

  // ─── Bank Statement Ingestion & Reconciliation (Phase 5) ───
  Future<Map<String, dynamic>> uploadBankStatement({
    required List<int> bytes,
    required String filename,
    int? bankAccountId,
  }) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/finance/payments/statements/upload');
    final req = http.MultipartRequest('POST', uri);
    req.headers.addAll({
      if (_auth.accessToken != null) 'Authorization': 'Bearer ${_auth.accessToken}',
    });
    if (bankAccountId != null) {
      req.fields['bank_account_id'] = bankAccountId.toString();
    }
    req.files.add(
      http.MultipartFile.fromBytes(
        'statement',
        bytes,
        filename: filename,
      ),
    );
    final streamedResponse = await req.send();
    final res = await http.Response.fromStream(streamedResponse);
    return _processResponse(res);
  }

  Future<Map<String, dynamic>> getStatementUploads({
    int? bankAccountId,
    int page = 1,
    int limit = 20,
  }) async {
    var url = '${AppConfig.apiBaseUrl}/finance/payments/statements?page=$page&limit=$limit';
    if (bankAccountId != null) url += '&bank_account_id=$bankAccountId';
    final res = await http.get(Uri.parse(url), headers: _headers);
    return _processResponse(res);
  }

  Future<Map<String, dynamic>> getStatementUpload(int id) async {
    final res = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/finance/payments/statements/$id'),
      headers: _headers,
    );
    return _processResponse(res);
  }

  Future<Map<String, dynamic>> updatePaymentStatus(int id, String status) async {
    final res = await http.patch(
      Uri.parse('${AppConfig.apiBaseUrl}/finance/payments/$id'),
      headers: _headers,
      body: jsonEncode({'status': status}),
    );
    return _processResponse(res);
  }

  // ─── Maintenance ───
  Future<Map<String, dynamic>> getMaintenanceRequests({int limit = 10, String? cursor, String? status}) async {
    var url = '${AppConfig.apiBaseUrl}/maintenance/requests?limit=$limit';
    if (cursor != null) url += '&cursor=$cursor';
    if (status != null) url += '&status=$status';
    final res = await http.get(Uri.parse(url), headers: _headers);
    return _processResponse(res);
  }

  Future<Map<String, dynamic>> getMaintenanceRequest(int id) async {
    final res = await http.get(Uri.parse('${AppConfig.apiBaseUrl}/maintenance/requests/$id'), headers: _headers);
    return _processResponse(res);
  }

  Future<Map<String, dynamic>> createMaintenanceRequest(Map<String, dynamic> data) async {
    final res = await http.post(Uri.parse('${AppConfig.apiBaseUrl}/maintenance/requests'), headers: _headers, body: jsonEncode(data));
    return _processResponse(res);
  }

  Future<Map<String, dynamic>> updateMaintenanceRequest(int id, Map<String, dynamic> data) async {
    final res = await http.put(Uri.parse('${AppConfig.apiBaseUrl}/maintenance/requests/$id'), headers: _headers, body: jsonEncode(data));
    return _processResponse(res);
  }

  // ─── Vendors ───
  Future<Map<String, dynamic>> getVendors({int limit = 50, String? cursor}) async {
    final res = await http.get(Uri.parse('${AppConfig.apiBaseUrl}/maintenance/vendors?limit=$limit${cursor != null ? '&cursor=$cursor' : ''}'), headers: _headers);
    return _processResponse(res);
  }

  Future<Map<String, dynamic>> createVendor(Map<String, dynamic> data) async {
    final res = await http.post(Uri.parse('${AppConfig.apiBaseUrl}/maintenance/vendors'), headers: _headers, body: jsonEncode(data));
    return _processResponse(res);
  }

  Future<Map<String, dynamic>> updateVendor(int id, Map<String, dynamic> data) async {
    final res = await http.put(Uri.parse('${AppConfig.apiBaseUrl}/maintenance/vendors/$id'), headers: _headers, body: jsonEncode(data));
    return _processResponse(res);
  }

  Future<void> deleteVendor(int id) async {
    final res = await http.delete(Uri.parse('${AppConfig.apiBaseUrl}/maintenance/vendors/$id'), headers: _headers);
    _processResponse(res);
  }

  // ─── Inspections ───
  Future<Map<String, dynamic>> getInspections({int limit = 50, String? cursor, int? leaseId, String? status, String? type}) async {
    var url = '${AppConfig.apiBaseUrl}/inspections/?limit=$limit';
    if (cursor != null) url += '&cursor=$cursor';
    if (leaseId != null) url += '&lease_id=$leaseId';
    if (status != null) url += '&status=$status';
    if (type != null) url += '&inspection_type=$type';
    final res = await http.get(Uri.parse(url), headers: _headers);
    return _processResponse(res);
  }

  Future<Map<String, dynamic>> getInspection(int id) async {
    final res = await http.get(Uri.parse('${AppConfig.apiBaseUrl}/inspections/$id'), headers: _headers);
    return _processResponse(res);
  }

  Future<Map<String, dynamic>> createInspection(Map<String, dynamic> data) async {
    final res = await http.post(Uri.parse('${AppConfig.apiBaseUrl}/inspections/'), headers: _headers, body: jsonEncode(data));
    return _processResponse(res);
  }

  Future<Map<String, dynamic>> updateInspection(int id, Map<String, dynamic> data) async {
    final res = await http.put(Uri.parse('${AppConfig.apiBaseUrl}/inspections/$id'), headers: _headers, body: jsonEncode(data));
    return _processResponse(res);
  }

  Future<void> deleteInspection(int id) async {
    final res = await http.delete(Uri.parse('${AppConfig.apiBaseUrl}/inspections/$id'), headers: _headers);
    _processResponse(res);
  }

  Future<Map<String, dynamic>> getInspectionCatalog() async {
    final res = await http.get(Uri.parse('${AppConfig.apiBaseUrl}/inspections/catalog'), headers: _headers);
    return _processResponse(res);
  }

  Future<Map<String, dynamic>> addInspectionDamage(int inspectionId, Map<String, dynamic> data) async {
    final res = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/inspections/$inspectionId/damages'),
      headers: _headers,
      body: jsonEncode(data),
    );
    return _processResponse(res);
  }

  Future<void> deleteInspectionDamage(int damageId) async {
    final res = await http.delete(Uri.parse('${AppConfig.apiBaseUrl}/inspections/damages/$damageId'), headers: _headers);
    _processResponse(res);
  }

  Future<Map<String, dynamic>> getDepositReconciliation(int inspectionId) async {
    final res = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/inspections/$inspectionId/deposit-reconciliation'),
      headers: _headers,
    );
    return _processResponse(res);
  }

  Future<Map<String, dynamic>> finalizeDepositRefund(int inspectionId, Map<String, dynamic> data) async {
    final res = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/inspections/$inspectionId/finalize-refund'),
      headers: _headers,
      body: jsonEncode(data),
    );
    return _processResponse(res);
  }

  // ─── Incidents ───
  Future<Map<String, dynamic>> getIncidents({int limit = 10, String? cursor, String? status}) async {
    var url = '${AppConfig.apiBaseUrl}/incidents?limit=$limit';
    if (cursor != null) url += '&cursor=$cursor';
    if (status != null) url += '&status=$status';
    final res = await http.get(Uri.parse(url), headers: _headers);
    return _processResponse(res);
  }

  Future<Map<String, dynamic>> createIncident(Map<String, dynamic> data) async {
    final res = await http.post(Uri.parse('${AppConfig.apiBaseUrl}/incidents'), headers: _headers, body: jsonEncode(data));
    return _processResponse(res);
  }

  Future<Map<String, dynamic>> updateIncidentStatus(int id, String status) async {
    final res = await http.patch(Uri.parse('${AppConfig.apiBaseUrl}/incidents/$id/status'), headers: _headers, body: jsonEncode({'status': status}));
    return _processResponse(res);
  }
  
  // ─── Communication ───
  Future<Map<String, dynamic>> getSessionByMaintenance(int maintenanceId) async {
    final res = await http.get(Uri.parse('${AppConfig.apiBaseUrl}/communication/sessions/maintenance/$maintenanceId'), headers: _headers);
    return _processResponse(res);
  }

  Future<Map<String, dynamic>> getMessages(int sessionId) async {
    // API returns List directly, so we need to wrap it if _processResponse expects Map, but let's see _processResponse.
    // _processResponse returns dynamic which is cast to Map usually, but it can return List. Wait, ApiService returns `Future<Map<String, dynamic>>`.
    // Let's change it to dynamic to support List.
    final res = await http.get(Uri.parse('${AppConfig.apiBaseUrl}/communication/sessions/$sessionId/messages'), headers: _headers);
    final data = _processResponse(res);
    if (data is List) {
      return {'data': data};
    }
    return data;
  }

  Future<Map<String, dynamic>> sendMessage(int sessionId, String message, {String messageType = 'TEXT'}) async {
    final res = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/communication/sessions/$sessionId/messages'), 
      headers: _headers, 
      body: jsonEncode({'message': message, 'message_type': messageType})
    );
    return _processResponse(res);
  }

  // ─── Notifications ───
  Future<Map<String, dynamic>> getNotifications({int limit = 10, String? cursor}) async {
    final res = await http.get(Uri.parse('${AppConfig.apiBaseUrl}/notifications/?limit=$limit${cursor != null ? '&cursor=$cursor' : ''}'), headers: _headers);
    return _processResponse(res);
  }

  Future<Map<String, dynamic>> markNotificationAsRead(String id) async {
    final res = await http.patch(Uri.parse('${AppConfig.apiBaseUrl}/notifications/$id/read'), headers: _headers);
    return _processResponse(res);
  }

  // ─── Global Search ───
  Future<Map<String, dynamic>> globalSearch(String query, {String? type, String? cursor, int limit = 5}) async {
    final queryParams = {
      'q': query,
      'limit': limit.toString(),
    };
    if (type != null) queryParams['type'] = type.toLowerCase();
    if (cursor != null) queryParams['cursor'] = cursor;

    final uri = Uri.parse('${AppConfig.apiBaseUrl}/search').replace(queryParameters: queryParams);
    final res = await http.get(uri, headers: _headers);
    return _processResponse(res);
  }

  // ─── Dashboards & Reports ───
  Future<Map<String, dynamic>> getCaretakerDashboard() async {
    final res = await http.get(Uri.parse('${AppConfig.apiBaseUrl}/dashboard/caretaker'), headers: _headers);
    return _processResponse(res);
  }

  Future<Map<String, dynamic>> getVendorDashboard() async {
    final res = await http.get(Uri.parse('${AppConfig.apiBaseUrl}/dashboard/vendor'), headers: _headers);
    return _processResponse(res);
  }

  Future<Map<String, dynamic>> getCaretakerReports() async {
    final res = await http.get(Uri.parse('${AppConfig.apiBaseUrl}/dashboard/caretaker/reports'), headers: _headers);
    return _processResponse(res);
  }

  // ─── Settings Module API ───
  Future<Map<String, dynamic>> getSettings(String category, {int? propertyId}) async {
    final query = propertyId != null ? '?property_id=$propertyId' : '';
    final res = await http.get(Uri.parse('${AppConfig.apiBaseUrl}/settings/$category$query'), headers: _headers);
    return _processResponse(res);
  }

  Future<Map<String, dynamic>> updateSettings(String category, Map<String, dynamic> data) async {
    final res = await http.put(
      Uri.parse('${AppConfig.apiBaseUrl}/settings/$category'),
      headers: _headers,
      body: jsonEncode(data),
    );
    return _processResponse(res);
  }

  Future<Map<String, dynamic>> getProfilePreferences() async {
    final res = await http.get(Uri.parse('${AppConfig.apiBaseUrl}/settings/profile'), headers: _headers);
    return _processResponse(res);
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    final res = await http.put(
      Uri.parse('${AppConfig.apiBaseUrl}/settings/profile'),
      headers: _headers,
      body: jsonEncode(data),
    );
    return _processResponse(res);
  }

  Future<Map<String, dynamic>> updatePreferences(Map<String, dynamic> data) async {
    final res = await http.put(
      Uri.parse('${AppConfig.apiBaseUrl}/settings/preferences'),
      headers: _headers,
      body: jsonEncode(data),
    );
    return _processResponse(res);
  }

  Future<Map<String, dynamic>> changePassword(String currentPassword, String newPassword) async {
    final res = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/settings/change-password'),
      headers: _headers,
      body: jsonEncode({
        'current_password': currentPassword,
        'new_password': newPassword,
      }),
    );
    return _processResponse(res);
  }

  // ─── Audit Logs ───
  Future<Map<String, dynamic>> getAuditLogs({
    int limit = 15,
    String? cursor,
    String? module,
    String? outcome,
    String? severity,
    String? search,
    String? entityType,
    String? entityId,
    String? propertyId,
    String? startDate,
    String? endDate,
  }) async {
    final queryParams = <String, String>{'limit': limit.toString()};
    if (cursor != null) queryParams['cursor'] = cursor;
    if (module != null && module.isNotEmpty) queryParams['module'] = module;
    if (outcome != null && outcome.isNotEmpty) queryParams['outcome'] = outcome;
    if (severity != null && severity.isNotEmpty) queryParams['severity'] = severity;
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (entityType != null && entityType.isNotEmpty) queryParams['entity_type'] = entityType;
    if (entityId != null && entityId.isNotEmpty) queryParams['entity_id'] = entityId;
    if (propertyId != null && propertyId.isNotEmpty) queryParams['property_id'] = propertyId;
    if (startDate != null && startDate.isNotEmpty) queryParams['start_date'] = startDate;
    if (endDate != null && endDate.isNotEmpty) queryParams['end_date'] = endDate;

    final uri = Uri.parse('${AppConfig.apiBaseUrl}/auditlogs/').replace(queryParameters: queryParams);
    final res = await http.get(uri, headers: _headers);
    return _processResponse(res);
  }

  Future<Map<String, dynamic>> getAuditLogById(dynamic id) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/auditlogs/$id');
    final res = await http.get(uri, headers: _headers);
    return _processResponse(res);
  }

  String getAuditExportUrl({
    String? module,
    String? outcome,
    String? severity,
    String? startDate,
    String? endDate,
  }) {
    final queryParams = <String, String>{};
    if (module != null && module.isNotEmpty) queryParams['module'] = module;
    if (outcome != null && outcome.isNotEmpty) queryParams['outcome'] = outcome;
    if (severity != null && severity.isNotEmpty) queryParams['severity'] = severity;
    if (startDate != null && startDate.isNotEmpty) queryParams['start_date'] = startDate;
    if (endDate != null && endDate.isNotEmpty) queryParams['end_date'] = endDate;

    return Uri.parse('${AppConfig.apiBaseUrl}/auditlogs/export').replace(queryParameters: queryParams).toString();
  }

  // ─── Documents ───
  Future<Map<String, dynamic>> getDocuments({
    int limit = 15,
    String? cursor,
    String? entityType,
    String? entityId,
    String? propertyId,
    String? docType,
    String? status,
    bool? isArchived,
    String? search,
  }) async {
    final queryParams = <String, String>{'limit': limit.toString()};
    if (cursor != null) queryParams['cursor'] = cursor;
    if (entityType != null && entityType.isNotEmpty) queryParams['entity_type'] = entityType;
    if (entityId != null && entityId.isNotEmpty) queryParams['entity_id'] = entityId;
    if (propertyId != null && propertyId.isNotEmpty) queryParams['property_id'] = propertyId;
    if (docType != null && docType.isNotEmpty) queryParams['document_type'] = docType;
    if (status != null && status.isNotEmpty) queryParams['status'] = status;
    if (isArchived != null) queryParams['is_archived'] = isArchived.toString();
    if (search != null && search.isNotEmpty) queryParams['search'] = search;

    final uri = Uri.parse('${AppConfig.apiBaseUrl}/documents/').replace(queryParameters: queryParams);
    final res = await http.get(uri, headers: _headers);
    return _processResponse(res);
  }

  Future<Map<String, dynamic>> getDocument(dynamic id) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/documents/$id');
    final res = await http.get(uri, headers: _headers);
    return _processResponse(res);
  }

  Future<Map<String, dynamic>> createDocument(
    Map<String, dynamic> data, {
    required http.MultipartFile file,
  }) async {
    final req = http.MultipartRequest('POST', Uri.parse('${AppConfig.apiBaseUrl}/documents/'));
    req.headers.addAll({
      if (_auth.accessToken != null) 'Authorization': 'Bearer ${_auth.accessToken}',
    });

    data.forEach((key, value) {
      if (value != null) {
        req.fields[key] = value.toString();
      }
    });

    req.files.add(file);

    final streamedResponse = await req.send();
    final res = await http.Response.fromStream(streamedResponse);
    return _processResponse(res);
  }

  Future<Map<String, dynamic>> uploadDocumentVersion(
    dynamic parentDocId,
    Map<String, dynamic> data, {
    required http.MultipartFile file,
  }) async {
    final req = http.MultipartRequest('POST', Uri.parse('${AppConfig.apiBaseUrl}/documents/$parentDocId/versions'));
    req.headers.addAll({
      if (_auth.accessToken != null) 'Authorization': 'Bearer ${_auth.accessToken}',
    });

    data.forEach((key, value) {
      if (value != null) {
        req.fields[key] = value.toString();
      }
    });

    req.files.add(file);

    final streamedResponse = await req.send();
    final res = await http.Response.fromStream(streamedResponse);
    return _processResponse(res);
  }

  Future<Map<String, dynamic>> updateDocument(dynamic id, Map<String, dynamic> data) async {
    final res = await http.patch(
      Uri.parse('${AppConfig.apiBaseUrl}/documents/$id'),
      headers: _headers,
      body: jsonEncode(data),
    );
    return _processResponse(res);
  }

  Future<Map<String, dynamic>> deleteDocument(dynamic id, {bool permanent = false}) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/documents/$id?permanent=$permanent');
    final res = await http.delete(uri, headers: _headers);
    return _processResponse(res);
  }

  String getDocumentDownloadUrl(dynamic id, {bool preview = false}) {
    final base = '${AppConfig.apiBaseUrl}/documents/$id/${preview ? 'preview' : 'download'}';
    return base;
  }

  // ─── Helper: extract list from any response shape ───
  static List<dynamic> extractList(Map<String, dynamic> response) {
    if (response.containsKey('data') && response['data'] is List) return response['data'];
    if (response.containsKey('results') && response['results'] is List) return response['results'];
    for (final v in response.values) {
      if (v is List) return v;
    }
    return [];
  }

  // ─── Helper: extract map/data object from response shape ───
  static Map<String, dynamic> extractMap(Map<String, dynamic> response) {
    if (response.containsKey('data') && response['data'] is Map) {
      return Map<String, dynamic>.from(response['data'] as Map);
    }
    return response;
  }
}

