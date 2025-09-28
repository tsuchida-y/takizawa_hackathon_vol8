import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:takizawa_hackathon_vol8/widgets/setting_button.dart'; // 削除済み

// ===== データモデル =====

/// イベント情報のデータモデル
class EventInfo {
  final String title;
  final String description;
  final String date;
  final String location;
  final Color color;

  const EventInfo({
    required this.title,
    required this.description,
    required this.date,
    required this.location,
    required this.color,
  });

  /// サンプルイベントデータを生成
  static List<EventInfo> generateSampleEvents() {
    return [
      const EventInfo(
        title: 'ハッカソン Vol.8',
        description: 'モバイルアプリ開発ハッカソン',
        date: '2025/01/15',
        location: 'Tokyo Tech Hub',
        color: Colors.blue,
      ),
      const EventInfo(
        title: 'プログラミング勉強会',
        description: 'Flutter開発の基礎から応用まで',
        date: '2025/01/20',
        location: 'オンライン',
        color: Colors.green,
      ),
      const EventInfo(
        title: 'テックカンファレンス',
        description: '最新技術トレンドの紹介',
        date: '2025/02/05',
        location: 'Shibuya Sky',
        color: Colors.purple,
      ),
      const EventInfo(
        title: 'アプリコンテスト',
        description: '学生向けアプリ開発コンテスト',
        date: '2025/02/12',
        location: 'Akihabara Center',
        color: Colors.orange,
      ),
    ];
  }
}

/// ヒートマップデータのモデル
class HeatmapData {
  final DateTime date;
  final int points;
  final int level; // 0-4のレベル（色の濃さ）

  const HeatmapData({
    required this.date,
    required this.points,
    required this.level,
  });

  /// サンプルヒートマップデータを生成（過去複数年分）
  static List<HeatmapData> generateSampleHeatmapData() {
    final List<HeatmapData> data = [];
    final now = DateTime.now();
    
    // 過去6年分のデータを生成（遡り機能に対応）
    final startDate = now.subtract(const Duration(days: 365 * 6));

    for (int i = 0; i < 365 * 6; i++) {
      final date = startDate.add(Duration(days: i));
      final points = _generateRandomPoints();
      final level = _calculateLevel(points);
      
      data.add(HeatmapData(
        date: date,
        points: points,
        level: level,
      ));
    }
    
    return data;
  }

static int _generateRandomPoints() {
  final random = math.Random();
  final value = random.nextInt(100);
  
  if (value < 20) return 0;
  if (value < 40) return random.nextInt(5) + 1;      // 1-5
  if (value < 70) return random.nextInt(5) + 5;      // 5-9
  if (value < 90) return random.nextInt(5) + 10;     // 10-14
  return random.nextInt(5) + 15;                     // 15-19
}

  static int _calculateLevel(int points) {
    if (points == 0) return 0;
    if (points < 5) return 1;
    if (points < 10) return 2;
    if (points < 15) return 3;
    return 4;
  }
}

/// ユーザープロフィール情報のモデル
class UserProfile {
  final String name;
  final String avatarUrl;
  final int totalPoints;
  final int currentStreak;
  final int maxStreak;
  final String joinDate;

  const UserProfile({
    required this.name,
    required this.avatarUrl,
    required this.totalPoints,
    required this.currentStreak,
    required this.maxStreak,
    required this.joinDate,
  });

  /// サンプルユーザープロフィールデータ
  static const UserProfile sampleProfile = UserProfile(
    name: 'あなた',
    avatarUrl: 'https://api.dicebear.com/7.x/avataaars/svg?seed=currentuser',
    totalPoints: 2548,
    currentStreak: 12,
    maxStreak: 45,
    joinDate: '2024/03/15',
  );
}

// ===== プロバイダー =====

/// ユーザープロフィールプロバイダー
final userProfileProvider = Provider<UserProfile>((ref) {
  return UserProfile.sampleProfile;
});

/// イベント情報プロバイダー
final eventInfoProvider = Provider<List<EventInfo>>((ref) {
  return EventInfo.generateSampleEvents();
});

/// ヒートマップデータプロバイダー
final heatmapDataProvider = Provider<List<HeatmapData>>((ref) {
  return HeatmapData.generateSampleHeatmapData();
});

/// 選択された期間プロバイダー（ヒートマップ表示用）
final selectedHeatmapPeriodProvider = StateProvider<int>((ref) {
  return 365; // デフォルトは1年間
});

/// ヒートマップの表示開始日のオフセット（遡り機能用）
final heatmapOffsetProvider = StateProvider<int>((ref) {
  return 0; // デフォルトは現在から開始
});

// ===== ウィジェット =====

/// ユーザープロフィール表示ウィジェット
class UserProfileSection extends ConsumerWidget {
  const UserProfileSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // ユーザーアバター
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.blue, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipOval(
              child: Image.network(
                profile.avatarUrl,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey.shade300,
                    child: const Icon(
                      Icons.person,
                      size: 40,
                      color: Colors.grey,
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // ユーザー名
          Text(
            profile.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          
          // 統計情報
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem('総ポイント', '${profile.totalPoints}', Icons.star),
              _buildStatItem('現在の連続', '${profile.currentStreak}日', Icons.local_fire_department),
              _buildStatItem('最長連続', '${profile.maxStreak}日', Icons.emoji_events),
            ],
          ),
        ],
      ),
    );
  }

  /// 統計情報項目を構築
  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.blue,
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}

/// イベント情報表示ウィジェット
class EventInfoSection extends ConsumerWidget {
  const EventInfoSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(eventInfoProvider);
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'イベント情報',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 140,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: events.length,
              itemBuilder: (context, index) {
                final event = events[index];
                return Container(
                  width: 280,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: event.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: event.color.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: event.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            event.date,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        event.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        event.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 12,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              event.location,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// ポイント履歴ヒートマップウィジェット
class PointHistoryHeatmap extends ConsumerWidget {
  const PointHistoryHeatmap({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final heatmapData = ref.watch(heatmapDataProvider);
    final offset = ref.watch(heatmapOffsetProvider);
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ポイント取得履歴',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                Row(
                  children: [
                    // 遡りコントロール（左矢印で過去へ）
                    IconButton(
                      onPressed: offset < 12 ? () { // 12ヶ月前まで遡れる
                        ref.read(heatmapOffsetProvider.notifier).state = offset + 1;
                      } : null,
                      icon: Icon(
                        Icons.chevron_left,
                        color: offset < 12 ? Colors.grey.shade600 : Colors.grey.shade300,
                      ),
                      iconSize: 20,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                    ),
                    Text(
                      _getDisplayPeriodText(offset),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    IconButton(
                      onPressed: offset > 0 ? () {
                        ref.read(heatmapOffsetProvider.notifier).state = offset - 1;
                      } : null,
                      icon: Icon(
                        Icons.chevron_right,
                        color: offset > 0 ? Colors.grey.shade600 : Colors.grey.shade300,
                      ),
                      iconSize: 20,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // ヒートマップグリッド（スクロール可能）
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildHeatmapWithLabels(heatmapData, offset),
          ),
          
          const SizedBox(height: 12),
          
          // ヒートマップの凡例
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '少ない',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade800,
                  ),
                ),
                Row(
                  children: List.generate(5, (index) {
                    return Container(
                      width: 12,
                      height: 12,
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      decoration: BoxDecoration(
                        color: _getHeatmapColor(index),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  }),
                ),
                Text(
                  '多い',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// ラベル付きヒートマップを構築（カレンダー形式）
  Widget _buildHeatmapWithLabels(List<HeatmapData> data, int offset) {
    const double cellSize = 44.0; // カレンダー形式でより大きなセル
    const double cellMargin = 1.0; // マージンを調整
    
    // オフセットを考慮してデータをカレンダー形式で整理
    final organizedData = _organizeDataForCalendar(data, offset);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 曜日ヘッダー
        _buildCalendarWeekdayHeader(cellSize, cellMargin),
        
        const SizedBox(height: 4),
        
        // カレンダーグリッド（縦にスクロール可能）
        SizedBox(
          height: 350, // 高さを大きく
          child: SingleChildScrollView(
            child: _buildCalendarGrid(organizedData, cellSize, cellMargin),
          ),
        ),
      ],
    );
  }



  /// カレンダー形式用のデータ構造
  List<List<HeatmapData?>> _organizeDataForCalendar(List<HeatmapData> data, int monthOffset) {
    final now = DateTime.now();
    
    // 月単位でオフセットを計算
    int targetYear = now.year;
    int targetMonth = now.month - monthOffset;
    
    // 月が0以下になった場合、前年に調整
    while (targetMonth <= 0) {
      targetMonth += 12;
      targetYear -= 1;
    }
    
    // 月が12を超えた場合、翌年に調整
    while (targetMonth > 12) {
      targetMonth -= 12;
      targetYear += 1;
    }
    
    // 指定された年月のカレンダーを生成
    final firstDayOfMonth = DateTime(targetYear, targetMonth, 1);
    final lastDayOfMonth = DateTime(targetYear, targetMonth + 1, 0);
    
    // 月の最初の日が何曜日かを取得（日曜日を0とする）
    final firstWeekday = firstDayOfMonth.weekday % 7;
    
    // カレンダーのグリッドを作成
    final List<List<HeatmapData?>> calendar = [];
    final List<HeatmapData?> currentWeek = List.filled(7, null);
    
    // 月の最初の週の前の空白セルを埋める
    for (int i = 0; i < firstWeekday; i++) {
      final prevDate = firstDayOfMonth.subtract(Duration(days: firstWeekday - i));
      currentWeek[i] = _findDataForDate(data, prevDate);
    }
    
    // 月の日付を追加
    int currentDay = 1;
    for (int weekday = firstWeekday; weekday < 7 && currentDay <= lastDayOfMonth.day; weekday++) {
      final currentDate = DateTime(targetYear, targetMonth, currentDay);
      currentWeek[weekday] = _findDataForDate(data, currentDate);
      currentDay++;
    }
    
    calendar.add(List.from(currentWeek));
    
    // 残りの週を追加
    while (currentDay <= lastDayOfMonth.day) {
      final List<HeatmapData?> week = List.filled(7, null);
      
      for (int weekday = 0; weekday < 7 && currentDay <= lastDayOfMonth.day; weekday++) {
        final currentDate = DateTime(targetYear, targetMonth, currentDay);
        week[weekday] = _findDataForDate(data, currentDate);
        currentDay++;
      }
      
      // 月の最後の週の後の空白セルを埋める
      if (currentDay > lastDayOfMonth.day) {
        for (int weekday = currentDay - lastDayOfMonth.day + (currentDay - 1) % 7; weekday < 7; weekday++) {
          final nextDate = DateTime(targetYear, targetMonth + 1, weekday - ((currentDay - 1) % 7) + 1);
          week[weekday] = _findDataForDate(data, nextDate);
        }
      }
      
      calendar.add(week);
    }
    
    return calendar;
  }

  /// 指定された日付のデータを検索
  HeatmapData? _findDataForDate(List<HeatmapData> data, DateTime targetDate) {
    try {
      return data.firstWhere((item) => 
        item.date.year == targetDate.year &&
        item.date.month == targetDate.month &&
        item.date.day == targetDate.day
      );
    } catch (e) {
      return null;
    }
  }

  /// カレンダー形式の曜日ヘッダーを構築
  Widget _buildCalendarWeekdayHeader(double cellSize, double cellMargin) {
    const weekdays = ['日', '月', '火', '水', '木', '金', '土'];
    const weekdayColors = [
      Colors.red,      // 日曜日
      Colors.black,    // 月曜日
      Colors.black,    // 火曜日
      Colors.black,    // 水曜日
      Colors.black,    // 木曜日
      Colors.black,    // 金曜日
      Colors.blue,     // 土曜日
    ];
    
    return Row(
      children: List.generate(7, (index) {
        return Container(
          width: cellSize + cellMargin * 2, // セルと同じ幅
          height: 40, // 少し高めに
          margin: EdgeInsets.all(cellMargin), // セルと同じマージン
          alignment: Alignment.center,
          child: Text(
            weekdays[index],
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: weekdayColors[index],
            ),
          ),
        );
      }),
    );
  }

  /// カレンダーグリッドを構築
  Widget _buildCalendarGrid(List<List<HeatmapData?>> calendar, double cellSize, double cellMargin) {
    final now = DateTime.now();
    
    return Column(
      children: calendar.map((week) {
        return Row(
          children: List.generate(7, (dayIndex) {
            final cellData = week[dayIndex];
            final isToday = cellData != null && 
                           cellData.date.year == now.year &&
                           cellData.date.month == now.month &&
                           cellData.date.day == now.day;
            
            Color cellColor = Colors.grey.shade200;
            if (cellData != null) {
              cellColor = _getHeatmapColor(cellData.level);
            }
            
            return Container(
              width: cellSize + cellMargin * 2,
              height: cellSize + cellMargin * 2,
              margin: EdgeInsets.all(cellMargin),
              decoration: BoxDecoration(
                color: cellColor,
                borderRadius: BorderRadius.circular(6),
                border: isToday ? Border.all(color: Colors.blue, width: 2) : null,
              ),
              child: cellData != null
                  ? Center(
                      child: Text(
                        '${cellData.date.day}',
                        style: TextStyle(
                          fontSize: 16, // フォントサイズを大きく
                          fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                          color: cellData.level > 2 ? Colors.white : Colors.black87,
                        ),
                      ),
                    )
                  : null,
            );
          }),
        );
      }).toList(),
    );
  }





  /// 表示期間のテキストを取得
  String _getDisplayPeriodText(int monthOffset) {
    final now = DateTime.now();
    
    if (monthOffset == 0) {
      return '${now.year}年${now.month}月';
    }
    
    // 月単位でオフセットを計算
    int targetYear = now.year;
    int targetMonth = now.month - monthOffset;
    
    // 月が0以下になった場合、前年に調整
    while (targetMonth <= 0) {
      targetMonth += 12;
      targetYear -= 1;
    }
    
    // 月が12を超えた場合、翌年に調整
    while (targetMonth > 12) {
      targetMonth -= 12;
      targetYear += 1;
    }
    
    return '${targetYear}年${targetMonth}月';
  }

  /// レベルに応じた色を取得
  Color _getHeatmapColor(int level) {
    switch (level) {
      case 0:
        return Colors.grey.shade200;
      case 1:
        return Colors.red.shade100;
      case 2:
        return Colors.red.shade300;
      case 3:
        return Colors.red.shade500;
      case 4:
        return Colors.red.shade700;
      default:
        return Colors.grey.shade200;
    }
  }
}

// CustomBottomNavigationBarは削除してwidgets/navigationbar.dartで共通化

/// プロフィール画面（ホーム画面）
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'ホーム',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
                IconButton(
                  onPressed: () => _showSettingsDialog(context),
                  icon: const Icon(Icons.settings),
                ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // 実際のアプリでは、ここでAPIからデータを再取得
          ref.invalidate(userProfileProvider);
          ref.invalidate(eventInfoProvider);
          ref.invalidate(heatmapDataProvider);
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ユーザープロフィールセクション
              const UserProfileSection(),
              
              const SizedBox(height: 24),
              
              // イベント情報セクション
              const EventInfoSection(),
              
              const SizedBox(height: 24),
              
              // ポイント履歴ヒートマップセクション
              const PointHistoryHeatmap(),
              
              // 下部余白（ボトムナビゲーション分）
              const SizedBox(height: 100),
            ],
          ),
        ),
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