import 'package:dio/dio.dart';

import '../storage/token_storage.dart';

class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final Map<String, dynamic>? meta;
  final int statusCode;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.meta,
    required this.statusCode,
  });
}

class ApiClient {
  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      headers: {'Accept': 'application/json'},
    ),
  );

  static Future<ApiResponse<dynamic>> get(
    String url, {
    bool withAuth = true,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.get(
        url,
        queryParameters: queryParameters,
        options: await _options(withAuth),
      );
      return _parseResponse(response);
    } on DioException catch (error) {
      return _errorResponse(error);
    }
  }

  static Future<ApiResponse<dynamic>> post(
    String url,
    Map<String, dynamic> body, {
    bool withAuth = true,
  }) async {
    try {
      final response = await _dio.post(
        url,
        data: body,
        options: await _options(withAuth),
      );
      return _parseResponse(response);
    } on DioException catch (error) {
      return _errorResponse(error);
    }
  }

  static Future<ApiResponse<dynamic>> put(
    String url,
    Map<String, dynamic> body, {
    bool withAuth = true,
  }) async {
    try {
      final response = await _dio.put(
        url,
        data: body,
        options: await _options(withAuth),
      );
      return _parseResponse(response);
    } on DioException catch (error) {
      return _errorResponse(error);
    }
  }

  static Future<ApiResponse<dynamic>> delete(
    String url, {
    bool withAuth = true,
  }) async {
    try {
      final response = await _dio.delete(
        url,
        options: await _options(withAuth),
      );
      return _parseResponse(response);
    } on DioException catch (error) {
      return _errorResponse(error);
    }
  }

  static Future<Options> _options(bool withAuth) async {
    final token = withAuth ? await TokenStorage.getAccessToken() : null;
    return Options(
      headers: {
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
    );
  }

  static ApiResponse<dynamic> _parseResponse(Response<dynamic> response) {
    final body = response.data is Map<String, dynamic>
        ? response.data as Map<String, dynamic>
        : <String, dynamic>{};
    return ApiResponse(
      success: body['success'] == true,
      message: body['message']?.toString() ?? 'Response received',
      data: body['data'],
      meta: body['meta'] is Map
          ? Map<String, dynamic>.from(body['meta'] as Map)
          : null,
      statusCode: response.statusCode ?? 0,
    );
  }

  static ApiResponse<dynamic> _errorResponse(DioException error) {
    final body = error.response?.data;
    final map = body is Map ? Map<String, dynamic>.from(body) : null;
    return ApiResponse(
      success: false,
      message:
          map?['message']?.toString() ?? 'Network error. Please try again.',
      data: map?['error'],
      statusCode: error.response?.statusCode ?? 0,
    );
  }
}
