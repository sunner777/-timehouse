import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/user_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();

  int _countdown = 0;
  Timer? _countdownTimer;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    setState(() => _countdown = 60);
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_countdown > 0) {
          _countdown--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  Future<void> _onSendCode(UserProvider provider) async {
    final phone = _phoneController.text;
    if (phone.length != 11) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先输入正确的手机号'), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    HapticFeedback.lightImpact();
    final success = await provider.sendSmsCode(phone);
    if (success) {
      _startCountdown();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('验证码已发送'), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  Future<void> _onLogin(UserProvider provider) async {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.lightImpact();
    final success = await provider.smsLogin(
      _phoneController.text,
      _codeController.text,
    );
    if (success && mounted) {
      GoRouter.of(context).go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UserProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 80),
                  // 标题
                  Text(
                    '拾光家',
                    textAlign: TextAlign.left,
                    style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A), letterSpacing: -1),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '我们的每一刻，都值得珍藏',
                    textAlign: TextAlign.left,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w400, color: Color(0xFF8E8E93)),
                  ),
                  const SizedBox(height: 56),

                  // 手机号 — 下划线
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    maxLength: 11,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500, letterSpacing: 1),
                    decoration: const InputDecoration(
                      hintText: '手机号',
                      counterText: '',
                      prefixIcon: Icon(Icons.phone_android_rounded, size: 22),
                      filled: false,
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFFD0D0D0)),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF5B9BD5), width: 2),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return '请输入手机号';
                      if (v.length != 11) return '请输入正确的手机号';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // 验证码行
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _codeController,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500, letterSpacing: 2),
                          decoration: const InputDecoration(
                            hintText: '验证码',
                            counterText: '',
                            prefixIcon: Icon(Icons.lock_outline_rounded, size: 22),
                            filled: false,
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFFD0D0D0)),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFF5B9BD5), width: 2),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return '请输入验证码';
                            if (v.length < 4) return '验证码至少4位';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        height: 44,
                        child: ElevatedButton(
                          onPressed: (_countdown > 0 || provider.isLoading)
                              ? null
                              : () => _onSendCode(provider),
                          style: ElevatedButton.styleFrom(
                            shape: const StadiumBorder(),
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            backgroundColor: const Color(0xFF5B9BD5),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: const Color(0xFFE0E0E0),
                            textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                          child: Text(_countdown > 0 ? '${_countdown}s' : '获取验证码'),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // 错误提示
                  if (provider.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        provider.errorMessage!,
                        style: TextStyle(color: theme.colorScheme.error, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  const SizedBox(height: 32),

                  // 登录按钮
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: provider.isLoading ? null : () => _onLogin(provider),
                      style: ElevatedButton.styleFrom(
                        shape: const StadiumBorder(),
                        backgroundColor: const Color(0xFF5B9BD5),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFFE0E0E0),
                      ),
                      child: provider.isLoading
                          ? const SizedBox(
                              height: 20, width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('登录', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                    ),
                  ),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
