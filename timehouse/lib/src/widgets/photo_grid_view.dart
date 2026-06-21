import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/photo.dart';

class PhotoGridView extends StatefulWidget {
  final List<Photo> photos;
  final bool isSelectionMode;
  final List<String> selectedIds;
  final Function(String)? onPhotoTap;
  final Function(String)? onPhotoLongPress;
  final VoidCallback? onPhotoViewReturn;
  final String? familyId;

  const PhotoGridView({
    super.key,
    required this.photos,
    this.isSelectionMode = false,
    this.selectedIds = const [],
    this.onPhotoTap,
    this.onPhotoLongPress,
    this.onPhotoViewReturn,
    this.familyId,
  });

  @override
  State<PhotoGridView> createState() => _PhotoGridViewState();
}

class _PhotoGridViewState extends State<PhotoGridView> {
  int _displayCount = 6; // 首批 2 行 × 3 列 = 6 张
  Timer? _loadTimer;

  @override
  void initState() {
    super.initState();
    if (widget.photos.length > _displayCount) _scheduleLoadMore();
  }

  @override
  void didUpdateWidget(PhotoGridView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.photos.length != oldWidget.photos.length) {
      _displayCount = 6;
      if (widget.photos.length > _displayCount) _scheduleLoadMore();
    }
  }

  @override
  void dispose() {
    _loadTimer?.cancel();
    super.dispose();
  }

  void _scheduleLoadMore() {
    _loadTimer?.cancel();
    _loadTimer = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() {
        _displayCount = (_displayCount + 6).clamp(0, widget.photos.length);
      });
      if (widget.photos.length > _displayCount) _scheduleLoadMore();
    });
  }

  Map<String, List<Photo>> _groupByDate() {
    final Map<String, List<Photo>> grouped = {};
    for (final photo in widget.photos) {
      final date = '${photo.takenAt.year}-${photo.takenAt.month.toString().padLeft(2, '0')}-${photo.takenAt.day.toString().padLeft(2, '0')}';
      grouped.putIfAbsent(date, () => []);
      grouped[date]!.add(photo);
    }
    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
    final sorted = <String, List<Photo>>{};
    for (final key in sortedKeys) {
      sorted[key] = grouped[key]!;
    }
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.photos.isEmpty) {
      return const Center(child: Text('暂无照片', style: TextStyle(color: Color(0xFF8E8E93))));
    }

    final grouped = _groupByDate();

    // 只展示前 _displayCount 张
    int remaining = _displayCount;
    final visibleGroups = <String, List<Photo>>{};
    for (final date in grouped.keys) {
      if (remaining <= 0) break;
      final datePhotos = grouped[date]!;
      visibleGroups[date] = datePhotos.take(remaining).toList();
      remaining -= visibleGroups[date]!.length;
    }

    return ListView.builder(
      itemCount: visibleGroups.length + (widget.photos.length > _displayCount ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= visibleGroups.length) {
          // "加载更多"指示器
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
          );
        }

        final date = visibleGroups.keys.elementAt(index);
        final datePhotos = visibleGroups[date]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
              child: Text(date, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Color(0xFF8E8E93))),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: datePhotos.length,
              itemBuilder: (context, photoIndex) {
                final photo = datePhotos[photoIndex];
                final isSelected = widget.selectedIds.contains(photo.id);

                return GestureDetector(
                  onTap: () async {
                    if (widget.isSelectionMode) {
                      widget.onPhotoTap?.call(photo.id);
                    } else {
                      final ids = widget.photos.map((p) => p.id).toList();
                      final idx = widget.photos.indexOf(photo);
                      final extra = <String, dynamic>{'neighborIds': ids, 'currentIndex': idx};
                      if (widget.familyId != null) extra['familyId'] = widget.familyId;
                      await context.push('/photo/${photo.id}', extra: extra);
                      widget.onPhotoViewReturn?.call();
                    }
                  },
                  onLongPress: () => widget.onPhotoLongPress?.call(photo.id),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: photo.thumbnailUrl,
                          cacheKey: photo.id,  // 用照片ID做缓存key，避免预签名URL变化导致缓存失效
                          fit: BoxFit.cover,
                          memCacheWidth: 300,
                          maxWidthDiskCache: 600,
                          placeholder: (context, url) => Container(
                            color: const Color(0xFFE8E8E4),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: const Color(0xFFE8E8E4),
                            child: const Center(child: Icon(Icons.broken_image_outlined, color: Color(0xFFC0C0C0), size: 24)),
                          ),
                        ),
                        if (widget.isSelectionMode)
                          Positioned(
                            top: 6, right: 6,
                            child: Container(
                              width: 24, height: 24,
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFF5B9BD5) : Colors.white.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 4)],
                              ),
                              child: isSelected ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
