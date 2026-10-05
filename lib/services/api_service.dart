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
    await http.delete(Uri.parse('${AppConfig.apiBaseUrl}/properties/$id'), headers: _headers);
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

  Future<Map<String, dynamic>> createUnit(Map<String, dynamic> data) async {
    final res = await http.post(Uri.parse('${AppConfig.apiBaseUrl}/units/'), headers: _headers, body: jsonEncode(data));
    return _processResponse(res);
  }

  Future<Map<String, dynamic>> updateUnit(int id, Map<String, dynamic> data) async {
    final res = await http.put(Uri.parse('${AppConfig.apiBaseUrl}/units/$id'), headers: _headers, body: jsonEncode(data));
    return _processResponse(res);
  }

  Future<void> deleteUnit(int id) async {
    await http.delete(Uri.parse('${AppConfig.apiBaseUrl}/units/$id'), headers: _headers);
  }

  // ─── Tenants (Users with role TENANT) ───
  Future<Map<String, dynamic>> getUsers({int limit = 10, String? cursor}) async {
    final res = await http.get(Uri.parse('${AppConfig.apiBaseUrl}/users/?limit=$limit${cursor != null ? '&cursor=$cursor' : ''}'), headers: _headers);
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

  Future<Map<String, dynamic>> createLease(Map<String, dynamic> data) async {
    final res = await http.post(Uri.parse('${AppConfig.apiBaseUrl}/leases/'), headers: _headers, body: jsonEncode(data));
    return _processResponse(res);
  }

  Future<Map<String, dynamic>> updateLease(int id, Map<String, dynamic> data) async {
    final res = await http.put(Uri.parse('${AppConfig.apiBaseUrl}/leases/$id'), headers: _headers, body: jsonEncode(data));
    return _processResponse(res);
  }

  Future<void> deleteLease(int id) async {
    await http.delete(Uri.parse('${AppConfig.apiBaseUrl}/leases/$id'), headers: _headers);
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
    await http.delete(Uri.parse('${AppConfig.apiBaseUrl}/invoices/$id'), headers: _headers);
  }

  // ─── Payments ───
  Future<Map<String, dynamic>> getPayments({int limit = 10, String? cursor}) async {
    final res = await http.get(Uri.parse('${AppConfig.apiBaseUrl}/finance/?limit=$limit${cursor != null ? '&cursor=$cursor' : ''}'), headers: _headers);
    return _processResponse(res);
  }

  Future<Map<String, dynamic>> createPayment(Map<String, dynamic> data) async {
    final res = await http.post(Uri.parse('${AppConfig.apiBaseUrl}/finance/payments'), headers: _headers, body: jsonEncode(data));
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

  // ─── Inspections ───
  Future<Map<String, dynamic>> getInspections({int limit = 10, String? cursor}) async {
    final res = await http.get(Uri.parse('${AppConfig.apiBaseUrl}/inspections/?limit=$limit${cursor != null ? '&cursor=$cursor' : ''}'), headers: _headers);
    return _processResponse(res);
  }

  // ─── Notifications ───
  Future<Map<String, dynamic>> getNotifications({int limit = 10, String? cursor}) async {
    final res = await http.get(Uri.parse('${AppConfig.apiBaseUrl}/notifications/?limit=$limit${cursor != null ? '&cursor=$cursor' : ''}'), headers: _headers);
    return _processResponse(res);
  }

  // ─── Documents ───
  Future<Map<String, dynamic>> getDocuments({int limit = 10, String? cursor}) async {
    final res = await http.get(Uri.parse('${AppConfig.apiBaseUrl}/documents/?limit=$limit${cursor != null ? '&cursor=$cursor' : ''}'), headers: _headers);
    return _processResponse(res);
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
}

