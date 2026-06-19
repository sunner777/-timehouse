import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

class PhotoCache {
  static Directory? _cacheDir;

  static Future<Directory> get _dir async {
    if (_cacheDir != null) return _cacheDir!;
    final base = await getApplicationDocumentsDirectory();
    _cacheDir = Directory('${base.path}/photos');
    if (!_cacheDir!.existsSync()) _cacheDir!.createSync(recursive: true);
    return _cacheDir!;
  }

  /// 本地缓存路径
  static Future<String> pathFor(String photoId) async {
    final dir = await _dir;
    return '${dir.path}/$photoId.jpg';
  }

  /// 是否有本地缓存
  static Future<bool> exists(String photoId) async {
    return File(await pathFor(photoId)).existsSync();
  }

  /// 保存到本地缓存
  static Future<void> save(String photoId, Uint8List bytes) async {
    await File(await pathFor(photoId)).writeAsBytes(bytes);
  }

  /// 缓存总大小（MB）
  static Future<double> totalSizeMB() async {
    final dir = await _dir;
    if (!dir.existsSync()) return 0;
    int total = 0;
    for (final f in dir.listSync()) {
      if (f is File) total += f.lengthSync();
    }
    return total / (1024 * 1024);
  }
}
