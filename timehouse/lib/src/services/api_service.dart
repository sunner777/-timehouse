import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import '../models/user.dart';
import '../models/photo.dart';

// 重试拦截器
class RetryInterceptor extends Interceptor {
  final Dio dio;
  final int retryCount;
  final List<Duration> retryDelays;

  RetryInterceptor({
    required this.dio,
    required this.retryCount,
    required this.retryDelays,
  });

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.unknown) {
      // 检查是否已经重试过
      int currentRetry = err.requestOptions.extra['retry'] ?? 0;
      if (currentRetry < retryCount) {
        // 增加重试计数
        err.requestOptions.extra['retry'] = currentRetry + 1;
        
        // 等待指定时间
        await Future.delayed(retryDelays[currentRetry]);
        
        // 重新发送请求
        try {
          final response = await dio.fetch(err.requestOptions);
          return handler.resolve(response);
        } catch (e) {
          return handler.reject(err);
        }
      }
    }
    return handler.reject(err);
  }
}

// 编译时 baseUrl，通过 --dart-define=API_BASE_URL=... 注入
const String kApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:3000/api/v1',
);

class ApiService {
  final Dio _dio = Dio();
  String? _token;

  // 单例模式
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal() {
    _dio.options =
      BaseOptions(
        baseUrl: kApiBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        sendTimeout: Duration(seconds: 10),
      );

    // 添加重试拦截器
    _dio.interceptors.add(
      RetryInterceptor(
        dio: _dio,
        retryCount: 3,
        retryDelays: [
          Duration(seconds: 1),
          Duration(seconds: 2),
          Duration(seconds: 3),
        ],
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // 添加认证token
          if (_token != null) {
            options.headers['Authorization'] = 'Bearer $_token';
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          // 处理错误响应
          if (e.response != null) {
            final errorMessage = e.response?.data?['message'] ?? '请求失败';
            throw Exception(errorMessage);
          }
          return handler.next(e);
        },
      ),
    );

    // 证书绑定：允许 api.timehouse.top 的证书用于 IP 直连（绕过 ICP 备案 SNI 检测）
    (_dio.httpClientAdapter as IOHttpClientAdapter).onHttpClientCreate =
        (HttpClient client) {
      client.badCertificateCallback = (X509Certificate cert, String host, int port) {
        // 只信任签发给 api.timehouse.top 的证书
        return cert.subject.contains('api.timehouse.top');
      };
    };
  }

  // 设置token
  void setToken(String token) {
    _token = token;
  }

  // 获取token
  String? getToken() {
    return _token;
  }

  // 清除token
  void clearToken() {
    _token = null;
  }

  // 用户相关API
  Future<Map<String, dynamic>> register(String phone, String password, {String? nickname}) async {
    final response = await _dio.post('/auth/register', data: {
      'phone': phone,
      'password': password,
      'nickname': nickname,
    });
    
    final data = response.data['data'];
    if (data['token'] != null) {
      _token = data['token'];
    }
    return data;
  }

  Future<Map<String, dynamic>> login(String phone, String password) async {
    final response = await _dio.post('/auth/login', data: {
      'phone': phone,
      'password': password,
    });
    
    final data = response.data['data'];
    if (data['token'] != null) {
      _token = data['token'];
    }
    return data;
  }

  // 发送短信验证码
  Future<void> sendSmsCode(String phone) async {
    await _dio.post('/auth/send-code', data: {
      'phone': phone,
    });
  }

  // 短信验证码登录
  Future<Map<String, dynamic>> smsLogin(String phone, String code) async {
    final response = await _dio.post('/auth/sms-login', data: {
      'phone': phone,
      'code': code,
    });

    final data = response.data['data'];
    if (data['token'] != null) {
      _token = data['token'];
    }
    return data;
  }

  // 登出（通知后端加入黑名单）
  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } catch (_) {
      // 网络错误时静默失败，不清除本地状态
    }
  }

  Future<void> updatePassword(String oldPassword, String newPassword) async {
    await _dio.put('/auth/password', data: {
      'oldPassword': oldPassword,
      'newPassword': newPassword,
    });
  }

  Future<Map<String, dynamic>> getUserInfo() async {
    final response = await _dio.get('/auth/profile');
    return response.data['data'];
  }

  // 照片相关API
  Future<Map<String, dynamic>> getPhotos({int page = 1, int pageSize = 20}) async {
    final response = await _dio.get('/photos', queryParameters: {
      'page': page,
      'pageSize': pageSize,
    });
    return response.data['data'];
  }

  Future<Map<String, dynamic>> uploadPhoto(Map<String, dynamic> photoData) async {
    final response = await _dio.post('/photos/upload', data: photoData);
    return response.data['data'];
  }

  Future<Map<String, dynamic>> getPhoto(String photoId) async {
    final response = await _dio.get('/photos/$photoId');
    return response.data['data'];
  }

  Future<void> deletePhoto(String photoId) async {
    await _dio.delete('/photos/$photoId');
  }

  Future<Map<String, dynamic>> deletePhotos(List<String> photoIds) async {
    final response = await _dio.post('/photos/batch-delete', data: {
      'photoIds': photoIds,
    });
    return response.data['data'];
  }

  // TOS上传签名API
  Future<Map<String, dynamic>> getTosUploadSignature(String fileName, String contentType) async {
    final response = await _dio.post('/photos/tos-upload-signature', data: {
      'fileName': fileName,
      'contentType': contentType,
    });
    return response.data['data'];
  }

  // 检查照片哈希是否重复
  Future<Map<String, dynamic>> checkDuplicates(List<String> hashes) async {
    final response = await _dio.post('/photos/check-duplicates', data: {
      'hashes': hashes,
    });
    return response.data['data'];
  }

  // 更新用户资料（昵称/头像）
  Future<void> updateProfile({String? nickname, String? avatar}) async {
    final Map<String, dynamic> data = {};
    if (nickname != null) data['nickname'] = nickname;
    if (avatar != null) data['avatar'] = avatar;
    if (data.isNotEmpty) {
      await _dio.put('/auth/profile', data: data);
    }
  }

  // 更新照片的家庭组归属
  Future<void> updatePhotoFamily(String photoId, String? familyId) async {
    await _dio.put('/photos/$photoId/family', data: {
      'familyId': familyId,
    });
  }

  // 家庭组相关API
  Future<Map<String, dynamic>> getFamilies() async {
    final response = await _dio.get('/families');
    return response.data;
  }

  Future<Map<String, dynamic>> createFamily(String name) async {
    final response = await _dio.post('/families', data: {
      'name': name,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> getFamilyDetail(String familyId) async {
    final response = await _dio.get('/families/$familyId');
    return response.data;
  }

  Future<Map<String, dynamic>> getFamilyPhotos(String familyId, {int page = 1, int pageSize = 20}) async {
    final response = await _dio.get('/families/$familyId/photos', queryParameters: {
      'page': page,
      'pageSize': pageSize,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> joinFamily(String inviteCode) async {
    final response = await _dio.post('/families/join', data: {
      'inviteCode': inviteCode,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> generateInviteCode(String familyId) async {
    final response = await _dio.post('/families/$familyId/invite');
    return response.data;
  }

  Future<Map<String, dynamic>> addFamilyMember(String familyId, String phone, String role) async {
    final response = await _dio.post('/families/$familyId/members', data: {
      'phone': phone,
      'role': role,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> updateMemberPermission(String familyId, String userId, String role) async {
    final response = await _dio.put('/families/$familyId/members/$userId/permissions', data: {
      'role': role,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> removeFamilyMember(String familyId, String userId) async {
    final response = await _dio.delete('/families/$familyId/members/$userId');
    return response.data;
  }

  Future<Map<String, dynamic>> leaveFamily(String familyId) async {
    final response = await _dio.post('/families/$familyId/leave');
    return response.data;
  }
}
