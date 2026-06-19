import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/photo_provider.dart';
import '../widgets/bottom_nav_bar.dart';

class PhotosScreen extends StatefulWidget {
  @override
  _PhotosScreenState createState() => _PhotosScreenState();
}

class _PhotosScreenState extends State<PhotosScreen> {
  bool _isSelectionMode = false;
  List<String> _selectedPhotoIds = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PhotoProvider>(context, listen: false).getPhotos();
    });
  }

  void _toggleSelection(String photoId) {
    setState(() {
      if (_selectedPhotoIds.contains(photoId)) {
        _selectedPhotoIds.remove(photoId);
        if (_selectedPhotoIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedPhotoIds.add(photoId);
        _isSelectionMode = true;
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _isSelectionMode = false;
      _selectedPhotoIds.clear();
    });
  }

  void _deleteSelected() async {
    final confirmed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('确认删除'),
        content: Text('确定要删除选中的${_selectedPhotoIds.length}张照片吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final photoProvider = Provider.of<PhotoProvider>(context, listen: false);
      await photoProvider.deletePhotos(_selectedPhotoIds);
      _clearSelection();
    }
  }

  @override
  Widget build(BuildContext context) {
    final photoProvider = Provider.of<PhotoProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: _isSelectionMode
            ? Text('已选择 ${_selectedPhotoIds.length} 张')
            : Text('照片'),
        leading: _isSelectionMode
            ? IconButton(
                icon: Icon(Icons.close),
                onPressed: _clearSelection,
              )
            : null,
        actions: _isSelectionMode
            ? [
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: _deleteSelected,
                ),
              ]
            : [
                IconButton(
                  icon: Icon(Icons.add),
                  onPressed: () async {
                    final ImagePicker _picker = ImagePicker();
                    final List<XFile> images = await _picker.pickMultiImage(
                      maxWidth: 1920,
                      maxHeight: 1080,
                      imageQuality: 85,
                    );

                    if (images.isNotEmpty) {
                      final selectedImages = images.take(10).toList();

                      final photoProvider = Provider.of<PhotoProvider>(context, listen: false);
                      for (final image in selectedImages) {
                        await photoProvider.uploadPhoto(image.path);
                      }

                      final skipped = photoProvider.lastUploadSkippedCount;
                      if (skipped > 0 && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('$skipped 张照片已存在，已跳过'),
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      }
                    }
                  },
                ),
              ],
      ),
      body: photoProvider.isLoading
          ? Center(child: CircularProgressIndicator())
          : photoProvider.photos.isEmpty
              ? Center(child: Text('暂无照片'))
              : ListView.builder(
                  itemCount: photoProvider.getPhotosByDate().length,
                  itemBuilder: (context, index) {
                    final date = photoProvider.getPhotosByDate().keys.elementAt(index);
                    final photos = photoProvider.getPhotosByDate()[date];

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Text(
                            date,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 2,
                            mainAxisSpacing: 2,
                          ),
                          itemCount: photos!.length,
                          itemBuilder: (context, photoIndex) {
                            final photo = photos[photoIndex];
                            final isSelected = _selectedPhotoIds.contains(photo.id);

                            return GestureDetector(
                              onTap: _isSelectionMode
                                  ? () => _toggleSelection(photo.id)
                                  : () {
                                      GoRouter.of(context).go('/photo/${photo.id}');
                                    },
                              onLongPress: () {
                                // 长按进入选择模式，只选中当前照片
                                setState(() {
                                  _isSelectionMode = true;
                                  _selectedPhotoIds = [photo.id];
                                });
                              },
                              child: Stack(
                                children: [
                                  CachedNetworkImage(
                                    imageUrl: photo.thumbnailUrl,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                    placeholder: (context, url) => Container(
                                      color: Colors.grey[200],
                                      child: Center(
                                        child: Icon(Icons.image, color: Colors.grey[400]),
                                      ),
                                    ),
                                    errorWidget: (context, url, error) => Container(
                                      color: Colors.grey[200],
                                      child: Center(
                                        child: Icon(Icons.error, color: Colors.red),
                                      ),
                                    ),
                                  ),
                                  if (_isSelectionMode)
                                    Positioned(
                                      top: 5,
                                      right: 5,
                                      child: Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: isSelected ? Colors.blue : Colors.white,
                                          border: Border.all(color: Colors.grey),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: isSelected
                                            ? Icon(Icons.check, size: 16, color: Colors.white)
                                            : null,
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                        SizedBox(height: 20),
                      ],
                    );
                  },
                ),
      bottomNavigationBar: BottomNavBar(currentRoute: '/'),
    );
  }
}
