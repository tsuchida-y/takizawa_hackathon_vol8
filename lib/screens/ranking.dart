import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:takizawa_hackathon_vol8/widgets/setting_button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  final String userId;

  const RankingItem({
    required this.rank,
    required this.name,
    required this.score,
    required this.avatarUrl,
    this.isCurrentUser = false,
    required this.userId,
  });

  /// テスト用のサンプルデータを生成
  static List<RankingItem> generateSampleData({int count = 10}) {
    return List.generate(count, (index) {
      return RankingItem(
        rank: index + 1,
        name: 'ユーザー${index + 1}',
        score: (1000 - index * 50) + (index * 10),
        avatarUrl:
            'https://api.dicebear.com/7.x/avataaars/svg?seed=user${index + 1}',
        userId: 'user${index + 1}',
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
        userId: '1', // 現在のユーザーIDを固定値「1」に設定
      );
    }
    return items;
  }

  /// Firestoreドキュメントからランキング項目を生成
  factory RankingItem.fromFirestore(DocumentSnapshot doc, int rank, bool isCurrentUser, String? nickname, String pointField) {
    final data = doc.data() as Map<String, dynamic>;
    return RankingItem(
      rank: rank,
      name: nickname ?? '未設定',
      score: data[pointField] ?? 0, // 期間に応じたポイントフィールドを使用
      avatarUrl: 'https://api.dicebear.com/7.x/avataaars/svg?seed=${doc.id}',
      isCurrentUser: isCurrentUser,
      userId: doc.id,
    );
  }
}

/// ランキング表示期間の種類
enum RankingPeriod {
  day('日', 'daily'),
  month('月', 'monthly'),
  year('年', 'yearly'),
  custom('カスタム', 'custom');

  const RankingPeriod(this.label, this.value);

  final String label;
  final String value;
}

/// カスタム期間のデータモデル
class CustomPeriod {
  final DateTime startDate;
  final DateTime endDate;

  const CustomPeriod({required this.startDate, required this.endDate});

  String get displayText {
    final start =
        '${startDate.year}/${startDate.month.toString().padLeft(2, '0')}/${startDate.day.toString().padLeft(2, '0')}';
    final end =
        '${endDate.year}/${endDate.month.toString().padLeft(2, '0')}/${endDate.day.toString().padLeft(2, '0')}';
    return '$start ~ $end';
  }
}

// ===== プロバイダー =====
//TODO: プロバイダーは別ファイルで管理した方が良さそう

/// 現在選択されている期間のプロバイダー
final selectedPeriodProvider = StateProvider<RankingPeriod>((ref) {
  return RankingPeriod.day; // デフォルトは「日」
});

/// カスタム期間のプロバイダー
final customPeriodProvider = StateProvider<CustomPeriod?>((ref) {
  return null;
});

/// ランキングデータのプロバイダー
final rankingDataProvider = FutureProvider<List<RankingItem>>((ref) async {
  final selectedPeriod = ref.watch(selectedPeriodProvider);
  
  // Firestoreからデータを取得
  final firestore = FirebaseFirestore.instance;
  final pointCollection = firestore.collection('point');
  final usersCollection = firestore.collection('users');
  
  // 現在のユーザーID
  const String currentUserId = '1';
  
  // 期間に応じたフィールドを取得
  String pointField;
  switch (selectedPeriod) {
    case RankingPeriod.day:
      pointField = 'dayPoint';
      break;
    case RankingPeriod.month:
      pointField = 'monthPoint';
      break;
    case RankingPeriod.year:
      pointField = 'yearPoint';
      break;
    case RankingPeriod.custom:
      // カスタム期間の場合はとりあえず合計ポイントを使用
      pointField = 'totalPoint';
      break;
  }
  
  // ポイントでソートされたクエリを実行
  final snapshot = await pointCollection.orderBy(pointField, descending: true).get();
  final pointDocs = snapshot.docs;
  
  // ユーザーIDのリストを抽出
  final userIds = pointDocs.map((doc) => doc.id).toList();
  
  // ユーザー情報をマップに格納
  final userNicknames = <String, String>{};
  
  // ユーザー情報を一括で取得（バッチ処理）
  if (userIds.isNotEmpty) {
    try {
      // 全てのユーザードキュメントを一度に取得
      final userSnapshot = await usersCollection.get();
      final allUserDocs = userSnapshot.docs;
      
      // ユーザーIDとニックネームのマップを作成
      for (final userDoc in allUserDocs) {
        if (userIds.contains(userDoc.id)) {
          final userData = userDoc.data();
          if (userData.containsKey('nickname')) {
            userNicknames[userDoc.id] = userData['nickname'] as String;
          }
        }
      }
    } catch (e) {
      debugPrint('ユーザー情報の一括取得に失敗: $e');
    }
  }
  
  // ランキング項目リストに変換
  final items = <RankingItem>[];
  for (int i = 0; i < pointDocs.length; i++) {
    final doc = pointDocs[i];
    final isCurrentUser = doc.id == currentUserId;
    
    // ユーザー情報からニックネームを取得
    final nickname = userNicknames[doc.id];
    
    items.add(RankingItem.fromFirestore(doc, i + 1, isCurrentUser, nickname, pointField));
  }
  
  return items;
});

/// 実際のユーザー情報を含むランキングデータを生成
List<RankingItem> _generateRankingDataWithRealUser(
    UserProfile userProfile, {
    required int count,
    required int baseScore,
    RankingPeriod period = RankingPeriod.day,
  }) {
  // ダミーユーザーデータを生成
  final dummyUsers = List.generate(count - 1, (index) {
    return RankingItem(
      rank: index + 1,
      name: 'TSU${(100000 + index * 12345).toString().substring(0, 6)}', // TSU + 6桁の数字
      score: (1000 - index * 50) + (index * 10) + baseScore,
      avatarUrl: 'https://api.dicebear.com/7.x/avataaars/svg?seed=user${index + 1}',
      isCurrentUser: false, userId: '',
    );
  });
  
  // ユーザーの期間に応じたポイントを決定
  int userPoints;
  switch (period) {
    case RankingPeriod.day:
      // 日間ポイント (ここでは例としてtotalPointsの1/30を使用)
      userPoints = (userProfile.totalPoints / 30).round();
      break;
    case RankingPeriod.month:
      // 月間ポイント (ここでは例としてtotalPointsの1/2を使用)
      userPoints = (userProfile.totalPoints / 2).round();
      break;
    case RankingPeriod.year:
      // 年間ポイント (totalPointsをそのまま使用)
      userPoints = userProfile.totalPoints;
      break;
    default:
      userPoints = userProfile.totalPoints;
  }
  
  // 実際のユーザーを追加（中位に配置）
  final currentUserItem = RankingItem(
    rank: count ~/ 2, // 中位に配置
    name: userProfile.displayName,
    score: userPoints + baseScore,
    avatarUrl: userProfile.avatarUrl,
    isCurrentUser: true, userId: '',
  );
  
  // リストに追加
  final items = [...dummyUsers, currentUserItem];
  
  return items;
}

/// 現在のユーザーのランキング情報を取得するプロバイダー
final currentUserRankingProvider = Provider<AsyncValue<RankingItem?>>((ref) {
  final rankingDataAsync = ref.watch(rankingDataProvider);
  
  return rankingDataAsync.whenData((rankingData) {
    try {
      return rankingData.firstWhere((item) => item.isCurrentUser);
    } catch (e) {
      return null;
    }
  });
});

/// トップランキング（上位10位）のプロバイダー
final topRankingProvider = Provider<AsyncValue<List<RankingItem>>>((ref) {
  final rankingDataAsync = ref.watch(rankingDataProvider);
  
  return rankingDataAsync.whenData((rankingData) {
    return rankingData.take(10).toList();
  });
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
                      fontWeight: isHighlighted
                          ? FontWeight.bold
                          : FontWeight.w500,
                      color: isHighlighted
                          ? Theme.of(context).primaryColor
                          : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item.score}ポイント',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
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
        rankWidget = const Icon(
          Icons.emoji_events,
          color: Colors.white,
          size: 20,
        );
        break;
      case 2:
        rankColor = const Color(0xFFC0C0C0); // 銀色
        rankWidget = const Icon(
          Icons.emoji_events,
          color: Colors.white,
          size: 20,
        );
        break;
      case 3:
        rankColor = const Color(0xFFCD7F32); // 銅色
        rankWidget = const Icon(
          Icons.emoji_events,
          color: Colors.white,
          size: 20,
        );
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
      decoration: BoxDecoration(color: rankColor, shape: BoxShape.circle),
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
          color: isHighlighted ? Colors.blue : Colors.grey.shade400,
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
            return Icon(Icons.person, size: 30, color: Colors.grey.shade600);
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
    final customPeriod = ref.watch(customPeriodProvider);

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
                if (period == RankingPeriod.custom) {
                  _showCustomPeriodDialog(context, ref);
                } else {
                  ref.read(selectedPeriodProvider.notifier).state = period;
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.all(4),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Theme.of(
                              context,
                            ).primaryColor.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  period == RankingPeriod.custom && customPeriod != null
                      ? 'カスタム'
                      : period.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey.shade600,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// カスタム期間選択ダイアログを表示
  void _showCustomPeriodDialog(BuildContext context, WidgetRef ref) {
    DateTime? startDate;
    DateTime? endDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('カスタム期間選択'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(
                  '開始日: ${startDate?.toString().split(' ')[0] ?? '未選択'}',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().subtract(
                      const Duration(days: 30),
                    ),
                    firstDate: DateTime.now().subtract(
                      const Duration(days: 365),
                    ),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() {
                      startDate = date;
                    });
                  }
                },
              ),
              ListTile(
                title: Text(
                  '終了日: ${endDate?.toString().split(' ')[0] ?? '未選択'}',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate:
                        startDate ??
                        DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() {
                      endDate = date;
                    });
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: startDate != null && endDate != null
                  ? () {
                      ref
                          .read(customPeriodProvider.notifier)
                          .state = CustomPeriod(
                        startDate: startDate!,
                        endDate: endDate!,
                      );
                      ref.read(selectedPeriodProvider.notifier).state =
                          RankingPeriod.custom;
                      Navigator.of(context).pop();
                    }
                  : null,
              child: const Text('適用'),
            ),
          ],
        ),
      ),
    );
  }
}

/// 現在のユーザーのランキングを表示するウィジェット（フッター上部固定）
class CurrentUserRankingFooter extends ConsumerWidget {
  const CurrentUserRankingFooter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserRankingAsync = ref.watch(currentUserRankingProvider);

    return currentUserRankingAsync.when(
      data: (currentUserRanking) {
        if (currentUserRanking == null) {
          return const SizedBox.shrink();
        }

        return Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(1), // 75%の背景透過率
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    Text(
                      'あなたのランキング',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: RankingCard(item: currentUserRanking, isHighlighted: true),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stackTrace) => const SizedBox.shrink(),
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
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'ホーム'),
          BottomNavigationBarItem(
            icon: Icon(Icons.leaderboard),
            label: 'ランキング',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'プロフィール'),
          BottomNavigationBarItem(icon: Icon(Icons.menu), label: 'メニュー'),
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
    final topRankingAsync = ref.watch(topRankingProvider);
    final selectedPeriod = ref.watch(selectedPeriodProvider);
    final customPeriod = ref.watch(customPeriodProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'ランキング',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [const SettingsButton()],
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () async {
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
                        if (selectedPeriod == RankingPeriod.custom &&
                            customPeriod != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Text(
                              customPeriod.displayText,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),

                // ランキングヘッダー
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selectedPeriod == RankingPeriod.custom
                              ? 'カスタム期間ランキング'
                              : '${selectedPeriod.label}間ランキング',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getPeriodDisplayText(selectedPeriod, customPeriod),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ランキングリスト
                topRankingAsync.when(
                  data: (topRankingData) => SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = topRankingData[index];
                        return RankingCard(
                          item: item,
                          isHighlighted: item.isCurrentUser, // 自分のランキングは強調表示
                        );
                      },
                      childCount: topRankingData.length,
                    ),
                  ),
                  loading: () => const SliverToBoxAdapter(
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (error, stackTrace) => SliverToBoxAdapter(
                    child: Center(
                      child: Text('エラーが発生しました: $error'),
                    ),
                  ),
                ),

                // 下部余白（フッター分）
                const SliverToBoxAdapter(
                  child: SizedBox(height: 180), // フッターとボトムナビ分の余白
                ),
              ],
            ),
          ),

          // フッター上部に固定された現在ユーザーランキング
          Positioned(
            left: 0,
            right: 0,
            bottom: 8, // ボトムナビゲーションバーとの余白を最小限に
            child: const CurrentUserRankingFooter(),
          ),
        ],
      ),
    );
  }

  /// 期間の詳細表示テキストを取得
  String _getPeriodDisplayText(
    RankingPeriod period,
    CustomPeriod? customPeriod,
  ) {
    final now = DateTime.now();

    switch (period) {
      case RankingPeriod.day:
        return '${now.year}年${now.month}月${now.day}日';
      case RankingPeriod.month:
        return '${now.year}年${now.month}月';
      case RankingPeriod.year:
        return '${now.year}年';
      case RankingPeriod.custom:
        return customPeriod?.displayText ?? 'カスタム期間';
    }
  }
}
