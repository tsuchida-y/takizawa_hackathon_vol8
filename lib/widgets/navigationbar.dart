import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../screens/settings_screen/location_lite.dart';

/// ナビゲーションのインデックス
enum NavIndex { home, ranking, profile, menu }

/// 現在選択されているナビゲーションインデックスのプロバイダー
final currentNavIndexProvider = StateProvider<NavIndex>((ref) => NavIndex.home);

/// カスタムボトムナビゲーションバー
class CustomBottomNavigationBar extends ConsumerWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(0x4D), // alpha: 0.3
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: currentIndex,
        onTap: onTap,
        backgroundColor: Colors.white,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey.shade400,
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'ホーム',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.leaderboard),
            label: 'ランキング',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.stars),
            label: 'ポイント',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.casino),
            label: 'ガチャ',
          ),
        ],
      ),
    );
  }
}

/// メインナビゲーションスクリーン
class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  NavIndex _currentIndex = NavIndex.home;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildCurrentScreen(),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _currentIndex.index,
        onTap: (index) {
          if (index < NavIndex.values.length) {
            setState(() => _currentIndex = NavIndex.values[index]);
          }
          _handleBottomNavigationTap(context, index);
        },
      ),
    );
  }

  Widget _buildCurrentScreen() {
    // 基本ナビゲーション復元（軽量実装）
    switch (_currentIndex) {
      case NavIndex.home:
        return const HomeScreenLite();
      case NavIndex.ranking:
        return const RankingScreenLite();
      case NavIndex.profile:
        return const ProfileScreenLite();
      case NavIndex.menu:
        return const MenuScreenLite();
    }
  }

  /// ボトムナビゲーションのタップを処理
  void _handleBottomNavigationTap(BuildContext context, int index) {
    // NavIndex.values[index]と_currentIndexが一致する場合、
    // すでに選択されたタブなので何もしない
    if (index < NavIndex.values.length && NavIndex.values[index] != _currentIndex) {
      setState(() => _currentIndex = NavIndex.values[index]);
      
      // 画面遷移時のアニメーション効果が必要な場合はここに追加
    }
  }
}

// 軽量版画面クラス群
class HomeScreenLite extends StatelessWidget {
  const HomeScreenLite({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ホーム'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.home, size: 80, color: Colors.blue),
            SizedBox(height: 20),
            Text(
              'ホーム画面',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text('軽量版で動作中'),
          ],
        ),
      ),
    );
  }
}

class RankingScreenLite extends StatelessWidget {
  const RankingScreenLite({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ランキング'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.leaderboard, size: 80, color: Colors.orange),
            SizedBox(height: 20),
            Text(
              'ランキング画面',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text('軽量版で動作中'),
          ],
        ),
      ),
    );
  }
}

class ProfileScreenLite extends StatelessWidget {
  const ProfileScreenLite({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('プロフィール'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.stars, size: 80, color: Colors.purple),
            SizedBox(height: 20),
            Text(
              'プロフィール画面',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text('軽量版で動作中'),
          ],
        ),
      ),
    );
  }
}

class MenuScreenLite extends StatelessWidget {
  const MenuScreenLite({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('メニュー'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            const Icon(Icons.casino, size: 80, color: Colors.green),
            const SizedBox(height: 20),
            const Text(
              'メニュー画面',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              '軽量版で動作中',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            
            // 位置情報設定ボタン
            Card(
              child: ListTile(
                leading: const Icon(Icons.location_on, color: Colors.blue),
                title: const Text('位置情報設定（軽量版）'),
                subtitle: const Text('GPS機能をテスト'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LocationScreenLite(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}