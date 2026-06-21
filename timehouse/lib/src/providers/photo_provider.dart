import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/photo.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

// 根据文件扩展名返回 MIME 类型
String _getMimeType(String fileName) {
  final ext = fileName.split('.').last.toLowerCase();
  switch (ext) {
    case 'jpg':
    case 'jpeg':
      return 'image/jpeg';
    case 'png':
      return 'image/png';
    case 'gif':
      return 'image/gif';
    case 'webp':
      return 'image/webp';
    case 'heic':
      return 'image/heic';
    case 'heif':
      return 'image/heif';
    default:
      return 'image/jpeg'; // 安全兜底
  }
}

class PhotoProvider extends ChangeNotifier {
  List<Photo> _photos = [];
  bool _isLoading = false;
  bool _isLoadingMyPhotos = false; // 独立于家人共享加载
  String? _errorMessage;
  int _lastUploadSkippedCount = 0;
  final Map<String, List<Photo>> _familyPhotosCache = {};
  final Map<String, bool> _familyPhotosLoading = {};

  List<Photo> get photos => _photos;
  bool get isLoading => _isLoading;
  bool get isLoadingMyPhotos => _isLoadingMyPhotos;
  String? get errorMessage => _errorMessage;
  int get lastUploadSkippedCount => _lastUploadSkippedCount;

  final ApiService _apiService = ApiService();
  ApiService getApiService() => _apiService;

  // 获取照片列表（我的照片）
  Future<void> getPhotos() async {
    _isLoadingMyPhotos = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 先从本地数据库获取，立即展示（不等待网络）
      final localPhotos = await StorageService.getPhotos();
      if (localPhotos.isNotEmpty) {
        _photos = localPhotos;
        _isLoadingMyPhotos = false;
        notifyListeners();
      }

      // 再从服务器获取最新数据
      final data = await _apiService.getPhotos();
      final serverPhotos = (data['photos'] as List).map((item) => Photo(
        id: item['id'].toString(),
        userId: item['userId'].toString(),
        url: item['url'],
        thumbnailUrl: item['thumbnailUrl'],
        fileName: item['fileName'],
        size: item['size'],
        contentType: item['contentType'],
        hash: item['hash'],
        takenAt: DateTime.parse(item['takenAt']),
        uploadedAt: DateTime.parse(item['createdAt']),
        location: item['location'],
        tags: List<String>.from(item['tags']),
      )).toList();

      _photos = serverPhotos;
      await StorageService.savePhotos(serverPhotos);

      _isLoadingMyPhotos = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoadingMyPhotos = false;
      notifyListeners();
    }
  }

  // 上传照片（从文件路径），返回照片ID或null（重复时返回null）
  Future<String?> uploadPhoto(String filePath, {String? familyId}) async {
    _isLoading = true;
    _errorMessage = null;
    _lastUploadSkippedCount = 0;
    notifyListeners();

    try {
      final fileName = filePath.split('/').last;
      final mimeType = _getMimeType(fileName);

      // 1. 读取文件并计算 SHA-256 哈希
      final file = File(filePath);
      final fileBytes = await file.readAsBytes();
      final hash = sha256.convert(fileBytes).toString();

      // 2. 检查本地是否已存在
      final isLocalDup = await StorageService.checkHashLocally(hash);
      if (isLocalDup) {
        _isLoading = false;
        _lastUploadSkippedCount = 1;
        notifyListeners();
        return null;
      }

      // 3. 检查服务器是否已存在
      try {
        final dupResult = await _apiService.checkDuplicates([hash]);
        final duplicates = dupResult['duplicates'] as List<dynamic>? ?? [];
        if (duplicates.contains(hash)) {
          _isLoading = false;
          _lastUploadSkippedCount = 1;
          notifyListeners();
          return null;
        }
      } catch (_) {
        // 服务器查重失败不阻塞上传，继续流程
      }

      // 4. 不重复，继续上传流程
      final signatureData = await _apiService.getTosUploadSignature(fileName, mimeType);
      final uploadUrl = signatureData['uploadUrl'];
      final objectKey = signatureData['objectKey'];

      final response = await http.put(
        Uri.parse(uploadUrl),
        headers: { 'Content-Type': mimeType },
        body: fileBytes,
      );

      if (response.statusCode != 200) {
        throw Exception('上传到TOS失败');
      }

      final tosUrl = 'https://timehouse-photos-cn-shanghai.tos-cn-shanghai.volces.com/$objectKey';

      final photoData = {
        'url': tosUrl.replaceAll('`', '').trim(),
        'thumbnailUrl': tosUrl.replaceAll('`', '').trim(),
        'fileName': fileName.replaceAll('`', '').trim(),
        'size': fileBytes.length,
        'contentType': mimeType,
        'hash': hash,
        'takenAt': DateTime.now().toIso8601String(),
        'location': '未知',
        'tags': [],
        'familyId': familyId
      };

      final data = await _apiService.uploadPhoto(photoData);
      final photoId = data['id'].toString();

      await getPhotos();
      _isLoading = false;
      notifyListeners();
      return photoId;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // 上传照片（从照片数据）
  Future<bool> uploadPhotoFromData(Map<String, dynamic> photoData) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _apiService.uploadPhoto(photoData);
      final photo = Photo(
        id: data['id'].toString(),
        userId: data['userId'].toString(),
        url: data['url'],
        thumbnailUrl: data['thumbnailUrl'],
        fileName: data['fileName'],
        size: data['size'],
        contentType: data['contentType'],
        hash: data['hash'],
        takenAt: DateTime.parse(data['takenAt']),
        uploadedAt: DateTime.now(),
        location: data['location'],
        tags: List<String>.from(data['tags']),
      );

      // 重新获取照片列表，确保所有照片都有带签名的下载URL
      await getPhotos();
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

  // 批量上传照片（从文件路径列表），带批量哈希去重
  Future<bool> uploadPhotos(List<String> filePaths, {String? familyId}) async {
    _isLoading = true;
    _errorMessage = null;
    _lastUploadSkippedCount = 0;
    notifyListeners();

    try {
      // 阶段 A：读取所有文件，计算所有哈希
      final List<Map<String, dynamic>> fileInfos = [];
      for (final filePath in filePaths) {
        final fileName = filePath.split('/').last;
        final mimeType = _getMimeType(fileName);
        final file = File(filePath);
        final fileBytes = await file.readAsBytes();
        final hash = sha256.convert(fileBytes).toString();
        fileInfos.add({
          'filePath': filePath,
          'fileName': fileName,
          'mimeType': mimeType,
          'fileBytes': fileBytes,
          'hash': hash,
        });
      }

      final allHashes = fileInfos.map((f) => f['hash'] as String).toList();

      // 阶段 B：本地查重
      final locallyDup = <String>{};
      for (final hash in allHashes) {
        if (await StorageService.checkHashLocally(hash)) {
          locallyDup.add(hash);
        }
      }

      // 阶段 C：服务器批量查重
      final nonLocalHashes = allHashes.where((h) => !locallyDup.contains(h)).toList();
      Set<String> serverDups = {};
      if (nonLocalHashes.isNotEmpty) {
        try {
          final dupResult = await _apiService.checkDuplicates(nonLocalHashes);
          final duplicates = (dupResult['duplicates'] as List<dynamic>?)
              ?.map((d) => d.toString())
              .toSet() ?? {};
          serverDups = duplicates;
        } catch (_) {
          // 服务器查重失败不阻塞上传
        }
      }

      final allDups = {...locallyDup, ...serverDups};
      final toUpload = fileInfos.where((f) => !allDups.contains(f['hash'])).toList();
      _lastUploadSkippedCount = allDups.length;

      // 阶段 D：上传非重复文件
      for (final info in toUpload) {
        final fileBytes = info['fileBytes'] as List<int>;
        final fileName = info['fileName'] as String;
        final mimeType = info['mimeType'] as String;
        final hash = info['hash'] as String;

        final signatureData = await _apiService.getTosUploadSignature(fileName, mimeType);
        final uploadUrl = signatureData['uploadUrl'];
        final objectKey = signatureData['objectKey'];

        final response = await http.put(
          Uri.parse(uploadUrl),
          headers: { 'Content-Type': mimeType },
          body: fileBytes,
        );

        if (response.statusCode != 200) {
          throw Exception('上传到TOS失败');
        }

        final tosUrl = 'https://timehouse-photos-cn-shanghai.tos-cn-shanghai.volces.com/$objectKey';

        final photoData = {
          'url': tosUrl.replaceAll('`', '').trim(),
          'thumbnailUrl': tosUrl.replaceAll('`', '').trim(),
          'fileName': fileName.replaceAll('`', '').trim(),
          'size': fileBytes.length,
          'contentType': mimeType,
          'hash': hash,
          'takenAt': DateTime.now().toIso8601String(),
          'location': '未知',
          'tags': [],
          'familyId': familyId
        };

        await _apiService.uploadPhoto(photoData);
      }

      await getPhotos();
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

  // 批量上传照片（从照片数据列表）
  Future<bool> uploadPhotosFromData(List<Map<String, dynamic>> photoDataList) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      for (final photoData in photoDataList) {
        final data = await _apiService.uploadPhoto(photoData);
        final photo = Photo(
          id: data['id'].toString(),
          userId: data['userId'].toString(),
          url: data['url'],
          thumbnailUrl: data['thumbnailUrl'],
          fileName: data['fileName'],
          size: data['size'],
          contentType: data['contentType'],
          hash: data['hash'],
          takenAt: DateTime.parse(data['takenAt']),
          uploadedAt: DateTime.now(),
          location: data['location'],
          tags: List<String>.from(data['tags']),
        );
        _photos.add(photo);
      }
      // 重新获取照片列表，确保所有照片都有带签名的下载URL
      await getPhotos();
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

  // 获取单张照片
  Future<Photo?> getPhoto(String photoId) async {
    try {
      final data = await _apiService.getPhoto(photoId);
      final item = data['photo'] ?? data;
      return Photo(
        id: item['id'].toString(),
        userId: item['userId'].toString(),
        url: item['url'],
        thumbnailUrl: item['thumbnailUrl'],
        fileName: item['fileName'],
        size: item['size'],
        contentType: item['contentType'],
        hash: item['hash'],
        takenAt: DateTime.parse(item['takenAt']),
        uploadedAt: DateTime.parse(item['createdAt']),
        location: item['location'],
        tags: List<String>.from(item['tags']),
      );
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    }
  }

  // 删除照片
  Future<bool> deletePhoto(String photoId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.deletePhoto(photoId);
      _photos.removeWhere((photo) => photo.id == photoId);
      _familyPhotosCache.clear(); // 清家人共享缓存
      await StorageService.savePhotos(_photos);
      await StorageService.deletePhoto(photoId);
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

  // 批量删除照片
  Future<bool> deletePhotos(List<String> photoIds) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.deletePhotos(photoIds);
      _photos.removeWhere((photo) => photoIds.contains(photo.id));
      _familyPhotosCache.clear(); // 清家人共享缓存
      await StorageService.savePhotos(_photos);
      for (final id in photoIds) {
        await StorageService.deletePhoto(id);
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

  // 按日期分组照片
  Map<String, List<Photo>> getPhotosByDate() {
    final Map<String, List<Photo>> groupedPhotos = {};
    
    for (final photo in _photos) {
      final date = '${photo.takenAt.year}-${photo.takenAt.month.toString().padLeft(2, '0')}-${photo.takenAt.day.toString().padLeft(2, '0')}';
      if (!groupedPhotos.containsKey(date)) {
        groupedPhotos[date] = [];
      }
      groupedPhotos[date]!.add(photo);
    }
    
    // 按日期降序排序
    final sortedKeys = groupedPhotos.keys.toList()..sort((a, b) => b.compareTo(a));
    final sortedGroupedPhotos = <String, List<Photo>>{};
    for (final key in sortedKeys) {
      sortedGroupedPhotos[key] = groupedPhotos[key]!;
    }
    
    return sortedGroupedPhotos;
  }

  // 获取家庭组照片列表
  Future<List<Photo>> getFamilyPhotos(String familyId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _apiService.getFamilyPhotos(familyId);
      final photos = (data['data']['photos'] as List).map((item) => Photo(
        id: item['id'].toString(),
        userId: item['userId'].toString(),
        url: item['url'],
        thumbnailUrl: item['thumbnailUrl'],
        fileName: item['fileName'],
        size: item['size'],
        contentType: item['contentType'],
        hash: item['hash'],
        takenAt: DateTime.parse(item['takenAt']),
        uploadedAt: DateTime.parse(item['createdAt']),
        location: item['location'],
        tags: List<String>.from(item['tags']),
      )).toList();
      
      _isLoading = false;
      notifyListeners();
      return photos;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return [];
    }
  }

  void invalidateFamilyPhotos(String familyId) {
    _familyPhotosCache.remove(familyId);
    notifyListeners();
  }

  void clearAllFamilyCache() {
    _familyPhotosCache.clear();
    notifyListeners();
  }

  // 存储进行中的 Future，防止多次触发相同 API 调用
  final Map<String, Future<List<Photo>>> _familyPhotosFuture = {};

  // 同步获取缓存的家庭照片（不触发加载），供 build 方法直接使用
  List<Photo> getCachedFamilyPhotos(String familyId) {
    return _familyPhotosCache[familyId] ?? [];
  }

  // 是否为指定家庭正在加载照片
  bool isFamilyPhotosLoading(String familyId) {
    return _familyPhotosLoading[familyId] == true;
  }

  Future<List<Photo>> getFamilyPhotosCached(String familyId) {
    // 缓存命中直接返回
    if (_familyPhotosCache.containsKey(familyId)) {
      return Future.value(_familyPhotosCache[familyId]);
    }

    // 正在加载中，返回同一个 Future（避免 FutureBuilder 重建时提前返回空）
    if (_familyPhotosFuture.containsKey(familyId)) {
      return _familyPhotosFuture[familyId]!;
    }

    // 发起新请求，保存 Future 引用
    final future = _loadFamilyPhotos(familyId);
    _familyPhotosFuture[familyId] = future;
    return future;
  }

  Future<List<Photo>> _loadFamilyPhotos(String familyId) async {
    _familyPhotosLoading[familyId] = true;
    notifyListeners();

    try {
      final photos = await getFamilyPhotos(familyId);
      _familyPhotosCache[familyId] = photos;
      return photos;
    } finally {
      _familyPhotosLoading[familyId] = false;
      _familyPhotosFuture.remove(familyId);
      notifyListeners();
    }
  }
}
