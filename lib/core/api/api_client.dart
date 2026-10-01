import 'package:dio/dio.dart';
import '../auth/auth_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class ApiResponse<T> {
  final bool success;
  final String? message;
  final T? data;
  final Map<String, dynamic>? meta;

  ApiResponse({
    required this.success,
    this.message,
    this.data,
    this.meta,
  });

  factory ApiResponse.fromDioResponse(Response response) {
    final responseData = response.data;
    if (responseData is Map<String, dynamic>) {
      return ApiResponse<T>(
        success: responseData['success'] ?? true,
        message: responseData['message'],
        data: responseData['data'] as T?,
        meta: responseData['meta'] as Map<String, dynamic>?,
      );
    }
    return ApiResponse<T>(
      success: true,
      data: responseData as T?,
    );
  }

  factory ApiResponse.error(String message) {
    return ApiResponse<T>(
      success: false,
      message: message,
    );
  }
}

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  
  late Dio dio;

  ApiClient._internal() {
    dio = Dio(BaseOptions(
      baseUrl: 'http://127.0.0.1:3005/api/',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await AuthStorage.getAccessToken();
        if (token != null && options.headers['Authorization'] == null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) async {
        if (e.response?.statusCode == 401) {
          await AuthStorage.clearTokens();
          debugPrint('Unauthorized access. Tokens cleared.');
        }
        return handler.next(e);
      },
    ));
  }

  static String _getErrorMessage(dynamic e) {
    if (e is DioException) {
      if (e.response?.data is Map) {
        return e.response?.data['message'] ?? e.message ?? 'Unknown error';
      }
      return e.message ?? 'Network error';
    }
    return e.toString();
  }

  static Future<ApiResponse<dynamic>> get(String path, {Map<String, dynamic>? queryParameters, bool withAuth = true}) async {
    try {
      final options = withAuth ? Options() : Options(headers: {'Authorization': ''});
      final response = await ApiClient().dio.get(path, queryParameters: queryParameters, options: options);
      return ApiResponse.fromDioResponse(response);
    } catch (e) {
      return ApiResponse.error(_getErrorMessage(e));
    }
  }

  static Future<ApiResponse<dynamic>> post(String path, dynamic data, {bool withAuth = true}) async {
    try {
      final options = withAuth ? Options() : Options(headers: {'Authorization': ''});
      final response = await ApiClient().dio.post(path, data: data, options: options);
      return ApiResponse.fromDioResponse(response);
    } catch (e) {
      return ApiResponse.error(_getErrorMessage(e));
    }
  }

  static Future<ApiResponse<dynamic>> put(String path, dynamic data, {bool withAuth = true}) async {
    try {
      final options = withAuth ? Options() : Options(headers: {'Authorization': ''});
      final response = await ApiClient().dio.put(path, data: data, options: options);
      return ApiResponse.fromDioResponse(response);
    } catch (e) {
      return ApiResponse.error(_getErrorMessage(e));
    }
  }

  static Future<ApiResponse<dynamic>> delete(String path, {bool withAuth = true}) async {
    try {
      final options = withAuth ? Options() : Options(headers: {'Authorization': ''});
      final response = await ApiClient().dio.delete(path, options: options);
      return ApiResponse.fromDioResponse(response);
    } catch (e) {
      return ApiResponse.error(_getErrorMessage(e));
    }
  }

  static Future<ApiResponse<dynamic>> postMultipart(String path, {required Map<String, dynamic> fields, List<XFile> images = const []}) async {
    try {
      final formData = FormData.fromMap(fields);
      for (var i = 0; i < images.length; i++) {
        formData.files.add(MapEntry(
          'image$i', // Defaulting key to image0, image1... Modify as needed
          await MultipartFile.fromFile(images[i].path, filename: images[i].name),
        ));
      }
      final response = await ApiClient().dio.post(path, data: formData);
      return ApiResponse.fromDioResponse(response);
    } catch (e) {
      return ApiResponse.error(_getErrorMessage(e));
    }
  }
}
