import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/photo_provider.dart';
import '../providers/family_provider.dart';

class UploadFAB extends StatefulWidget {
  final String? preSelectedFamilyId;

  const UploadFAB({super.key, this.preSelectedFamilyId});

  @override
  State<UploadFAB> createState() => _UploadFABState();
}

class _UploadFABState extends State<UploadFAB> {
  bool _isUploading = false;
  int _uploadProgress = 0;
  int _uploadTotal = 0;

  Future<void> _upload() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage(
      maxWidth: 1920, maxHeight: 1080, imageQuality: 85,
    );
    if (images.isEmpty) return;

    final taken = images.take(10).toList();
    setState(() { _isUploading = true; _uploadProgress = 0; _uploadTotal = taken.length; });

    final photoProvider = Provider.of<PhotoProvider>(context, listen: false);
    final familyProvider = Provider.of<FamilyProvider>(context, listen: false);
    final apiService = photoProvider.getApiService();

    final uploadedIds = <String>[];
    for (final image in taken) {
      final photoId = await photoProvider.uploadPhoto(image.path);
      if (photoId != null) uploadedIds.add(photoId);
      if (mounted) setState(() => _uploadProgress++);
    }

    // 刷新
    await photoProvider.getPhotos();
    photoProvider.clearAllFamilyCache();

    final skippedCount = photoProvider.lastUploadSkippedCount;

    setState(() { _isUploading = false; _uploadProgress = 0; _uploadTotal = 0; });

    if (!mounted) return;

    // 显示跳过提示
    if (skippedCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$skippedCount 张照片已存在，已跳过'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }

    if (uploadedIds.isEmpty) return;

    final families = familyProvider.families;
    if (families.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('成功上传 ${uploadedIds.length} 张照片'), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    // 可见范围选择 — 加底部安全间距避免被 tab 挡住
    if (!mounted) return;
    final selectedFamilyId = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 16),
              decoration: BoxDecoration(color: const Color(0xFFD0D0D0), borderRadius: BorderRadius.circular(2)),
            ),
            const Text('选择照片可见范围', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('已上传 ${uploadedIds.length} 张照片', style: const TextStyle(fontSize: 14, color: Color(0xFF8E8E93))),
            const SizedBox(height: 12),
            ...families.map((f) => ListTile(
              title: Text(f.name),
              subtitle: Text('${f.memberCount} 人'),
              trailing: widget.preSelectedFamilyId == f.id ? const Icon(Icons.check, color: Color(0xFF5B9BD5)) : null,
              onTap: () => Navigator.of(ctx).pop(f.id),
            )),
            ListTile(
              title: const Text('仅自己可见', style: TextStyle(color: Color(0xFF8E8E93))),
              onTap: () => Navigator.of(ctx).pop(''),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (selectedFamilyId != null && mounted) {
      final targetId = selectedFamilyId!.isEmpty ? null : selectedFamilyId;
      for (final id in uploadedIds) {
        await apiService.updatePhotoFamily(id, targetId);
      }
      if (targetId != null) photoProvider.invalidateFamilyPhotos(targetId);
      await photoProvider.getPhotos();

      final targetName = selectedFamilyId!.isNotEmpty
          ? families.firstWhere((f) => f.id == selectedFamilyId).name
          : '仅自己可见';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('上传 ${uploadedIds.length} 张 → $targetName'), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isUploading) {
      // 上传中显示进度
      return GestureDetector(
        onTap: null,
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: const Color(0xFF5B9BD5),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF5B9BD5).withOpacity(0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('$_uploadProgress', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
              Text('/$_uploadTotal', style: const TextStyle(color: Colors.white70, fontSize: 11)),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: _upload,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: const Color(0xFF5B9BD5),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF5B9BD5).withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 28),
      ),
    );
  }
}
