import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/photo_provider.dart';
import '../providers/family_provider.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/photo_grid_view.dart';
import '../widgets/upload_fab.dart';

class MySpaceScreen extends StatefulWidget {
  const MySpaceScreen({super.key});

  @override
  State<MySpaceScreen> createState() => _MySpaceScreenState();
}

class _MySpaceScreenState extends State<MySpaceScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _lastRefresh = DateTime(2000);

  bool _isSelectionMode = false;
  final Set<String> _selectedPhotoIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging && _tabController.index == 0) {
        _tryRefresh();
      }
    });
    // 显式监听确保数据变更必定触发重建
    final photoProvider = Provider.of<PhotoProvider>(context, listen: false);
    photoProvider.addListener(_onDataChanged);
    final familyProvider = Provider.of<FamilyProvider>(context, listen: false);
    familyProvider.addListener(_onDataChanged);
    // 首帧就绪后从服务器拉最新数据（本地缓存已在 main() 中预装）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _tryRefresh();
      familyProvider.getFamilies();
    });
  }

  void _onDataChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    Provider.of<PhotoProvider>(context, listen: false).removeListener(_onDataChanged);
    Provider.of<FamilyProvider>(context, listen: false).removeListener(_onDataChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _tryRefresh() {
    if (DateTime.now().difference(_lastRefresh).inSeconds < 3) return;
    _lastRefresh = DateTime.now();
    Provider.of<PhotoProvider>(context, listen: false).getPhotos();
  }

  void _clearSelection() {
    setState(() { _isSelectionMode = false; _selectedPhotoIds.clear(); });
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
    setState(() { _isSelectionMode = true; _selectedPhotoIds.add(photoId); });
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

  void _goCreateFamily() => context.push('/create-family');

  Color _roleColor(String role) {
    switch (role) {
      case 'owner': return const Color(0xFF5B9BD5);
      case 'admin': return const Color(0xFF7EC8A0);
      default: return const Color(0xFF8E8E93);
    }
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'owner': return '群主';
      case 'admin': return '管理员';
      default: return '成员';
    }
  }

  @override
  Widget build(BuildContext context) {
    final photoProvider = Provider.of<PhotoProvider>(context);
    final familyProvider = Provider.of<FamilyProvider>(context);

    final body = _isSelectionMode
        ? PhotoGridView(
            photos: photoProvider.photos,
            isSelectionMode: true,
            selectedIds: _selectedPhotoIds.toList(),
            onPhotoTap: _onPhotoTap,
            onPhotoLongPress: _onPhotoLongPress,
          )
        : TabBarView(
            controller: _tabController,
            children: [
              // 已有缓存数据 → 直接展示；无缓存 + 加载中 → 转圈等待
              photoProvider.photos.isEmpty && photoProvider.isLoadingMyPhotos
                  ? const Center(child: CircularProgressIndicator())
                  : PhotoGridView(
                      photos: photoProvider.photos,
                      onPhotoLongPress: _onPhotoLongPress,
                    ),
              _buildFamilyTab(familyProvider),
            ],
          );

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 页面头部 — 与家人共享页统一
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('我的空间', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w700, letterSpacing: -0.5)),
                  SizedBox(height: 4),
                  Text('👨‍👩‍👧‍👦 我们的每一刻，都值得珍藏',
                      style: TextStyle(fontSize: 15, color: Color(0xFF6C6C70))),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Tab bar
            // 轻量加载提示（不阻塞 UI）
            if (!_isSelectionMode && photoProvider.isLoadingMyPhotos)
              const SizedBox(
                height: 2,
                child: LinearProgressIndicator(minHeight: 2),
              ),
            if (!_isSelectionMode)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.black.withOpacity(0.08))),
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: const Color(0xFF5B9BD5),
                  unselectedLabelColor: const Color(0xFF8E8E93),
                  labelStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  unselectedLabelStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
                  indicatorColor: const Color(0xFF5B9BD5),
                  indicatorWeight: 3,
                  tabs: const [
                    Tab(text: '我的照片'),
                    Tab(text: '我的家人共享'),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            // 主体
            Expanded(child: body),
          ],
        ),
      ),
      floatingActionButton: _isSelectionMode ? null : const UploadFAB(),
      bottomNavigationBar: _isSelectionMode
          ? BottomAppBar(
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
            )
          : const BottomNavBar(currentRoute: '/my-space'),
    );
  }

  Widget _buildFamilyTab(FamilyProvider familyProvider) {
    final hasError = familyProvider.errorMessage != null;
    if (hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 48, color: Color(0xFFC0C0C0)),
              const SizedBox(height: 16),
              Text(familyProvider.errorMessage!,
                  style: const TextStyle(fontSize: 14, color: Color(0xFF8E8E93)),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 24),
              Material(
                color: const Color(0xFF5B9BD5),
                borderRadius: BorderRadius.circular(28),
                child: InkWell(
                  borderRadius: BorderRadius.circular(28),
                  onTap: () {
                    familyProvider.clearError();
                    familyProvider.getFamilies();
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.refresh, size: 16, color: Colors.white),
                        SizedBox(width: 4),
                        Text('重试', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _goCreateFamily,
              icon: const Icon(Icons.add, size: 20),
              label: const Text('创建'),
            ),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: familyProvider.families.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.group_outlined, size: 56, color: Colors.grey[300]),
                      const SizedBox(height: 12),
                      const Text('还没有家人共享', style: TextStyle(fontSize: 16, color: Color(0xFF8E8E93))),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: familyProvider.families.length,
                  itemBuilder: (context, index) {
                    final family = familyProvider.families[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                      child: Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => context.push('/families/${family.id}/members', extra: family.name),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: _roleColor(family.role).withOpacity(0.15),
                                  radius: 22,
                                  child: Icon(Icons.group_rounded, color: _roleColor(family.role), size: 22),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(family.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                                      const SizedBox(height: 2),
                                      Text('${_roleLabel(family.role)} · ${family.memberCount}人',
                                          style: const TextStyle(fontSize: 13, color: Color(0xFF8E8E93))),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right, color: Color(0xFFC0C0C0)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
