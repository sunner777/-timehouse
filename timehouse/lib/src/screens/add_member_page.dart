import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/family_provider.dart';

class AddMemberPage extends StatefulWidget {
  final String familyId;
  final String familyName;
  const AddMemberPage({super.key, required this.familyId, required this.familyName});

  @override
  State<AddMemberPage> createState() => _AddMemberPageState();
}

class _AddMemberPageState extends State<AddMemberPage> {
  final _phoneController = TextEditingController();
  String _selectedRole = 'member';

  Future<void> _onAdd() async {
    final phone = _phoneController.text.trim();
    if (phone.length != 11) return;
    final familyProvider = Provider.of<FamilyProvider>(context, listen: false);
    await familyProvider.addMember(widget.familyId, phone, _selectedRole);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('添加成员')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('向「${widget.familyName}」添加成员',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const Text('输入对方的手机号',
                style: TextStyle(fontSize: 15, color: Color(0xFF8E8E93))),
            const SizedBox(height: 32),
            TextField(
              controller: _phoneController,
              autofocus: true,
              keyboardType: TextInputType.phone,
              maxLength: 11,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500, letterSpacing: 1),
              decoration: const InputDecoration(
                hintText: '手机号',
                counterText: '',
                filled: false,
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFD0D0D0)),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF5B9BD5), width: 2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('角色',
                style: TextStyle(fontSize: 15, color: Color(0xFF8E8E93))),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'member', label: Text('成员')),
                ButtonSegment(value: 'admin', label: Text('管理员')),
                ButtonSegment(value: 'guest', label: Text('游客')),
              ],
              selected: {_selectedRole},
              onSelectionChanged: (v) => setState(() => _selectedRole = v.first),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _onAdd,
              child: const Text('添加'),
            ),
          ],
        ),
      ),
    );
  }
}
