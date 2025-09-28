import 'dart:math' as math;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:takizawa_hackathon_vol8/widgets/setting_button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:takizawa_hackathon_vol8/providers/user_profile_provider.dart';

// ===== データモデル =====

/// イベント情報のデータモデル
class EventInfo {
  final String title;
  final String content;
  final DateTime startDay;
  final DateTime? endDay; // 終了日（オプション）
  final String place;
  final Color color;
  final String id;

  const EventInfo({
    required this.title,
    required this.content,
    required this.startDay,
    this.endDay,
    required this.place,
    required this.color,
    required this.id,
  });

  /// 日付表示用の文字列を取得
  String get dateString {
    if (endDay == null || _isSameDay(startDay, endDay!)) {
      return '${startDay.year}/${startDay.month.toString().padLeft(2, '0')}/${startDay.day.toString().padLeft(2, '0')}';
    } else {
      return '${startDay.year}/${startDay.month.toString().padLeft(2, '0')}/${startDay.day.toString().padLeft(2, '0')}~${endDay!.year}/${endDay!.month.toString().padLeft(2, '0')}/${endDay!.day.toString().padLeft(2, '0')}';
    }
  }

  /// 同じ日かどうかを判定
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  /// Firestoreドキュメントからイベント情報を生成
  factory EventInfo.fromFirestore(Map<String, dynamic> data, String documentId) {
    // カラーはランダムに生成（Firestoreに保存されていないため）
    final List<Color> colors = [
      Colors.blue,
      Colors.green,
      Colors.purple,
      Colors.orange,
      Colors.pink,
      Colors.teal,
      Colors.amber,
      Colors.indigo,
    ];
    final random = math.Random();
    final color = colors[random.nextInt(colors.length)];
    
    return EventInfo(
      id: documentId,
      title: data['title'] ?? '無題のイベント',
      content: data['content'] ?? '詳細なし',
      startDay: data['startDay'] != null 
          ? (data['startDay'] as Timestamp).toDate()
          : DateTime.now(),
      endDay: data['endDay'] != null 
          ? (data['endDay'] as Timestamp).toDate()
          : null,
      place: data['place'] ?? '場所未定',
      color: color,
    );
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

      data.add(HeatmapData(date: date, points: points, level: level));
    }

    return data;
  }

  static int _generateRandomPoints() {
    final random = math.Random();
    final value = random.nextInt(100);

    if (value < 20) return 0;
    if (value < 40) return random.nextInt(5) + 1; // 1-5
    if (value < 70) return random.nextInt(5) + 5; // 5-9
    if (value < 90) return random.nextInt(5) + 10; // 10-14
    return random.nextInt(5) + 15; // 15-19
  }

  static int _calculateLevel(int points) {
    if (points == 0) return 0;
    if (points < 5) return 1;
    if (points < 10) return 2;
    if (points < 15) return 3;
    return 4;
  }
}



// ===== プロバイダー =====



/// イベント情報プロバイダー
final eventInfoProvider = FutureProvider<List<EventInfo>>((ref) async {
  try {
    // Firestoreからイベント情報を取得
    final snapshot = await FirebaseFirestore.instance.collection('eventInfo').get();
    
    // Firestoreのデータからイベント情報を生成
    return snapshot.docs
        .map((doc) => EventInfo.fromFirestore(doc.data(), doc.id))
        .toList();
  } catch (e) {
    print('イベント情報の取得に失敗しました: $e');
    throw Exception('イベント情報の取得に失敗しました');
  }
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
    final profile = ref.watch(sharedUserProfileProvider);
    
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
              child: _buildProfileImage(profile),
            ),
          ),
          const SizedBox(height: 16),

          // ユーザー名
          Text(
            profile.displayName,
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
              _buildStatItem(
                '現在の連続',
                '${profile.currentStreak}日',
                Icons.local_fire_department,
              ),
              _buildStatItem(
                '最長連続',
                '${profile.maxStreak}日',
                Icons.emoji_events,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// プロフィール画像を構築
  Widget _buildProfileImage(UserProfile profile) {
    // プロフィール画像パスがある場合はファイルから読み込み
    if (profile.profileImagePath != null) {
      final file = File(profile.profileImagePath!);
      if (file.existsSync()) {
        return Image.file(
          file,
          width: 80,
          height: 80,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildDefaultAvatar(profile);
          },
        );
      }
    }
    
    // デフォルトアバターまたはネットワーク画像
    return Image.network(
      profile.avatarUrl,
      width: 80,
      height: 80,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return _buildDefaultAvatar(profile);
      },
    );
  }

  /// デフォルトアバターを構築
  Widget _buildDefaultAvatar(UserProfile profile) {
    return Container(
      color: Colors.grey.shade300,
      child: const Icon(
        Icons.person,
        size: 40,
        color: Colors.grey,
      ),
    );
  }

  /// 統計情報項目を構築
  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue, size: 24),
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
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
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
    final eventsAsync = ref.watch(eventInfoProvider);

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
            child: eventsAsync.when(
              data: (events) {
                if (events.isEmpty) {
                  return Center(
                    child: Text(
                      'イベントはありません',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  );
                }
                return ListView.builder(
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
                                event.dateString,
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
                            event.content,
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
                                  event.place,
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
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stack) => Center(
                child: Text(
                  'エラーが発生しました: $error',
                  style: TextStyle(color: Colors.red.shade800),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ポイント履歴ヒートマップウィジェット
class PointHistoryHeatmap extends ConsumerStatefulWidget {
  const PointHistoryHeatmap({super.key});

  @override
  ConsumerState<PointHistoryHeatmap> createState() =>
      _PointHistoryHeatmapState();
}

class _PointHistoryHeatmapState extends ConsumerState<PointHistoryHeatmap> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    final offset = ref.read(heatmapOffsetProvider);
    _pageController = PageController(
      initialPage: 12 - offset,
      viewportFraction: 1.0,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ポイント取得履歴',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '左右スワイプまたはボタンで月移動',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    // 遡りコントロール（左矢印で過去へ）
                    IconButton(
                      onPressed: offset < 12
                          ? () {
                              // 12ヶ月前まで遡れる
                              final newOffset = offset + 1;
                              ref.read(heatmapOffsetProvider.notifier).state =
                                  newOffset;
                              _pageController.animateToPage(
                                12 - newOffset,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            }
                          : null,
                      icon: Icon(
                        Icons.chevron_left,
                        color: offset < 12
                            ? Colors.grey.shade600
                            : Colors.grey.shade300,
                      ),
                      iconSize: 20,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 30,
                        minHeight: 30,
                      ),
                    ),
                    Text(
                      _getDisplayPeriodText(offset),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    IconButton(
                      onPressed: offset > 0
                          ? () {
                              final newOffset = offset - 1;
                              ref.read(heatmapOffsetProvider.notifier).state =
                                  newOffset;
                              _pageController.animateToPage(
                                12 - newOffset,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            }
                          : null,
                      icon: Icon(
                        Icons.chevron_right,
                        color: offset > 0
                            ? Colors.grey.shade600
                            : Colors.grey.shade300,
                      ),
                      iconSize: 20,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 30,
                        minHeight: 30,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ヒートマップグリッド（スクロール可能）
          _buildHeatmapWithLabels(context, ref, heatmapData, offset),

          const SizedBox(height: 12),

          // ヒートマップの凡例
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '少ない',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
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
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// ラベル付きヒートマップを構築（カレンダー形式）
  Widget _buildHeatmapWithLabels(
    BuildContext context,
    WidgetRef ref,
    List<HeatmapData> data,
    int offset,
  ) {
    const double cellSize = 40.0; // カレンダーのセルサイズを調整（オーバーフロー防止）
    const double cellMargin = 1.0; // マージンを調整

    // カレンダーの幅を計算（7日分のセル + マージン）
    const double calendarWidth = (cellSize + cellMargin * 2) * 7;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 曜日ヘッダー（固定）
        Center(
          child: SizedBox(
            width: calendarWidth,
            child: _buildCalendarWeekdayHeader(cellSize, cellMargin),
          ),
        ),

        const SizedBox(height: 4),

        // カレンダー月表示を水平スクロール可能に
        SizedBox(
          height: 280, // 適切な高さに調整
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (page) {
              // ページが変更されたらオフセットを更新
              final newOffset = 12 - page;
              if (newOffset >= 0 && newOffset <= 12) {
                ref.read(heatmapOffsetProvider.notifier).state = newOffset;
              }
            },
            itemCount: 13, // 過去12ヶ月 + 現在月
            itemBuilder: (context, index) {
              final monthOffset = 12 - index;
              final monthData = _organizeDataForCalendar(data, monthOffset);

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: SingleChildScrollView(
                  child: Center(
                    child: _buildCalendarGrid(
                      context,
                      monthData,
                      cellSize,
                      cellMargin,
                      data,
                      monthOffset,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// カレンダー形式用のデータ構造
  List<List<HeatmapData?>> _organizeDataForCalendar(
    List<HeatmapData> data,
    int monthOffset,
  ) {
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

    // 月の最初の日が何曜日かを取得（日曜日を0、月曜日を1...土曜日を6）
    int firstWeekday = firstDayOfMonth.weekday;
    if (firstWeekday == 7) firstWeekday = 0; // 日曜日を0に調整

    // カレンダーのグリッドを作成
    final List<List<HeatmapData?>> calendar = [];

    // カレンダーの開始日（前月の日付を含む）
    final calendarStartDate = firstDayOfMonth.subtract(
      Duration(days: firstWeekday),
    );

    // 6週間分のカレンダーを生成
    for (int week = 0; week < 6; week++) {
      final List<HeatmapData?> weekData = [];

      for (int day = 0; day < 7; day++) {
        final currentDate = calendarStartDate.add(
          Duration(days: week * 7 + day),
        );
        weekData.add(_findDataForDate(data, currentDate));
      }

      calendar.add(weekData);
    }

    return calendar;
  }

  /// 指定された日付のデータを検索
  HeatmapData? _findDataForDate(List<HeatmapData> data, DateTime targetDate) {
    try {
      return data.firstWhere(
        (item) =>
            item.date.year == targetDate.year &&
            item.date.month == targetDate.month &&
            item.date.day == targetDate.day,
      );
    } catch (e) {
      return null;
    }
  }

  /// カレンダー形式の曜日ヘッダーを構築
  Widget _buildCalendarWeekdayHeader(double cellSize, double cellMargin) {
    const weekdays = ['日', '月', '火', '水', '木', '金', '土'];
    const weekdayColors = [
      Colors.red, // 日曜日
      Colors.black, // 月曜日
      Colors.black, // 火曜日
      Colors.black, // 水曜日
      Colors.black, // 木曜日
      Colors.black, // 金曜日
      Colors.blue, // 土曜日
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center, // 中央寄せに修正
      children: List.generate(7, (index) {
        return Container(
          width: cellSize,
          height: 40,
          margin: EdgeInsets.all(cellMargin),
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
  Widget _buildCalendarGrid(
    BuildContext context,
    List<List<HeatmapData?>> calendar,
    double cellSize,
    double cellMargin,
    List<HeatmapData> allData,
    int monthOffset,
  ) {
    final now = DateTime.now();

    // 表示中の月を計算
    int displayYear = now.year;
    int displayMonth = now.month - monthOffset;

    // 月が0以下になった場合、前年に調整
    while (displayMonth <= 0) {
      displayMonth += 12;
      displayYear -= 1;
    }

    // 月が12を超えた場合、翌年に調整
    while (displayMonth > 12) {
      displayMonth -= 12;
      displayYear += 1;
    }

    return Column(
      children: calendar.map((week) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(7, (dayIndex) {
            final cellData = week[dayIndex];
            final isToday =
                cellData != null &&
                cellData.date.year == now.year &&
                cellData.date.month == now.month &&
                cellData.date.day == now.day;

            // 該当月かどうかを判定（現在表示中の月）
            final isCurrentMonth =
                cellData != null &&
                cellData.date.year == displayYear &&
                cellData.date.month == displayMonth;

            Color cellColor = Colors.grey.shade200;
            if (cellData != null) {
              cellColor = _getHeatmapColor(cellData.level);
            }

            return Flexible(
              child: GestureDetector(
                onTap: cellData != null
                    ? () => _showDayPointsDialog(context, cellData)
                    : null,
                child: Container(
                  width: cellSize + cellMargin * 2,
                  height: cellSize + cellMargin * 2,
                  margin: EdgeInsets.all(cellMargin),
                  decoration: BoxDecoration(
                    color: cellColor,
                    borderRadius: BorderRadius.circular(6),
                    border: isToday
                        ? Border.all(color: Colors.blue, width: 2)
                        : null,
                  ),
                  child: cellData != null
                      ? Center(
                          child: Text(
                            '${cellData.date.day}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: isToday
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: isCurrentMonth
                                  ? (cellData.level > 2
                                        ? Colors.white
                                        : Colors.black87)
                                  : Colors.grey.shade400, // 該当月以外は薄く表示
                            ),
                          ),
                        )
                      : null,
                ),
              ),
            );
          }),
        );
      }).toList(),
    );
  }

  /// 日付タップ時のポイント詳細ダイアログを表示
  void _showDayPointsDialog(BuildContext context, HeatmapData data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '${data.date.year}年${data.date.month}月${data.date.day}日',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getHeatmapColor(data.level).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _getHeatmapColor(data.level)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.star,
                    color: _getHeatmapColor(data.level),
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${data.points}ポイント',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _getHeatmapColor(data.level),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'レベル: ${_getLevelText(data.level)}',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
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

  /// レベルのテキスト表現を取得
  String _getLevelText(int level) {
    switch (level) {
      case 0:
        return 'なし';
      case 1:
        return '少ない';
      case 2:
        return '普通';
      case 3:
        return '多い';
      case 4:
        return '非常に多い';
      default:
        return 'なし';
    }
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
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [const SettingsButton()],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // 実際のアプリでは、ここでAPIからデータを再取得
          ref.invalidate(sharedUserProfileProvider);
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
}
