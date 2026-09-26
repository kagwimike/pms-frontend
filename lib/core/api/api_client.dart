
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import '../storage/token_storage.dart';

/// Generic API response wrapper.
///
/// T represents the type of data returned by the backend.
/// Example:

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
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );

  /// Set the global API base URL.
  static void init({
    required String baseUrl,
  }) {
    _dio.options.baseUrl = baseUrl;
  }

  // ---------------------------------------------------------------------------
  // GET
  // ---------------------------------------------------------------------------

  static Future<ApiResponse<T>> get<T>(
    String url, {
    bool withAuth = true,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get(
        url,
        queryParameters: queryParameters,
        options: await _options(
          withAuth,
          headers: headers,
        ),
        cancelToken: cancelToken,
      );

      return _parseResponse<T>(response);
    } on DioException catch (error) {
      return _errorResponse<T>(error);
    }
  }

  // ---------------------------------------------------------------------------
  // POST
  // ---------------------------------------------------------------------------

  static Future<ApiResponse<T>> post<T>(
    String url,
    dynamic body, {
    bool withAuth = true,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.post(
        url,
        data: body,
        queryParameters: queryParameters,
        options: await _options(
          withAuth,
          headers: headers,
        ),
        cancelToken: cancelToken,
      );

      return _parseResponse<T>(response);
    } on DioException catch (error) {
      return _errorResponse<T>(error);
    }
  }

  // ---------------------------------------------------------------------------
  // PUT
  // ---------------------------------------------------------------------------

  static Future<ApiResponse<T>> put<T>(
    String url,
    dynamic body, {
    bool withAuth = true,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.put(
        url,
        data: body,
        queryParameters: queryParameters,
        options: await _options(
          withAuth,
          headers: headers,
        ),
        cancelToken: cancelToken,
      );

      return _parseResponse<T>(response);
    } on DioException catch (error) {
      return _errorResponse<T>(error);
    }
  }

  // ---------------------------------------------------------------------------
  // PATCH
  // ---------------------------------------------------------------------------

  static Future<ApiResponse<T>> patch<T>(
    String url,
    dynamic body, {
    bool withAuth = true,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.patch(
        url,
        data: body,
        queryParameters: queryParameters,
        options: await _options(
          withAuth,
          headers: headers,
        ),
        cancelToken: cancelToken,
      );

      return _parseResponse<T>(response);
    } on DioException catch (error) {
      return _errorResponse<T>(error);
    }
  }

  // ---------------------------------------------------------------------------
  // DELETE
  // ---------------------------------------------------------------------------

  static Future<ApiResponse<T>> delete<T>(
    String url, {
    bool withAuth = true,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.delete(
        url,
        queryParameters: queryParameters,
        options: await _options(
          withAuth,
          headers: headers,
        ),
        cancelToken: cancelToken,
      );

      return _parseResponse<T>(response);
    } on DioException catch (error) {
      return _errorResponse<T>(error);
    }
  }

  // ---------------------------------------------------------------------------
  // MULTIPART POST
  // ---------------------------------------------------------------------------

  static Future<ApiResponse<T>> postMultipart<T>(
    String url, {
    required Map<String, dynamic> fields,
    List<XFile> images = const [],
    String fileKey = 'images',
    bool withAuth = true,
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
  }) async {
    try {
      final List<MultipartFile> files = [];

      for (final image in images) {
        if (kIsWeb) {
          final bytes = await image.readAsBytes();

          files.add(
            MultipartFile.fromBytes(
              bytes,
              filename: image.name.isNotEmpty
                  ? image.name
                  : 'upload.jpg',
            ),
          );
        } else {
          files.add(
            await MultipartFile.fromFile(
              image.path,
              filename: image.name.isNotEmpty
                  ? image.name
                  : 'upload.jpg',
            ),
          );
        }
      }

      final Map<String, dynamic> sanitizedFields = {};

      fields.forEach((key, value) {
        if (value != null) {
          sanitizedFields[key] = value.toString();
        }
      });

      final form = FormData.fromMap({
        ...sanitizedFields,
        if (files.isNotEmpty)
          fileKey: files.length == 1
              ? files.first
              : files,
      });

      final response = await _dio.post(
        url,
        data: form,
        options: await _options(
          withAuth,
          headers: headers,
        ),
        cancelToken: cancelToken,
      );

      return _parseResponse<T>(response);
    } on DioException catch (error) {
      return _errorResponse<T>(error);
    }
  }

  // ---------------------------------------------------------------------------
  // OPTIONS
  // ---------------------------------------------------------------------------

  static Future<Options> _options(
    bool withAuth, {
    Map<String, dynamic>? headers,
  }) async {
    final token = withAuth
        ? await TokenStorage.getAccessToken()
        : null;

    return Options(
      headers: {
        if (token != null && token.isNotEmpty)
          'Authorization': 'Bearer $token',
        ...?headers,
      },
    );
  }

  // ---------------------------------------------------------------------------
  // RESPONSE PARSER
  // ---------------------------------------------------------------------------

  static ApiResponse<T> _parseResponse<T>(
    Response response,
  ) {
    final Map<String, dynamic> body;

    if (response.data is Map) {
      body = Map<String, dynamic>.from(
        response.data as Map,
      );
    } else {
      body = {};
    }

    final statusCode = response.statusCode ?? 0;

    final isHttpSuccess =
        statusCode >= 200 && statusCode < 300;

    T? parsedData;

    if (body.containsKey('data')) {
      final data = body['data'];

      if (data is T) {
        parsedData = data;
      }
    } else if (response.data is T) {
      parsedData = response.data as T;
    }

    Map<String, dynamic>? meta;

    if (body['meta'] is Map) {
      meta = Map<String, dynamic>.from(
        body['meta'] as Map,
      );
    }

    return ApiResponse<T>(
      success: body.containsKey('success')
          ? body['success'] == true
          : isHttpSuccess,
      message: body['message']?.toString() ??
          'Response received successfully',
      data: parsedData,
      meta: meta,
      statusCode: statusCode,
    );
  }

  // ---------------------------------------------------------------------------
  // ERROR RESPONSE
  // ---------------------------------------------------------------------------

  static ApiResponse<T> _errorResponse<T>(
    DioException error,
  ) {
    final body = error.response?.data;

    Map<String, dynamic>? map;

    if (body is Map) {
      map = Map<String, dynamic>.from(body);
    }

    String defaultMessage;

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        defaultMessage =
            'Connection timed out. Please try again.';
        break;

      case DioExceptionType.connectionError:
        defaultMessage =
            'No internet connection. Please check your network.';
        break;

      case DioExceptionType.cancel:
        defaultMessage =
            'Request was cancelled.';
        break;

      case DioExceptionType.badResponse:
        defaultMessage =
            _getHttpErrorMessage(
              error.response?.statusCode,
            );
        break;

      default:
        defaultMessage =
            'Network error. Please try again.';
    }

    T? errorData;

    final rawError =
        map?['error'] ?? map?['errors'];

    if (rawError is T) {
      errorData = rawError;
    }

    return ApiResponse<T>(
      success: false,
      message:
          map?['message']?.toString() ??
          defaultMessage,
      data: errorData,
      statusCode:
          error.response?.statusCode ?? 0,
    );
  }

  // ---------------------------------------------------------------------------
  // HTTP ERROR MESSAGES
  // ---------------------------------------------------------------------------

  static String _getHttpErrorMessage(
    int? statusCode,
  ) {
    switch (statusCode) {
      case 400:
        return 'Bad request. Please check your input.';

      case 401:
        return 'Unauthorized. Please log in again.';

      case 403:
        return 'Access denied. You do not have permission.';

      case 404:
        return 'Requested resource not found.';

      case 500:
        return 'Internal server error. Please try again later.';

      default:
        return 'Something went wrong. Please try again.';
    }
  }
}
