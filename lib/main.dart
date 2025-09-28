import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'widgets/navigationbar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Android最適化：重い初期化を段階的に無効化
  if (!kIsWeb) {
    // とりあえず全ての重い処理をスキップ
    debugPrint('Android軽量モードで起動...');
  }
  
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
