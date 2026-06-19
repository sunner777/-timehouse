import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class UserProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  String _nickname = '';

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get nickname => _nickname;

  final ApiService _apiService = ApiService();

  // 发送短信验证码
  Future<bool> sendSmsCode(String phone) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.sendSmsCode(phone);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // 短信验证码登录
  Future<bool> smsLogin(String phone, String code) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _apiService.smsLogin(phone, code);
      if (data['token'] != null) {
        await StorageService.saveUserInfo(
          data['userId'].toString(),
          data['token'],
          phone: data['phone'] ?? phone,
        );
        _apiService.setToken(data['token']);
        // 保存服务器返回的昵称，并恢复本地保存的（以本地为准）
        final localNick = StorageService.getNickname();
        if (localNick != null && localNick.isNotEmpty) {
          _nickname = localNick;
        } else if (data['nickname'] != null && data['nickname'].toString().isNotEmpty) {
          _nickname = data['nickname'].toString();
          await StorageService.saveNickname(_nickname);
        }
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // 登出 — 通知后端吊销 token，然后清除本地状态
  Future<void> logout() async {
    await _apiService.logout();      // 尽力通知后端（网络失败也继续）
    await StorageService.clearUserInfo();
    _apiService.clearToken();
    notifyListeners();
  }

  // 设置昵称（存本地 + 调后端接口）
  Future<void> setNickname(String name) async {
    _nickname = name;
    await StorageService.saveNickname(name);
    try { await _apiService.updateProfile(nickname: name); } catch (_) {}
    notifyListeners();
  }

  // 检查登录状态
  Future<void> checkLoginStatus() async {
    final userId = StorageService.getUserId();
    final token = StorageService.getToken();
    if (userId != null && token != null) {
      _apiService.setToken(token);
      _nickname = StorageService.getNickname() ?? '';
      _isLoading = false;
      notifyListeners();
    }
  }
}
