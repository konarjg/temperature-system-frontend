import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import '../config/api_config.dart';

class ApiService {
  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  late final PersistCookieJar _cookieJar;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl, 
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      contentType: 'application/json',
    ));
  }

  Future<void> init() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    _cookieJar = PersistCookieJar(storage: FileStorage("${appDocDir.path}/.cookies/"));
    
    _dio.interceptors.add(CookieManager(_cookieJar));
    
    // Auth Interceptor
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'jwt_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException error, handler) async {
        // Handle 401 - Refresh Token Flow
        if (error.response?.statusCode == 401) {
          
          // Load cookies to check if we have a refresh token
          final cookies = await _cookieJar.loadForRequest(Uri.parse(ApiConfig.baseUrl));
          
          if (cookies.isNotEmpty) {
            // Prevent infinite loops
            if (error.requestOptions.path.contains('auth/refresh')) {
               await _storage.delete(key: 'jwt_token');
               return handler.next(error);
            }

            try {
              // Call refresh (HttpOnly cookie sent automatically by CookieManager)
              final refreshResponse = await _dio.put('/api/auth/refresh');
              
              if (refreshResponse.statusCode == 200) {
                final newData = refreshResponse.data;
                final newToken = newData['accessToken'];
                
                await _storage.write(key: 'jwt_token', value: newToken);
                
                // Retry original request with new token
                final opts = error.requestOptions;
                opts.headers['Authorization'] = 'Bearer $newToken';
                
                final clonedRequest = await _dio.request(
                  opts.path,
                  options: Options(
                    method: opts.method,
                    headers: opts.headers,
                  ),
                  data: opts.data,
                  queryParameters: opts.queryParameters,
                );
                
                return handler.resolve(clonedRequest);
              }
            } catch (e) {
              // Refresh failed
              await _storage.delete(key: 'jwt_token');
            }
          }
        }
        return handler.next(error);
      },
    ));
  }

  // Generic Methods
  Future<dynamic> get(String path, {Map<String, dynamic>? queryParams}) async {
    final response = await _dio.get(path, queryParameters: queryParams);
    return response.data;
  }

  Future<dynamic> post(String path, dynamic data) async {
    final response = await _dio.post(path, data: data);
    return response.data;
  }

  Future<dynamic> put(String path, dynamic data) async {
    final response = await _dio.put(path, data: data);
    return response.data;
  }

  Future<dynamic> delete(String path) async {
    final response = await _dio.delete(path);
    return response.data;
  }

  Future<void> clearTokens() async {
    await _storage.delete(key: 'jwt_token');
    await _cookieJar.deleteAll();
  }
}