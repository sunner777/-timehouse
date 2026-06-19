import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../models/family.dart';
import '../models/photo.dart';
import '../providers/family_provider.dart';
import '../providers/photo_provider.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/photo_grid_view.dart';
import '../widgets/upload_fab.dart';

String _relativeTime(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final thatDay = DateTime(date.year, date.month, date.day);
  final diff = today.difference(thatDay).inDays;
  if (diff == 0) return '今天';
  if (diff == 1) return '昨天';
  return '${diff}天前';
}

class FamiliesScreen extends StatefulWidget {
  const FamiliesScreen({super.key});

  @override
  State<FamiliesScreen> createState() => _FamiliesScreenState();
}

class _FamiliesScreenState extends State<FamiliesScreen> {
  int _selectedFamilyIndex = 0;
  bool _showMenu = false;

  bool _isSelectionMode = false;
  final Set<String> _selectedPhotoIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FamilyProvider>(context, listen: false).getFamilies();
    });
  }

  void _clearSelection() {
    setState(() {
      _isSelectionMode = false;
      _selectedPhotoIds.clear();
    });
  }

  void _onPhotoTap(String photoId) {
    if (_isSelectionMode) {
      setState(() {
        if (_selectedPhotoIds.contains(photoId)) {
          _selectedPhotoIds.remove(photoId);
          if (_selectedPhotoIds.isEmpty) _isSelectionMode = false;
        } else {
          _selectedPhotoIds.add(photoId);
        }
      });
    }
  }

  void _onPhotoLongPress(String photoId) {
    HapticFeedback.lightImpact();
    setState(() {
      _isSelectionMode = true;
      _selectedPhotoIds.add(photoId);
    });
  }

  Future<void> _batchDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除选中的 ${_selectedPhotoIds.length} 张照片吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('删除')),
        ],
      ),
    );
    if (confirmed != true) return;
    await Provider.of<PhotoProvider>(context, listen: false).deletePhotos(_selectedPhotoIds.toList());
    _clearSelection();
  }

  void _navigateToMembers() {
    final families = Provider.of<FamilyProvider>(context, listen: false).families;
    if (families.isEmpty) return;
    context.push('/families/${families[_selectedFamilyIndex].id}/members', extra: families[_selectedFamilyIndex].name);
  }

  void _menuAction(String which) {
    setState(() => _showMenu = false);
    final families = Provider.of<FamilyProvider>(context, listen: false).families;
    final currentFamilyId = families.isNotEmpty ? families[_selectedFamilyIndex].id : null;
    final currentFamilyName = families.isNotEmpty ? families[_selectedFamilyIndex].name : '';

    if (which == 'create') context.push('/create-family');
    else if (which == 'add') {
      context.push('/add-member', extra: {
        'familyId': currentFamilyId ?? '',
        'familyName': currentFamilyName,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final familyProvider = context.watch<FamilyProvider>();
    final photoProvider = context.watch<PhotoProvider>();
    final hasFamilies = familyProvider.families.isNotEmpty;

    final body = Stack(
      children: [
        familyProvider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : !hasFamilies
                ? _buildEmptyState()
                : Column(
                    children: [
                      // 标签栏
                      const SizedBox(height: 4),
                      SizedBox(
                        height: 48,
                        child: _buildTabs(familyProvider),
                      ),
                      Expanded(
                        child: _buildPhotoTimeline(familyProvider.families[_selectedFamilyIndex]),
                      ),
                    ],
                  ),
        if (_showMenu) _buildMenuOverlay(),
      ],
    );

    if (_isSelectionMode) {
      return Scaffold(
        appBar: AppBar(
          title: Text('已选择 ${_selectedPhotoIds.length} 张'),
          leading: IconButton(icon: const Icon(Icons.close), onPressed: _clearSelection),
        ),
        body: body,
        bottomNavigationBar: BottomAppBar(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton.icon(
                onPressed: _batchDelete,
                icon: const Icon(Icons.delete, color: Colors.red),
                label: const Text('删除', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ),
      );
    }

    // 计算当前家庭的统计
    final family = hasFamilies ? familyProvider.families[_selectedFamilyIndex] : null;
    final memberCount = family?.memberCount ?? 0;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 页面头部
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '家人共享',
                          style: TextStyle(fontSize: 34, fontWeight: FontWeight.w700, letterSpacing: -0.5),
                        ),
                                    const SizedBox(height: 4),
                        Row(
                          children: [
                            const Text('👨‍👩‍👧‍👦', style: TextStyle(fontSize: 15)),
                            const SizedBox(width: 4),
                            const Text(
                              '我们的每一刻，都值得珍藏',
                              style: TextStyle(fontSize: 15, color: Color(0xFF6C6C70)),
                            ),
                            const SizedBox(width: 12),
                            if (hasFamilies)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF5B9BD5).withOpacity(0.10),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '$memberCount位家人',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF5B9BD5)),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // 主体
            Expanded(child: body),
          ],
        ),
      ),
      floatingActionButton: UploadFAB(
        preSelectedFamilyId: hasFamilies ? familyProvider.families[_selectedFamilyIndex].id : null,
      ),
      bottomNavigationBar: const BottomNavBar(currentRoute: '/'),
    );
  }

  Widget _buildTabs(FamilyProvider familyProvider) {
    return Stack(
      children: [
        Positioned.fill(
          right: 56,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemBuilder: (context, index) {
              final fam = familyProvider.families[index];
              final selected = _selectedFamilyIndex == index;
              return GestureDetector(
                onTap: () => setState(() => _selectedFamilyIndex = index),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        fam.name,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                          color: selected ? const Color(0xFF5B9BD5) : const Color(0xFF8E8E93),
                        ),
                      ),
                      if (selected)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          width: 28,
                          height: 3,
                          decoration: BoxDecoration(
                            color: const Color(0xFF5B9BD5),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
            itemCount: familyProvider.families.length,
          ),
        ),
        // 右侧胶囊按钮
        Positioned(
          right: 12,
          top: 4,
          child: _buildCapsuleButton(),
        ),
      ],
    );
  }

  Widget _buildCapsuleButton() {
    return GestureDetector(
      onTap: () => setState(() => _showMenu = true),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF5B9BD5).withOpacity(0.12),
          borderRadius: BorderRadius.circular(40),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, size: 18, color: Color(0xFF5B9BD5)),
            SizedBox(width: 4),
            Text('新建', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF5B9BD5))),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuOverlay() {
    return GestureDetector(
      onTap: () => setState(() => _showMenu = false),
      child: Container(
        color: Colors.black26,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(color: const Color(0xFFD0D0D0), borderRadius: BorderRadius.circular(2)),
                    ),
                    const SizedBox(height: 24),
                    _buildMenuItem('创建家人共享', () => _menuAction('create')),
                    const SizedBox(height: 4),
                    _buildMenuItem('添加家人共享成员', () => _menuAction('add')),
                    const SizedBox(height: 24),
                    _buildMenuItem('取消', () => setState(() => _showMenu = false), isCancel: true),
                  ],
                ),
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(String label, VoidCallback onTap, {bool isCancel = false}) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: isCancel ? const Color(0xFFF3F3F1) : Colors.transparent,
        borderRadius: BorderRadius.circular(isCancel ? 26 : 14),
        child: InkWell(
          borderRadius: BorderRadius.circular(isCancel ? 26 : 14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: isCancel ? FontWeight.w500 : FontWeight.w600,
                color: isCancel ? const Color(0xFF8E8E93) : const Color(0xFF1A1A1A),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.photo_library_outlined, size: 64, color: Color(0xFFD0D0D0)),
          const SizedBox(height: 20),
          const Text('还没有家人共享', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text('创建一个家人共享，邀请家人一起分享照片',
              style: TextStyle(fontSize: 14, color: Color(0xFF8E8E93))),
          const SizedBox(height: 32),
          Material(
            color: const Color(0xFF5B9BD5),
            borderRadius: BorderRadius.circular(28),
            child: InkWell(
              borderRadius: BorderRadius.circular(28),
              onTap: () => setState(() => _showMenu = true),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                child: Text('开始使用', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoTimeline(Family family) {
    final photoProvider = Provider.of<PhotoProvider>(context, listen: false);
    final photosFuture = photoProvider.getFamilyPhotosCached(family.id);

    return FutureBuilder<List<Photo>>(
      future: photosFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final photoList = snapshot.data;
        if (photoList == null || photoList.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('✨', style: TextStyle(fontSize: 40)),
                SizedBox(height: 12),
                Text('暂无照片，快上传一张记录家人的美好吧',
                    style: TextStyle(fontSize: 15, color: Color(0xFF8E8E93))),
              ],
            ),
          );
        }
        return PhotoGridView(
          photos: photoList,
          isSelectionMode: _isSelectionMode,
          selectedIds: _selectedPhotoIds.toList(),
          onPhotoTap: _onPhotoTap,
          onPhotoLongPress: _onPhotoLongPress,
          familyId: family.id,
          onPhotoViewReturn: () {
            photoProvider.invalidateFamilyPhotos(family.id);
            setState(() {});
          },
        );
      },
    );
  }
}
