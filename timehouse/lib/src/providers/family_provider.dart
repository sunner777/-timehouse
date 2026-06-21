import 'package:flutter/foundation.dart';
import '../models/family.dart';
import '../models/family_member.dart';
import '../services/api_service.dart';

class FamilyProvider extends ChangeNotifier {
  final ApiService _apiService;
  List<Family> _families = [];
  Family? _currentFamily;
  List<FamilyMember> _familyMembers = [];
  bool _isLoading = false;
  String? _errorMessage;

  FamilyProvider(this._apiService);

  List<Family> get families => _families;
  Family? get currentFamily => _currentFamily;
  List<FamilyMember> get familyMembers => _familyMembers;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  Future<void> getFamilies() async {
    _setLoading(true);
    _setError(null);
    try {
      final response = await _apiService.getFamilies();
      if (response['code'] == 0) {
        // 逐个解析，单个异常不阻塞其余数据
        final familiesList = <Family>[];
        for (final item in (response['data']['families'] as List)) {
          try {
            familiesList.add(Family.fromJson(item));
          } catch (_) {
            // 跳过解析失败的条目
          }
        }
        _families = familiesList;
      } else {
        _setError(response['message'] ?? '获取家庭组列表失败');
      }
    } catch (error) {
      _setError('获取家庭组列表失败: $error');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> createFamily(String name) async {
    _setLoading(true);
    _setError(null);
    try {
      final response = await _apiService.createFamily(name);
      if (response['code'] == 0) {
        await getFamilies();
      } else {
        _setError(response['message'] ?? '创建家庭组失败');
      }
    } catch (error) {
      _setError('创建家庭组失败: $error');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> getFamilyDetail(String familyId) async {
    _setLoading(true);
    _setError(null);
    try {
      final response = await _apiService.getFamilyDetail(familyId);
      if (response['code'] == 0) {
        _familyMembers = (response['data']['members'] as List)
            .map((item) => FamilyMember.fromJson(item))
            .toList();
      } else {
        _setError(response['message'] ?? '获取家庭组详情失败');
      }
    } catch (error) {
      _setError('获取家庭组详情失败: $error');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> joinFamily(String inviteCode) async {
    _setLoading(true);
    _setError(null);
    try {
      final response = await _apiService.joinFamily(inviteCode);
      if (response['code'] == 0) {
        await getFamilies();
      } else {
        _setError(response['message'] ?? '加入家庭组失败');
      }
    } catch (error) {
      _setError('加入家庭组失败: $error');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> generateInviteCode(String familyId) async {
    _setLoading(true);
    _setError(null);
    try {
      final response = await _apiService.generateInviteCode(familyId);
      if (response['code'] == 0) {
        return response['data']['inviteCode'];
      } else {
        _setError(response['message'] ?? '生成邀请码失败');
      }
    } catch (error) {
      _setError('生成邀请码失败: $error');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addMember(String familyId, String phone, String role) async {
    _setLoading(true);
    _setError(null);
    try {
      final response = await _apiService.addFamilyMember(familyId, phone, role);
      if (response['code'] == 0) {
        await getFamilyDetail(familyId);
      } else {
        _setError(response['message'] ?? '添加成员失败');
      }
    } catch (error) {
      _setError('添加成员失败: $error');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateMemberPermission(String familyId, String userId, String role) async {
    _setLoading(true);
    _setError(null);
    try {
      final response = await _apiService.updateMemberPermission(familyId, userId, role);
      if (response['code'] == 0) {
        await getFamilyDetail(familyId);
      } else {
        _setError(response['message'] ?? '更新权限失败');
      }
    } catch (error) {
      _setError('更新权限失败: $error');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> removeMember(String familyId, String userId) async {
    _setLoading(true);
    _setError(null);
    try {
      final response = await _apiService.removeFamilyMember(familyId, userId);
      if (response['code'] == 0) {
        await getFamilyDetail(familyId);
      } else {
        _setError(response['message'] ?? '移除成员失败');
      }
    } catch (error) {
      _setError('移除成员失败: $error');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> leaveFamily(String familyId) async {
    _setLoading(true);
    _setError(null);
    try {
      final response = await _apiService.leaveFamily(familyId);
      if (response['code'] == 0) {
        await getFamilies();
      } else {
        _setError(response['message'] ?? '退出家庭组失败');
      }
    } catch (error) {
      _setError('退出家庭组失败: $error');
    } finally {
      _setLoading(false);
    }
  }

  void clearError() {
    _setError(null);
  }
}
