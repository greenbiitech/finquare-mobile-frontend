import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_config.dart';

/// API Client Provider
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

/// Secure Storage Provider
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

/// API Exception for handling errors
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  ApiException({
    required this.message,
    this.statusCode,
    this.data,
  });

  @override
  String toString() => message;
}

/// API Client using Dio
class ApiClient {
  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Add auth token if available
          final token = await _storage.read(key: 'access_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          if (kDebugMode) {
            print('API Request: ${options.method} ${options.path}');
            print('Data: ${options.data}');
          }

          return handler.next(options);
        },
        onResponse: (response, handler) {
          if (kDebugMode) {
            print('API Response: ${response.statusCode}');
            print('Data: ${response.data}');
          }
          return handler.next(response);
        },
        onError: (error, handler) {
          if (kDebugMode) {
            print('API Error: ${error.message}');
            print('Response: ${error.response?.data}');
          }
          return handler.next(error);
        },
      ),
    );
  }

  /// GET request
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// POST request
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// PUT request
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// DELETE request
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// PATCH request
  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.patch<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Handle Dio errors
  ApiException _handleError(DioException error) {
    String message;
    int? statusCode = error.response?.statusCode;
    dynamic data = error.response?.data;

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        message = 'Connection timeout. Please check your internet connection.';
        break;
      case DioExceptionType.connectionError:
        message = 'Unable to connect to server. Please check your internet connection.';
        break;
      case DioExceptionType.badResponse:
        // Try to extract error message from response
        if (data is Map<String, dynamic>) {
          final msg = data['message'];
          if (msg is List) {
            // NestJS validation errors return an array
            message = msg.join(', ');
          } else if (msg is String) {
            message = msg;
          } else {
            message = 'An error occurred';
          }
        } else {
          message = _getStatusMessage(statusCode);
        }
        break;
      case DioExceptionType.cancel:
        message = 'Request was cancelled';
        break;
      default:
        message = 'An unexpected error occurred';
    }

    return ApiException(
      message: message,
      statusCode: statusCode,
      data: data,
    );
  }

  String _getStatusMessage(int? statusCode) {
    switch (statusCode) {
      case 400:
        return 'Bad request';
      case 401:
        return 'Unauthorized';
      case 403:
        return 'Forbidden';
      case 404:
        return 'Not found';
      case 409:
        return 'Conflict';
      case 422:
        return 'Validation error';
      case 500:
        return 'Internal server error';
      default:
        return 'An error occurred';
    }
  }

  /// Save auth token
  Future<void> saveToken(String token) async {
    await _storage.write(key: 'access_token', value: token);
  }

  /// Clear auth token
  Future<void> clearToken() async {
    await _storage.delete(key: 'access_token');
  }

  /// Get saved token
  Future<String?> getToken() async {
    return await _storage.read(key: 'access_token');
  }
}
