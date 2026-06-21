import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/user_provider.dart';
import '../services/storage_service.dart';
import '../widgets/bottom_nav_bar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? get _phone => StorageService.getPhone() ?? StorageService.getUserId();

  String get _displayPhone {
    final phone = _phone;
    if (phone == null || phone.length < 11) return phone ?? '';
    return '${phone.substring(0, 3)} **** ${phone.substring(7)}';
  }

  void _editNickname(UserProvider provider) {
    provider.clearError();
    final ctrl = TextEditingController(text: provider.nickname.isNotEmpty ? provider.nickname : '我的家人');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('修改昵称'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLength: 12,
          style: const TextStyle(fontSize: 18),
          decoration: const InputDecoration(
            hintText: '输入昵称',
            filled: false,
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFD0D0D0))),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF5B9BD5), width: 2)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () {
              final name = ctrl.text.trim();
              if (name.isNotEmpty) {
                provider.setNickname(name);
              }
              Navigator.pop(ctx);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  Future<void> _logout(UserProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('退出登录'),
        content: const Text('确定要退出登录吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('确定', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed == true) {
      await provider.logout();
      if (mounted) GoRouter.of(context).go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UserProvider>();

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            // 头像 + 昵称
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () => _editNickname(provider),
                    child: CircleAvatar(
                      radius: 48,
                      backgroundColor: const Color(0xFF5B9BD5).withOpacity(0.12),
                      backgroundImage: (provider.avatar != null && provider.avatar!.isNotEmpty)
                          ? NetworkImage(provider.avatar!)
                          : null,
                      child: (provider.avatar == null || provider.avatar!.isEmpty)
                          ? Text(
                              provider.nickname.isNotEmpty ? provider.nickname[0] : '我',
                              style: const TextStyle(fontSize: 36, color: Color(0xFF5B9BD5), fontWeight: FontWeight.w600),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => _editNickname(provider),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          provider.nickname.isNotEmpty ? provider.nickname : '我的家人',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.edit, size: 16, color: Color(0xFF8E8E93)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(_displayPhone, style: const TextStyle(fontSize: 15, color: Color(0xFF8E8E93))),
                  // 错误提示
                  if (provider.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        provider.errorMessage!,
                        style: const TextStyle(fontSize: 12, color: Colors.red),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 36),
            // 设置项
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _buildItem(Icons.person_outline, '编辑昵称', () => _editNickname(provider)),
                  _buildItem(Icons.logout, '退出登录', () => _logout(provider), isDestructive: true),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentRoute: '/profile'),
    );
  }

  Widget _buildItem(IconData icon, String label, VoidCallback onTap, {bool isDestructive = false}) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 22, color: isDestructive ? Colors.red : const Color(0xFF5B9BD5)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(label,
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500, color: isDestructive ? Colors.red : null)),
              ),
              const Icon(Icons.chevron_right, size: 20, color: Color(0xFFC0C0C0)),
            ],
          ),
        ),
      ),
    );
  }
}
