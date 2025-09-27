import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'pointget.dart';
import 'gacha.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '地域ポイントアプリ',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
      ),
      home: const MainNavigationScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

/// ボトムナビゲーションのインデックス
enum NavIndex { home, ranking, pointGet, gacha }

/// 共通ヘッダーウィジェット
class CommonHeader extends ConsumerWidget {
  final String title;
  final bool showPoints;

  const CommonHeader({super.key, required this.title, this.showPoints = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pointState = ref.watch(pointProvider);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          if (showPoints) ...[
            Text(
              '${pointState.currentPoints}pt',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.blue,
              ),
            ),
          ],
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            onPressed: () => _showSettingsDialog(context),
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('設定'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(leading: Icon(Icons.account_circle), title: Text('アカウント')),
            ListTile(leading: Icon(Icons.notifications), title: Text('通知')),
            ListTile(leading: Icon(Icons.help), title: Text('ヘルプ')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }
}

/// 共通ボトムナビゲーションウィジェット
class CommonBottomNavigation extends StatelessWidget {
  final NavIndex currentIndex;
  final Function(NavIndex) onTap;

  const CommonBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Icons.home,
                label: 'ホーム',
                index: NavIndex.home,
                isSelected: currentIndex == NavIndex.home,
              ),
              _buildNavItem(
                icon: Icons.leaderboard,
                label: 'ランキング',
                index: NavIndex.ranking,
                isSelected: currentIndex == NavIndex.ranking,
              ),
              _buildNavItem(
                icon: Icons.stars,
                label: 'ポイント',
                index: NavIndex.pointGet,
                isSelected: currentIndex == NavIndex.pointGet,
              ),
              _buildNavItem(
                icon: Icons.casino,
                label: 'ガチャ',
                index: NavIndex.gacha,
                isSelected: currentIndex == NavIndex.gacha,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required NavIndex index,
    required bool isSelected,
  }) {
    // ホームとランキングは無効化
    final isDisabled = index == NavIndex.home || index == NavIndex.ranking;

    return GestureDetector(
      onTap: isDisabled ? null : () => onTap(index),
      child: Opacity(
        opacity: isDisabled ? 0.5 : 1.0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isSelected ? Colors.blue : Colors.grey, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.blue : Colors.grey,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// メインナビゲーションスクリーン
class MainNavigationScreen extends ConsumerStatefulWidget {
  final NavIndex initialIndex;

  const MainNavigationScreen({
    super.key,
    this.initialIndex = NavIndex.pointGet,
  });

  @override
  ConsumerState<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  late NavIndex _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildCurrentScreen(),
      bottomNavigationBar: CommonBottomNavigation(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }

  Widget _buildCurrentScreen() {
    switch (_currentIndex) {
      case NavIndex.home:
        return const HomeScreen();
      case NavIndex.ranking:
        return const RankingScreen();
      case NavIndex.pointGet:
        return const PointGetScreen();
      case NavIndex.gacha:
        return const GachaScreen();
    }
  }
}

/// ホーム画面（プロフィール画面）
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pointState = ref.watch(pointProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            // ヘッダー
            const CommonHeader(title: 'Info'),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // プロフィール画像
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.person,
                        size: 60,
                        color: Colors.grey.shade600,
                      ),
                    ),

                    const SizedBox(height: 40),

                    // 現在のポイント表示
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Pt',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '${pointState.currentPoints}',
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ランキング画面
class RankingScreen extends ConsumerWidget {
  const RankingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            // ヘッダー
            const CommonHeader(title: 'ランキング'),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // ランキングリスト
                    Expanded(
                      child: ListView.builder(
                        itemCount: 10,
                        itemBuilder: (context, index) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                // 順位
                                Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: index < 3
                                        ? Colors.orange
                                        : Colors.grey.shade300,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${index + 1}',
                                      style: TextStyle(
                                        color: index < 3
                                            ? Colors.white
                                            : Colors.black,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // プロフィール画像
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade300,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.person,
                                    color: Colors.grey.shade600,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // 名前とポイント
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'ユーザー${index + 1}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        '${(1000 - index * 50)}pt',
                                        style: TextStyle(
                                          color: Colors.blue.shade600,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
