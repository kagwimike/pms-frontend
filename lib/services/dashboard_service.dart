import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import 'auth_service.dart';

class DashboardService {
  final AuthService _authService = AuthService();

  Future<Map<String, dynamic>> getCaretakerDashboard() async {
    final token = _authService.accessToken;
    if (token == null) throw Exception('Not authenticated');

    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/dashboard/caretaker'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      return decoded['data'] ?? {};
    } else {
      throw Exception('Failed to load caretaker dashboard: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getVendorDashboard() async {
    final token = _authService.accessToken;
    if (token == null) throw Exception('Not authenticated');

    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/dashboard/vendor'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      return decoded['data'] ?? {};
    } else {
      throw Exception('Failed to load vendor dashboard: ${response.body}');
    }
  }
}
