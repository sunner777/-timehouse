import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class UserProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  String _nickname = '';
  String? _avatar;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get nickname => _nickname;
  String? get avatar => _avatar;

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
        // 从服务器拉取最新资料（昵称/头像），本地兜底
        await _restoreProfile(data);
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

  // 登录后恢复资料：优先服务器 → 本地 → 默认空
  Future<void> _restoreProfile(Map<String, dynamic> loginData) async {
    // 先取服务器返回的
    final serverNick = (loginData['nickname'] != null && loginData['nickname'].toString().isNotEmpty)
        ? loginData['nickname'].toString()
        : null;
    final serverAvatar = (loginData['avatar'] != null && loginData['avatar'].toString().isNotEmpty)
        ? loginData['avatar'].toString()
        : null;

    // 再取本地保存的（旧设备可能只存在本地）
    final localNick = StorageService.getNickname();
    final localAvatar = StorageService.getAvatar();

    // 服务器优先，本地兜底
    if (serverNick != null) {
      _nickname = serverNick;
      await StorageService.saveNickname(_nickname);
    } else if (localNick != null && localNick.isNotEmpty) {
      _nickname = localNick;
    }

    if (serverAvatar != null) {
      _avatar = serverAvatar;
      await StorageService.saveAvatar(_avatar!);
    } else if (localAvatar != null && localAvatar.isNotEmpty) {
      _avatar = localAvatar;
    }
  }

  // 登出 — 通知后端吊销 token，然后清除本地状态
  Future<void> logout() async {
    await _apiService.logout();
    await StorageService.clearUserInfo();
    _apiService.clearToken();
    notifyListeners();
  }

  // 设置昵称（存本地 + 调后端接口，不再静默吞错误）
  Future<void> setNickname(String name) async {
    _nickname = name;
    await StorageService.saveNickname(name);
    notifyListeners(); // 先乐观更新 UI

    try {
      await _apiService.updateProfile(nickname: name);
    } catch (e) {
      // 后端失败时回滚本地昵称并提示用户
      _errorMessage = '保存昵称失败: $e';
      notifyListeners();
    }
  }

  // 检查登录状态（App 启动时）
  Future<void> checkLoginStatus() async {
    final userId = StorageService.getUserId();
    final token = StorageService.getToken();
    if (userId != null && token != null) {
      _apiService.setToken(token);
      _nickname = StorageService.getNickname() ?? '';
      _avatar = StorageService.getAvatar();
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
