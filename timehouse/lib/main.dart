import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'src/routes/app_router.dart';
import 'src/providers/user_provider.dart';
import 'src/providers/photo_provider.dart';
import 'src/providers/family_provider.dart';
import 'src/services/storage_service.dart';
import 'src/services/api_service.dart';

// 编译时环境配置 — 通过 --dart-define 注入
class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000/api/v1',
  );
  static const String environment = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'development',
  );
  static bool get isProduction => environment == 'production';
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.init();
  // 尽早初始化 ApiService
  ApiService();
  initAppRouter(); // 初始化路由
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => PhotoProvider()),
        ChangeNotifierProvider(create: (_) => FamilyProvider(ApiService())),
      ],
      child: Builder(builder: (context) {
        // debugPrint removed for production — API URL was logged in plaintext
        // 检查登录状态，延迟执行以避免构建过程中调用
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final userProvider = context.read<UserProvider>();
          userProvider.checkLoginStatus();
        });
        
        return MaterialApp.router(
          title: '拾光家',
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF5B9BD5), // 天蓝 — 轻快、温暖
              brightness: Brightness.light,
            ),
            // 全局圆角
            cardTheme: CardThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            ),
            // 输入框圆角
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: const Color(0xFFF3F3F1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFF3B6F5A), width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            // 按钮圆角
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: const Color(0xFF5B9BD5),
                foregroundColor: Colors.white,
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            // AppBar
            appBarTheme: const AppBarTheme(
              elevation: 0,
              scrolledUnderElevation: 0,
              centerTitle: false,
              titleTextStyle: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A1A),
              ),
            ),
            // 底部导航
            navigationBarTheme: NavigationBarThemeData(
              elevation: 0,
              indicatorShape: const StadiumBorder(),
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            ),
            // 字体
            textTheme: const TextTheme(
              headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.5),
              headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
              bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: Color(0xFF8E8E93)),
            ),
            scaffoldBackgroundColor: const Color(0xFFFAFAF8),
          ),
          routerConfig: appRouter,
        );
      }),
    );
  }
}
