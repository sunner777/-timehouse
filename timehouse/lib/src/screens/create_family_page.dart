import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/family_provider.dart';

class CreateFamilyPage extends StatefulWidget {
  const CreateFamilyPage({super.key});

  @override
  State<CreateFamilyPage> createState() => _CreateFamilyPageState();
}

class _CreateFamilyPageState extends State<CreateFamilyPage> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onCreate() async {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    await Provider.of<FamilyProvider>(context, listen: false).createFamily(name);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('创建家人共享')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('给家人共享取个名字',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const Text('比如"我们的家"、"旅行相册"',
                style: TextStyle(fontSize: 15, color: Color(0xFF8E8E93))),
            const SizedBox(height: 32),
            TextField(
              controller: _controller,
              autofocus: true,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
              decoration: const InputDecoration(
                hintText: '家人共享名称',
                filled: false,
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFD0D0D0)),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF5B9BD5), width: 2),
                ),
              ),
              maxLength: 20,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _onCreate,
              child: const Text('创建'),
            ),
          ],
        ),
      ),
    );
  }
}
