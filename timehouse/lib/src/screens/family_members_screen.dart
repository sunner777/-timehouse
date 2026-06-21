import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/family_provider.dart';

class FamilyMembersScreen extends StatefulWidget {
  final String familyId;
  final String familyName;

  const FamilyMembersScreen({super.key, required this.familyId, required this.familyName});

  @override
  State<FamilyMembersScreen> createState() => _FamilyMembersScreenState();
}

class _FamilyMembersScreenState extends State<FamilyMembersScreen> {
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshMembers();
    });
  }

  void _refreshMembers() {
    Provider.of<FamilyProvider>(context, listen: false).getFamilyDetail(widget.familyId);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _showAddMemberDialog() {
    final provider = Provider.of<FamilyProvider>(context, listen: false);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24, top: 20, right: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('添加成员', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            const SizedBox(height: 24),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              maxLength: 11,
              style: const TextStyle(fontSize: 18),
              decoration: const InputDecoration(
                hintText: '手机号',
                counterText: '',
                filled: false,
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFD0D0D0))),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF5B9BD5), width: 2)),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                if (_phoneController.text.trim().isEmpty) return;
                await provider.addMember(widget.familyId, _phoneController.text.trim(), 'member');
                if (provider.errorMessage == null && ctx.mounted) {
                  Navigator.of(ctx).pop();
                  _phoneController.clear();
                }
              },
              child: const Text('添加'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showRoleDialog(String memberId, String currentRole, String nickname) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('修改 $nickname 的权限', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            const SizedBox(height: 20),
            ...['admin', 'member', 'guest'].map((role) => ListTile(
              leading: Radio<String>(value: role, groupValue: currentRole, onChanged: (_) => Navigator.of(ctx).pop(role)),
              title: Text(_roleLabel(role), style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(_roleDesc(role)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            )),
          ],
        ),
      ),
    ).then((newRole) {
      if (newRole != null && newRole != currentRole) {
        Provider.of<FamilyProvider>(context, listen: false)
            .updateMemberPermission(widget.familyId, memberId, newRole);
      }
    });
  }

  void _removeMember(String memberId, String nickname) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认移除'),
        content: Text('确定要移除 $nickname 吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('移除', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed == true) {
      Provider.of<FamilyProvider>(context, listen: false).removeMember(widget.familyId, memberId);
    }
  }

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
      case 'member': return '成员';
      case 'guest': return '访客';
      default: return '成员';
    }
  }

  String _roleDesc(String role) {
    switch (role) {
      case 'admin': return '可查看、编辑、删除照片';
      case 'member': return '可查看、编辑照片';
      case 'guest': return '仅可查看照片';
      default: return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FamilyProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(widget.familyName)),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.familyMembers.isEmpty
              ? const Center(child: Text('暂无成员', style: TextStyle(color: Color(0xFF8E8E93))))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: provider.familyMembers.length,
                  itemBuilder: (context, index) {
                    final member = provider.familyMembers[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                      child: Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: member.role != 'owner'
                              ? () => _showRoleDialog(member.userId, member.role, member.nickname)
                              : null,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: _roleColor(member.role).withOpacity(0.15),
                                  radius: 22,
                                  backgroundImage: (member.avatar != null && member.avatar!.isNotEmpty)
                                      ? NetworkImage(member.avatar!)
                                      : null,
                                  child: (member.avatar == null || member.avatar!.isEmpty)
                                      ? Text(
                                          member.nickname.isNotEmpty ? member.nickname[0] : '?',
                                          style: TextStyle(color: _roleColor(member.role), fontWeight: FontWeight.w600, fontSize: 16),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(member.nickname, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                                      Text(_roleLabel(member.role),
                                          style: TextStyle(fontSize: 13, color: _roleColor(member.role))),
                                    ],
                                  ),
                                ),
                                if (member.role != 'owner')
                                  PopupMenuButton<String>(
                                    onSelected: (value) {
                                      if (value == 'remove') _removeMember(member.userId, member.nickname);
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(value: 'remove', child: Text('移除成员', style: TextStyle(color: Colors.red))),
                                    ],
                                    icon: const Icon(Icons.more_horiz, color: Color(0xFFC0C0C0)),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: GestureDetector(
        onTap: _showAddMemberDialog,
        child: Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFF5B9BD5),
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: const Color(0xFF5B9BD5).withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: const Icon(Icons.person_add, color: Colors.white),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
