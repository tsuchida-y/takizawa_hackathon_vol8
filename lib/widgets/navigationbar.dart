import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../screens/settings_screen/location.dart';
import '../screens/pointget.dart';
import '../screens/ranking.dart';
import '../screens/profile.dart';
import '../screens/gacha.dart';
import '../service/firebase_service_lite.dart';

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
    // 元のUI画面に復元
    switch (_currentIndex) {
      case NavIndex.home:
        return const PointGetScreen();
      case NavIndex.ranking:
        return const RankingScreen();
      case NavIndex.profile:
        return const ProfileScreen();
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

// 元のUI画面に復元（軽量版クラス削除）





class MenuScreenLite extends StatelessWidget {
  const MenuScreenLite({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        foregroundColor: Colors.black87,
      ),
      backgroundColor: Colors.grey[50],
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 位置情報設定カード
            Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: Colors.grey.shade200,
                  width: 1,
                ),
              ),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LocationScreen(),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // アイコン部分
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.location_on_outlined,
                          color: Colors.blue.shade600,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      
                      // テキスト部分
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '位置情報',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'GPS・位置情報設定',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // 矢印アイコン
                      Icon(
                        Icons.chevron_right,
                        color: Colors.grey.shade400,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Firebase状態表示
            Consumer(
              builder: (context, ref, child) {
                final firebaseInfo = ref.watch(firebaseConnectionInfoProvider);
                final status = firebaseInfo['status'] as String;
                
                return Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: Colors.grey.shade200,
                      width: 1,
                    ),
                  ),
                  child: InkWell(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Firebase接続情報'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('状態: ${firebaseInfo['status']}'),
                              Text('メッセージ: ${firebaseInfo['message']}'),
                              if (firebaseInfo['project_id'] != null)
                                Text('プロジェクトID: ${firebaseInfo['project_id']}'),
                              Text('アプリ数: ${firebaseInfo['apps_count']}'),
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
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          // アイコン部分
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: status == 'connected' ? Colors.green.shade50 : 
                                     status == 'error' ? Colors.red.shade50 : Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              status == 'connected' ? Icons.cloud_done : 
                              status == 'error' ? Icons.cloud_off : Icons.cloud_outlined,
                              color: status == 'connected' ? Colors.green.shade600 : 
                                     status == 'error' ? Colors.red.shade600 : Colors.orange.shade600,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          
                          // テキスト部分
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Firebase状態',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  firebaseInfo['message'] as String,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // ステータスアイコン
                          Icon(
                            status == 'connected' ? Icons.check_circle : Icons.info_outline,
                            color: status == 'connected' ? Colors.green : Colors.grey.shade400,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}