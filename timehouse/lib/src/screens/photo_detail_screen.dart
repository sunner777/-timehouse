import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'package:gal/gal.dart';
import '../models/photo.dart';
import '../providers/photo_provider.dart';
import '../services/photo_cache.dart';

class PhotoDetailScreen extends StatefulWidget {
  final String photoId;
  final String? familyId;
  final List<String>? neighborIds;
  final int? currentIndex;

  const PhotoDetailScreen({
    super.key,
    required this.photoId,
    this.familyId,
    this.neighborIds,
    this.currentIndex,
  });

  @override
  State<PhotoDetailScreen> createState() => _PhotoDetailScreenState();
}

class _PhotoDetailScreenState extends State<PhotoDetailScreen> {
  Photo? _photo;
  bool _isLoading = true;
  bool _isZoomed = false;
  bool _isLocal = false;
  String? _localPath;
  final TransformationController _zoomCtrl = TransformationController();

  List<String> get _allIds => widget.neighborIds ?? [];

  @override
  void initState() {
    super.initState();
    _loadPhoto();
  }

  @override
  void dispose() {
    _zoomCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPhoto() async {
    final photoProvider = Provider.of<PhotoProvider>(context, listen: false);
    var photo = photoProvider.photos.firstWhere(
      (p) => p.id == widget.photoId,
      orElse: () => Photo(
        id: widget.photoId, userId: '1', url: '', thumbnailUrl: '',
        fileName: 'photo.jpg', size: 0, contentType: 'image/jpeg',
        takenAt: DateTime.now(), uploadedAt: DateTime.now(),
        location: '', tags: [],
      ),
    );

    if (photo.url.isEmpty) {
      final fetched = await photoProvider.getPhoto(widget.photoId);
      if (fetched != null) photo = fetched;
    }

    // 检查本地缓存
    final localExists = await PhotoCache.exists(widget.photoId);
    if (localExists) {
      _localPath = await PhotoCache.pathFor(widget.photoId);
      _isLocal = true;
    }

    if (mounted) setState(() { _photo = photo; _isLoading = false; });

    // 后台缓存到本地（不阻塞显示）
    if (!_isLocal && photo.url.isNotEmpty) {
      _cacheToLocal(photo.url);
    }
  }

  Future<void> _cacheToLocal(String url) async {
    try {
      final response = await Dio().get(
        url,
        options: Options(responseType: ResponseType.bytes),
      );
      if (response.data != null) {
        final bytes = Uint8List.fromList(response.data as List<int>);
        await PhotoCache.save(widget.photoId, bytes);
        if (mounted) {
        _localPath = await PhotoCache.pathFor(widget.photoId);
        setState(() { _isLocal = true; });
      }
      }
    } catch (_) { /* 静默失败，不影响体验 */ }
  }

  Future<void> _saveToGallery() async {
    try {
      // 优先用本地缓存
      Uint8List bytes;
      if (_isLocal && _localPath != null) {
        bytes = await File(_localPath!).readAsBytes();
      } else {
        HapticFeedback.mediumImpact();
        final response = await Dio().get(
          _photo!.url,
          options: Options(responseType: ResponseType.bytes),
        );
        if (response.data == null) throw Exception('download failed');
        bytes = Uint8List.fromList(response.data as List<int>);
      }

      await Gal.putImageBytes(bytes);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已保存到相册'), behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: ${e.toString().split('\n').first}'), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  void _onTapPhoto() {
    HapticFeedback.lightImpact();
    setState(() {
      _isZoomed = !_isZoomed;
      if (!_isZoomed) _zoomCtrl.value = Matrix4.identity();
    });
  }

  void _navigate(String targetPhotoId) {
    final idx = _allIds.indexOf(targetPhotoId);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => PhotoDetailScreen(
          photoId: targetPhotoId,
          familyId: widget.familyId,
          neighborIds: _allIds,
          currentIndex: idx >= 0 ? idx : null,
        ),
      ),
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final photo = _photo!;
    final photoProvider = Provider.of<PhotoProvider>(context);
    final isFromGroup = widget.familyId != null && widget.familyId!.isNotEmpty;
    final ids = _allIds;
    final idx = widget.currentIndex ?? ids.indexOf(widget.photoId);
    final prevId = (ids.isNotEmpty && idx > 0) ? ids[idx - 1] : null;
    final nextId = (ids.isNotEmpty && idx >= 0 && idx < ids.length - 1) ? ids[idx + 1] : null;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (_isZoomed) return;
          if (details.primaryVelocity == null) return;
          if (details.primaryVelocity! > 0 && prevId != null) {
            _navigate(prevId!);
          } else if (details.primaryVelocity! < 0 && nextId != null) {
            _navigate(nextId!);
          }
        },
        child: SafeArea(
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildPhotoView(photo),
              // 顶部栏
              Positioned(
                top: 0, left: 0, right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  color: Colors.black26,
                  child: Row(
                    children: [
                      IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.of(context).pop()),
                      const Spacer(),
                      if (_isLocal)
                        const Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: Icon(Icons.sim_card_download, color: Colors.white38, size: 18),
                        ),
                      IconButton(
                        icon: const Icon(Icons.download, color: Colors.white),
                        tooltip: '保存到相册',
                        onPressed: _saveToGallery,
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.white),
                        onPressed: () async {
                          final isDelete = !isFromGroup;
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: Text(isDelete ? '确认删除' : '从组中移除'),
                              content: Text(isDelete ? '确定要彻底删除这张照片吗？' : '确定要从该家人共享中移除此照片吗？'),
                              actions: [
                                TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('取消')),
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(true),
                                  child: Text(isDelete ? '删除' : '移除', style: const TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
                          if (confirmed != true || !mounted) return;
                          if (isDelete) {
                            await photoProvider.deletePhoto(photo.id);
                          } else {
                            await photoProvider.getApiService().updatePhotoFamily(photo.id, null);
                          }
                          if (mounted) Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                ),
              ),
              // 底部信息
              if (!_isZoomed)
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_formatDate(photo.takenAt), style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600)),
                        if (photo.location.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(children: [
                            const Icon(Icons.location_on, color: Colors.white70, size: 14),
                            const SizedBox(width: 4),
                            Text(photo.location, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                          ]),
                        ],
                        const SizedBox(height: 4),
                        Text('${_formatSize(photo.size)}${_isLocal ? " · 已缓存" : ""}', style: const TextStyle(color: Colors.white54, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              if (_isZoomed)
                const Positioned(
                  top: 60, left: 0, right: 0,
                  child: Center(child: Text('双指缩放中 · 长按保存 · 点击退出', style: TextStyle(color: Colors.white54, fontSize: 13))),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoView(Photo photo) {
    // 优先用本地缓存文件
    final imageProvider = (_isLocal && _localPath != null)
        ? FileImage(File(_localPath!)) as ImageProvider
        : NetworkImage(photo.url);

    return GestureDetector(
      onTap: _onTapPhoto,
      child: InteractiveViewer(
        transformationController: _zoomCtrl,
        panEnabled: _isZoomed,
        scaleEnabled: _isZoomed,
        minScale: 1.0,
        maxScale: 5.0,
        boundaryMargin: EdgeInsets.all(_isZoomed ? double.infinity : 0),
        child: Center(
          child: Image(
            image: imageProvider,
            fit: BoxFit.contain,
            gaplessPlayback: true,
            errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.white54, size: 64),
          ),
        ),
      ),
    );
  }
}
