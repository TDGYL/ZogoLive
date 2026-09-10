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
      baseUrl: 'https://api.g5-live.com',
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      responseType: ResponseType.json,
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    // 添加拦截器
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        // 打印请求信息
        debugPrint(
            '\n==================== G5Network Request ====================');
        debugPrint('Method: ${options.method}');
        debugPrint('URL: ${options.baseUrl}${options.path}');
        if (options.queryParameters.isNotEmpty) {
          debugPrint('QueryParameters: ${options.queryParameters}');
        }
        debugPrint('Headers: ${options.headers}');
        if (options.data != null) {
          debugPrint('Data: ${options.data}');
        }
        debugPrint(
            '===========================================================\n');

        return handler.next(options);
      },
      onResponse: (response, handler) {
        // 打印响应信息
        debugPrint(
            '\n==================== G5Network Response ===================');
        debugPrint(
            'URL: ${response.requestOptions.baseUrl}${response.requestOptions.path}');
        debugPrint('StatusCode: ${response.statusCode}');
        debugPrint('Data: ${response.data}');
        debugPrint(
            '===========================================================\n');

        return handler.next(response);
      },
      onError: (DioException e, handler) {
        // 打印错误信息
        debugPrint(
            '\n==================== G5Network Error ======================');
        debugPrint('URL: ${e.requestOptions.baseUrl}${e.requestOptions.path}');
        debugPrint('Error: ${e.message}');
        if (e.response != null) {
          debugPrint('StatusCode: ${e.response?.statusCode}');
          debugPrint('Data: ${e.response?.data}');
        }
        debugPrint(
            '===========================================================\n');

        return handler.next(e);
      },
    ));
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
