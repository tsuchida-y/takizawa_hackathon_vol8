import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:takizawa_hackathon_vol8/pointget.dart'; // 削除済み
import 'package:takizawa_hackathon_vol8/screens/ranking.dart';
import 'package:takizawa_hackathon_vol8/screens/profile.dart';
import 'package:takizawa_hackathon_vol8/screens/gacha.dart';

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
    switch (_currentIndex) {
      case NavIndex.home:
        return const ProfileScreen(); // ホーム画面としてプロフィール画面を使用
      case NavIndex.ranking:
        return const RankingScreen();
      case NavIndex.profile:
        return const Center(child: Text('ポイント獲得画面\n（未実装）', style: TextStyle(fontSize: 18))); // プレースホルダー
      case NavIndex.menu:
        return const GachaScreen();
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