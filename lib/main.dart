import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'widgets/navigationbar.dart';
import 'service/notification_service.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Android最適化：段階的初期化（Step 5: Firebase Core追加）
  if (!kIsWeb) {
    debugPrint('Android軽量モードで起動...');
    
    try {
      // Firebase初期化（軽量）
      debugPrint('Firebase初期化開始...');
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint('Firebase初期化完了');
    } catch (e) {
      debugPrint('Firebase初期化エラー（続行）: $e');
      // エラーでも続行（Firebase無しでも動作）
    }
  }

    // 通知サービスを初期化
  final notificationService = NotificationService();
  await notificationService.initialize();
  await notificationService.createNotificationChannels();
  
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '地域ポイントアプリ',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MainNavigationScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
