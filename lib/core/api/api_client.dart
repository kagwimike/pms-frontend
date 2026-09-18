import 'dart:convert';
import 'package:http/http.dart' as http;
import '../storage/token_storage.dart';

class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final int statusCode;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    required this.statusCode,
  });
}

class ApiClient {
  static Future<Map<String, String>> _getHeaders({bool withAuth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (withAuth) {
      final token = await TokenStorage.getAccessToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  static Future<ApiResponse<dynamic>> get(String url, {bool withAuth = true}) async {
    try {
      final headers = await _getHeaders(withAuth: withAuth);
      final response = await http.get(Uri.parse(url), headers: headers);
      return _parseResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Network error: $e',
        statusCode: 500,
      );
    }
  }

  static Future<ApiResponse<dynamic>> post(String url, Map<String, dynamic> body, {bool withAuth = true}) async {
    try {
      final headers = await _getHeaders(withAuth: withAuth);
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: json.encode(body),
      );
      return _parseResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Network error: $e',
        statusCode: 500,
      );
    }
  }

  static Future<ApiResponse<dynamic>> put(String url, Map<String, dynamic> body, {bool withAuth = true}) async {
    try {
      final headers = await _getHeaders(withAuth: withAuth);
      final response = await http.put(
        Uri.parse(url),
        headers: headers,
        body: json.encode(body),
      );
      return _parseResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Network error: $e',
        statusCode: 500,
      );
    }
  }

  static Future<ApiResponse<dynamic>> delete(String url, {bool withAuth = true}) async {
    try {
      final headers = await _getHeaders(withAuth: withAuth);
      final response = await http.delete(Uri.parse(url), headers: headers);
      return _parseResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Network error: $e',
        statusCode: 500,
      );
    }
  }

  static ApiResponse<dynamic> _parseResponse(http.Response response) {
    try {
      final decoded = json.decode(response.body);
      final isSuccess = decoded['success'] ?? (response.statusCode >= 200 && response.statusCode < 300);
      final message = decoded['message'] ?? 'Response received';
      final data = decoded['data'];

      return ApiResponse(
        success: isSuccess,
        message: message,
        data: data,
        statusCode: response.statusCode,
      );
    } catch (_) {
      return ApiResponse(
        success: response.statusCode >= 200 && response.statusCode < 300,
        message: response.reasonPhrase ?? 'Unknown response',
        data: response.body,
        statusCode: response.statusCode,
      );
    }
  }
}
