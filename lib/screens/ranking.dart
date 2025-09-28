import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:takizawa_hackathon_vol8/widgets/setting_button.dart';
import 'package:takizawa_hackathon_vol8/providers/user_profile_provider.dart';
import 'dart:io';

// ===== データモデル =====

/// ランキング項目のデータモデル
class RankingItem {
  final int rank;
  final String name;
  final int score;
  final String avatarUrl;
  final bool isCurrentUser;

  const RankingItem({
    required this.rank,
    required this.name,
    required this.score,
    required this.avatarUrl,
    this.isCurrentUser = false,
  });

  /// テスト用のサンプルデータを生成
  static List<RankingItem> generateSampleData({int count = 10}) {
    return List.generate(count, (index) {
      return RankingItem(
        rank: index + 1,
        name: 'ユーザー${index + 1}',
        score: (1000 - index * 50) + (index * 10),
        avatarUrl: 'https://api.dicebear.com/7.x/avataaars/svg?seed=user${index + 1}',
      );
    });
  }

  /// 現在のユーザーを含むサンプルデータを生成
  static List<RankingItem> generateSampleDataWithCurrentUser({int count = 10}) {
    final items = generateSampleData(count: count);
    // 5位に現在のユーザーを配置
    final currentUserIndex = 4;
    if (items.length > currentUserIndex) {
      items[currentUserIndex] = RankingItem(
        rank: currentUserIndex + 1,
        name: 'あなた',
        score: items[currentUserIndex].score,
        avatarUrl: items[currentUserIndex].avatarUrl,
        isCurrentUser: true,
      );
    }
    return items;
  }
}

/// ランキング表示期間の種類
enum RankingPeriod {
  day('日', 'daily'),
  month('月', 'monthly'),
  year('年', 'yearly');

  const RankingPeriod(this.label, this.value);

  final String label;
  final String value;
}

// ===== プロバイダー =====
//TODO: プロバイダーは別ファイルで管理した方が良さそう

/// 現在選択されている期間のプロバイダー
final selectedPeriodProvider = StateProvider<RankingPeriod>((ref) {
  return RankingPeriod.day; // デフォルトは「日」
});

/// ランキングデータのプロバイダー
final rankingDataProvider = Provider.family<List<RankingItem>, RankingPeriod>((ref, period) {
  // 実際のユーザープロフィールを取得
  final userProfile = ref.watch(sharedUserProfileProvider);
  
  // 実際のアプリケーションでは、ここでAPIからデータを取得する
  // 今回はダミーデータを使用
  List<RankingItem> items;
  
  //現在はタブを切り替えるたびにデータを生成している
  //TODO: 本番ではキャッシュするなどの工夫をする
  switch (period) {
    case RankingPeriod.day:
      items = _generateRankingDataWithRealUser(userProfile, count: 15, baseScore: 0);
      break;
    case RankingPeriod.month:
      items = _generateRankingDataWithRealUser(userProfile, count: 12, baseScore: 200);
      break;
    case RankingPeriod.year:
      items = _generateRankingDataWithRealUser(userProfile, count: 20, baseScore: 500);
      break;
  }
  
  // スコア順でソートしてランクを再計算
  // TODO:キャッシュの利用の検討やソートが効率的かを検証する
  items.sort((a, b) => b.score.compareTo(a.score));
  for (int i = 0; i < items.length; i++) {
    items[i] = RankingItem(
      rank: i + 1,
      name: items[i].name,
      score: items[i].score,
      avatarUrl: items[i].avatarUrl,
      isCurrentUser: items[i].isCurrentUser,
    );
  }
  
  return items;
});

/// 実際のユーザー情報を含むランキングデータを生成
List<RankingItem> _generateRankingDataWithRealUser(UserProfile userProfile, {required int count, required int baseScore}) {
  // ダミーユーザーデータを生成
  final dummyUsers = List.generate(count - 1, (index) {
    return RankingItem(
      rank: index + 1,
      name: 'TSU${(100000 + index * 12345).toString().substring(0, 6)}', // TSU + 6桁の数字
      score: (1000 - index * 50) + (index * 10) + baseScore,
      avatarUrl: 'https://api.dicebear.com/7.x/avataaars/svg?seed=user${index + 1}',
      isCurrentUser: false,
    );
  });
  
  // 実際のユーザーを追加（中位に配置）
  final currentUserItem = RankingItem(
    rank: count ~/ 2, // 中位に配置
    name: userProfile.displayName,
    score: userProfile.totalPoints + baseScore,
    avatarUrl: userProfile.avatarUrl,
    isCurrentUser: true,
  );
  
  // リストに追加
  final items = [...dummyUsers, currentUserItem];
  
  return items;
}

/// 現在のユーザーのランキング情報を取得するプロバイダー
final currentUserRankingProvider = Provider<RankingItem?>((ref) {
  final selectedPeriod = ref.watch(selectedPeriodProvider);
  final rankingData = ref.watch(rankingDataProvider(selectedPeriod));
  
  try {
    return rankingData.firstWhere((item) => item.isCurrentUser);
  } catch (e) {
    return null;
  }
});

/// トップランキング（上位10位）のプロバイダー
final topRankingProvider = Provider<List<RankingItem>>((ref) {
  final selectedPeriod = ref.watch(selectedPeriodProvider);  
  final rankingData = ref.watch(rankingDataProvider(selectedPeriod));
  
  return rankingData.take(10).toList();
});

// ===== ウィジェット =====

/// ランキングアイテムを表示するカードウィジェット
class RankingCard extends StatelessWidget {
  final RankingItem item;
  final bool isHighlighted; // 現在のユーザーを強調表示するかどうか

  const RankingCard({
    super.key,
    required this.item,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),

      //自身のカードのみを強調表示する
      decoration: BoxDecoration(
        color: isHighlighted 
          ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
          : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isHighlighted 
          ? Border.all(color: Theme.of(context).primaryColor, width: 2)
          : Border.all(color: Colors.grey.shade300),
        boxShadow: [
          if (isHighlighted)
            BoxShadow(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          else
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // ランク表示
            _buildRankWidget(),
            const SizedBox(width: 16),
            
            // アバター
            _buildAvatar(),
            const SizedBox(width: 16),
            
            // 名前とスコア
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w500,
                      color: isHighlighted 
                        ? Theme.of(context).primaryColor 
                        : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item.score}ポイント',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ランク表示ウィジェット
  /// 順位によってアバターの色やアイコンを変える
  Widget _buildRankWidget() {
    Color rankColor;
    Widget rankWidget;
    
    switch (item.rank) {
      case 1:
        rankColor = const Color(0xFFFFD700); // 金色
        rankWidget = const Icon(Icons.emoji_events, color: Colors.white, size: 20);
        break;
      case 2:
        rankColor = const Color(0xFFC0C0C0); // 銀色
        rankWidget = const Icon(Icons.emoji_events, color: Colors.white, size: 20);
        break;
      case 3:
        rankColor = const Color(0xFFCD7F32); // 銅色
        rankWidget = const Icon(Icons.emoji_events, color: Colors.white, size: 20);
        break;
      default:
        rankColor = Colors.grey.shade400;
        rankWidget = Text(
          '${item.rank}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        );
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: rankColor,
        shape: BoxShape.circle,
      ),
      child: Center(child: rankWidget),
    );
  }

  /// アバター表示ウィジェット
  Widget _buildAvatar() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey.shade300,
        border: Border.all(
          color: isHighlighted 
            ? Colors.blue
            : Colors.grey.shade400,
          width: 2,
        ),
      ),
      child: ClipOval(
        child: _buildAvatarImage(),
      ),
    );
  }

  /// アバター画像を構築
  Widget _buildAvatarImage() {
    // 現在のユーザーでファイルパスがある場合
    if (item.isCurrentUser && item.avatarUrl.startsWith('/')) {
      final file = File(item.avatarUrl);
      if (file.existsSync()) {
        return Image.file(
          file,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildDefaultAvatar();
          },
        );
      }
    }
    
    // ネットワーク画像またはデフォルト
    return Image.network(
      item.avatarUrl,
      width: 50,
      height: 50,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return _buildDefaultAvatar();
      },
    );
  }

  /// デフォルトアバター
  Widget _buildDefaultAvatar() {
    return Icon(
      Icons.person,
      size: 30,
      color: Colors.grey.shade600,
    );
  }
}

/// 期間選択タブウィジェット
class PeriodSelectionTabs extends ConsumerWidget {
  const PeriodSelectionTabs({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedPeriod = ref.watch(selectedPeriodProvider);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: RankingPeriod.values.map((period) {
          final isSelected = period == selectedPeriod;
          
          return Expanded(
            child: GestureDetector(
              onTap: () {
                ref.read(selectedPeriodProvider.notifier).state = period;
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.all(4),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: isSelected ? [
                    BoxShadow(
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ] : null,
                ),
                child: Text(
                  period.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey.shade600,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// 現在のユーザーのランキングを表示するウィジェット
class CurrentUserRanking extends ConsumerWidget {
  const CurrentUserRanking({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserRanking = ref.watch(currentUserRankingProvider);
    
    if (currentUserRanking == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 16, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'あなたのランキング',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          const SizedBox(height: 8),
          RankingCard(
            item: currentUserRanking,
            isHighlighted: true,
          ),
        ],
      ),
    );
  }
}

/// カスタムボトムナビゲーションバー
class CustomBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.3),
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
            icon: Icon(Icons.person),
            label: 'プロフィール',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu),
            label: 'メニュー',
          ),
        ],
      ),
    );
  }
}

/// ランキング画面
class RankingScreen extends ConsumerWidget {
  const RankingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topRanking = ref.watch(topRankingProvider);
    final selectedPeriod = ref.watch(selectedPeriodProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'ランキング',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          const SettingsButton(),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // 実際のアプリでは、ここでAPIからデータを再取得
          ref.invalidate(rankingDataProvider);
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: CustomScrollView(
          slivers: [
            // 期間選択タブ
            SliverToBoxAdapter(
              child: Container(
                color: Colors.white,
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    const PeriodSelectionTabs(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            
            // ランキングヘッダー
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '${selectedPeriod.label}間ランキング',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
            
            // ランキングリスト
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = topRanking[index];
                  return RankingCard(
                    item: item,
                    isHighlighted: item.isCurrentUser,
                  );
                },
                childCount: topRanking.length,
              ),
            ),
            
            // 現在のユーザーのランキング
            const SliverToBoxAdapter(
              child: CurrentUserRanking(),
            ),
            
            // 下部余白
            const SliverToBoxAdapter(
              child: SizedBox(height: 100), // ボトムナビゲーション分の余白
            ),
          ],
        ),
      ),
      // 共通のナビゲーションバーはMainNavigationScreenで管理するため削除
    );
  }
}