import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import 'auth_service.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final _auth = AuthService();

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_auth.accessToken != null) 'Authorization': 'Bearer ${_auth.accessToken}',
      };

  // ─── Properties ───
  Future<Map<String, dynamic>> getProperties({int limit = 10, String? cursor}) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/properties/?limit=$limit${cursor != null ? '&cursor=$cursor' : ''}');
    final res = await http.get(uri, headers: _headers);
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> getProperty(int id) async {
    final res = await http.get(Uri.parse('${AppConfig.apiBaseUrl}/properties/$id'), headers: _headers);
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> createProperty(Map<String, dynamic> data) async {
    final res = await http.post(Uri.parse('${AppConfig.apiBaseUrl}/properties/'), headers: _headers, body: jsonEncode(data));
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> updateProperty(int id, Map<String, dynamic> data) async {
    final res = await http.put(Uri.parse('${AppConfig.apiBaseUrl}/properties/$id'), headers: _headers, body: jsonEncode(data));
    return jsonDecode(res.body);
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
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> createUnit(Map<String, dynamic> data) async {
    final res = await http.post(Uri.parse('${AppConfig.apiBaseUrl}/units/'), headers: _headers, body: jsonEncode(data));
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> updateUnit(int id, Map<String, dynamic> data) async {
    final res = await http.put(Uri.parse('${AppConfig.apiBaseUrl}/units/$id'), headers: _headers, body: jsonEncode(data));
    return jsonDecode(res.body);
  }

  Future<void> deleteUnit(int id) async {
    await http.delete(Uri.parse('${AppConfig.apiBaseUrl}/units/$id'), headers: _headers);
  }

  // ─── Tenants (Users with role TENANT) ───
  Future<Map<String, dynamic>> getUsers({int limit = 10, String? cursor}) async {
    final res = await http.get(Uri.parse('${AppConfig.apiBaseUrl}/users/?limit=$limit${cursor != null ? '&cursor=$cursor' : ''}'), headers: _headers);
    return jsonDecode(res.body);
  }

  // ─── Leases ───
  Future<Map<String, dynamic>> getLeases({int limit = 10, String? cursor, String? status}) async {
    var url = '${AppConfig.apiBaseUrl}/leases/?limit=$limit';
    if (cursor != null) url += '&cursor=$cursor';
    if (status != null) url += '&status=$status';
    final res = await http.get(Uri.parse(url), headers: _headers);
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> createLease(Map<String, dynamic> data) async {
    final res = await http.post(Uri.parse('${AppConfig.apiBaseUrl}/leases/'), headers: _headers, body: jsonEncode(data));
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> updateLease(int id, Map<String, dynamic> data) async {
    final res = await http.put(Uri.parse('${AppConfig.apiBaseUrl}/leases/$id'), headers: _headers, body: jsonEncode(data));
    return jsonDecode(res.body);
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
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> createInvoice(Map<String, dynamic> data) async {
    final res = await http.post(Uri.parse('${AppConfig.apiBaseUrl}/invoices/'), headers: _headers, body: jsonEncode(data));
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> updateInvoice(int id, Map<String, dynamic> data) async {
    final res = await http.put(Uri.parse('${AppConfig.apiBaseUrl}/invoices/$id'), headers: _headers, body: jsonEncode(data));
    return jsonDecode(res.body);
  }

  Future<void> deleteInvoice(int id) async {
    await http.delete(Uri.parse('${AppConfig.apiBaseUrl}/invoices/$id'), headers: _headers);
  }

  // ─── Payments ───
  Future<Map<String, dynamic>> getPayments({int limit = 10, String? cursor}) async {
    final res = await http.get(Uri.parse('${AppConfig.apiBaseUrl}/finance/?limit=$limit${cursor != null ? '&cursor=$cursor' : ''}'), headers: _headers);
    return jsonDecode(res.body);
  }

  // ─── Maintenance ───
  Future<Map<String, dynamic>> getMaintenanceRequests({int limit = 10, String? cursor, String? status}) async {
    var url = '${AppConfig.apiBaseUrl}/maintenance/?limit=$limit';
    if (cursor != null) url += '&cursor=$cursor';
    if (status != null) url += '&status=$status';
    final res = await http.get(Uri.parse(url), headers: _headers);
    return jsonDecode(res.body);
  }

  // ─── Inspections ───
  Future<Map<String, dynamic>> getInspections({int limit = 10, String? cursor}) async {
    final res = await http.get(Uri.parse('${AppConfig.apiBaseUrl}/inspections/?limit=$limit${cursor != null ? '&cursor=$cursor' : ''}'), headers: _headers);
    return jsonDecode(res.body);
  }

  // ─── Notifications ───
  Future<Map<String, dynamic>> getNotifications({int limit = 10, String? cursor}) async {
    final res = await http.get(Uri.parse('${AppConfig.apiBaseUrl}/notifications/?limit=$limit${cursor != null ? '&cursor=$cursor' : ''}'), headers: _headers);
    return jsonDecode(res.body);
  }

  // ─── Documents ───
  Future<Map<String, dynamic>> getDocuments({int limit = 10, String? cursor}) async {
    final res = await http.get(Uri.parse('${AppConfig.apiBaseUrl}/documents/?limit=$limit${cursor != null ? '&cursor=$cursor' : ''}'), headers: _headers);
    return jsonDecode(res.body);
  }
}
