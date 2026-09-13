import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// 网络请求响应实体
class G5ApiResponse<T> {
  final int? code;
  final T? data;
  final String? message;

  G5ApiResponse({this.code, this.data, this.message});

  bool get isSuccess => code == 0;
}

/// 网络请求管理类
class G5NetworkManager {
  static final G5NetworkManager _instance = G5NetworkManager._internal();
  late Dio _dio;

  factory G5NetworkManager() {
    return _instance;
  }

  G5NetworkManager._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: 'https://api.livespeeds.com',
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      responseType: ResponseType.json,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'x-platform': 'IOS',
        'Accept-Language': 'en-US',
        'x-version': '6.0.0'
      },
    ));

    // 添加拦截器
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        // 打印请求信息
        if (kDebugMode) {
          print('\n==================== G5Network Request ====================');
          print('Method: ${options.method}');
          print('URL: ${options.baseUrl}${options.path}');
          if (options.queryParameters.isNotEmpty) {
            print('QueryParameters: ${options.queryParameters}');
          }
          print('Headers: ${options.headers}');
          if (options.data != null) {
            print('Data: ${options.data}');
          }
          print('===========================================================\n');
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        // 打印响应信息
        if (kDebugMode) {
          print('\n==================== G5Network Response ===================');
          print('URL: ${response.requestOptions.baseUrl}${response.requestOptions.path}');
          print('StatusCode: ${response.statusCode}');
          print('Data: ${response.data}');
          print('===========================================================\n');
        }
        return handler.next(response);
      },
      onError: (DioException e, handler) {
        // 打印错误信息
        if (kDebugMode) {
          print('\n==================== G5Network Error ======================');
          print('URL: ${e.requestOptions.baseUrl}${e.requestOptions.path}');
          print('Error: ${e.message}');
          if (e.response != null) {
            print('StatusCode: ${e.response?.statusCode}');
            print('Data: ${e.response?.data}');
          }
          print('===========================================================\n');
        }
        return handler.next(e);
      },
    ));
  }

  void setAuthorizationHeader(String token) {
    _dio.options.headers['authorization'] = token;
  }

  void clearAuthorizationHeader() {
    _dio.options.headers.remove('authorization');
  }

  /// GET 请求
  Future<G5ApiResponse<dynamic>> get(String path,
      {Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);
      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  /// POST 请求
  Future<G5ApiResponse<dynamic>> post(String path, {dynamic data}) async {
    try {
      final response = await _dio.post(path, data: data);
      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  /// 处理响应
  G5ApiResponse<dynamic> _handleResponse(Response response) {
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = response.data;
      return G5ApiResponse(
        code: data['code'] as int?,
        data: data['data'],
        message: data['message'] as String?,
      );
    } else {
      return G5ApiResponse(
        code: response.statusCode,
        message: 'Network Error: ${response.statusCode}',
      );
    }
  }

  /// 处理异常
  G5ApiResponse<dynamic> _handleError(dynamic error) {
    String msg = 'Unknown Error';
    if (error is DioException) {
      msg = error.message ?? 'Dio Error';
    }
    return G5ApiResponse(code: -1, message: msg);
  }
}
