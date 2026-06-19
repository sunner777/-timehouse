import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/photo.dart';

class StorageService {
  static Database? _database;
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    // 初始化数据库
    final dbPath = await getDatabasesPath();
    _database = await openDatabase(
      join(dbPath, 'timehouse.db'),
      onCreate: (db, version) {
        return db.execute(
          '''
          CREATE TABLE photos (
            id TEXT PRIMARY KEY,
            userId TEXT,
            url TEXT,
            thumbnailUrl TEXT,
            fileName TEXT,
            size INTEGER,
            contentType TEXT,
            hash TEXT,
            takenAt TEXT,
            uploadedAt TEXT,
            location TEXT,
            tags TEXT
          )
          ''',
        );
      },
      onUpgrade: (db, oldVersion, newVersion) {
        if (oldVersion < 2) {
          db.execute('ALTER TABLE photos ADD COLUMN hash TEXT');
        }
      },
      version: 2,
    );

    // 初始化SharedPreferences
    _prefs = await SharedPreferences.getInstance();
  }

  // 保存用户信息（登录成功后调用）
  static Future<void> saveUserInfo(String userId, String token, {String? phone}) async {
    if (_prefs == null) {
      _prefs = await SharedPreferences.getInstance();
    }
    await _prefs?.setString('userId', userId);
    await _prefs?.setString('token', token);
    if (phone != null) await _prefs?.setString('phone', phone);
  }

  // 获取用户信息
  static String? getUserId() {
    return _prefs?.getString('userId');
  }
  static String? getToken() {
    return _prefs?.getString('token');
  }
  static String? getPhone() {
    return _prefs?.getString('phone');
  }

  // 昵称
  static Future<void> saveNickname(String nickname) async {
    await _prefs?.setString('nickname', nickname);
  }
  static String? getNickname() {
    return _prefs?.getString('nickname');
  }

  // 清除用户信息
  static Future<void> clearUserInfo() async {
    await _prefs?.remove('userId');
    await _prefs?.remove('token');
    await _prefs?.remove('phone');
    await _prefs?.remove('nickname');
  }

  // 保存照片到本地数据库
  static Future<void> savePhotos(List<Photo> photos) async {
    final batch = _database?.batch();
    for (final photo in photos) {
      batch?.insert(
        'photos',
        {
          'id': photo.id,
          'userId': photo.userId,
          'url': photo.url,
          'thumbnailUrl': photo.thumbnailUrl,
          'fileName': photo.fileName,
          'size': photo.size,
          'contentType': photo.contentType,
          'hash': photo.hash,
          'takenAt': photo.takenAt.toIso8601String(),
          'uploadedAt': photo.uploadedAt.toIso8601String(),
          'location': photo.location,
          'tags': photo.tags.join(','),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch?.commit();
  }

  // 从本地数据库获取照片
  static Future<List<Photo>> getPhotos() async {
    final List<Map<String, dynamic>> maps = await _database?.query('photos') ?? [];
    return List.generate(maps.length, (i) {
      return Photo(
        id: maps[i]['id'],
        userId: maps[i]['userId'],
        url: maps[i]['url'],
        thumbnailUrl: maps[i]['thumbnailUrl'],
        fileName: maps[i]['fileName'],
        size: maps[i]['size'],
        contentType: maps[i]['contentType'],
        hash: maps[i]['hash'],
        takenAt: DateTime.parse(maps[i]['takenAt']),
        uploadedAt: DateTime.parse(maps[i]['uploadedAt']),
        location: maps[i]['location'],
        tags: maps[i]['tags'].split(','),
      );
    });
  }

  // 检查本地数据库是否已存在相同哈希的照片
  static Future<bool> checkHashLocally(String hash) async {
    if (hash.isEmpty) return false;
    final result = await _database?.query(
      'photos',
      where: 'hash = ?',
      whereArgs: [hash],
    );
    return result != null && result.isNotEmpty;
  }

  // 删除本地照片
  static Future<void> deletePhoto(String photoId) async {
    await _database?.delete('photos', where: 'id = ?', whereArgs: [photoId]);
  }

  // 清空本地照片
  static Future<void> clearPhotos() async {
    await _database?.delete('photos');
  }
}
