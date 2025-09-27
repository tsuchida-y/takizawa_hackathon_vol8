import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ===== Domain Layer =====

/// お知らせの種類
enum AnnouncementType {
  update('アップデート'),
  maintenance('メンテナンス'),
  campaign('キャンペーン'),
  feature('新機能'),
  important('重要');

  const AnnouncementType(this.displayName);
  final String displayName;

  Color get color {
    switch (this) {
      case AnnouncementType.update:
        return Colors.blue;
      case AnnouncementType.maintenance:
        return Colors.orange;
      case AnnouncementType.campaign:
        return Colors.purple;
      case AnnouncementType.feature:
        return Colors.green;
      case AnnouncementType.important:
        return Colors.red;
    }
  }

  IconData get icon {
    switch (this) {
      case AnnouncementType.update:
        return Icons.system_update;
      case AnnouncementType.maintenance:
        return Icons.build;
      case AnnouncementType.campaign:
        return Icons.local_offer;
      case AnnouncementType.feature:
        return Icons.new_releases;
      case AnnouncementType.important:
        return Icons.priority_high;
    }
  }
}

/// お知らせアイテムのモデル
class AnnouncementItem {
  final String id;
  final String title;
  final String content;
  final AnnouncementType type;
  final DateTime publishedAt;
  final bool isRead;
  final bool isPinned;

  const AnnouncementItem({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    required this.publishedAt,
    this.isRead = false,
    this.isPinned = false,
  });

  AnnouncementItem copyWith({
    String? id,
    String? title,
    String? content,
    AnnouncementType? type,
    DateTime? publishedAt,
    bool? isRead,
    bool? isPinned,
  }) {
    return AnnouncementItem(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      type: type ?? this.type,
      publishedAt: publishedAt ?? this.publishedAt,
      isRead: isRead ?? this.isRead,
      isPinned: isPinned ?? this.isPinned,
    );
  }
}

/// お知らせ状態のモデル
class AnnouncementState {
  final List<AnnouncementItem> announcements;
  final bool isLoading;

  const AnnouncementState({
    required this.announcements,
    this.isLoading = false,
  });

  AnnouncementState copyWith({
    List<AnnouncementItem>? announcements,
    bool? isLoading,
  }) {
    return AnnouncementState(
      announcements: announcements ?? this.announcements,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  /// 未読のお知らせ数を取得
  int get unreadCount => announcements.where((item) => !item.isRead).length;

  /// ピン留めされたお知らせを取得
  List<AnnouncementItem> get pinnedAnnouncements =>
      announcements.where((item) => item.isPinned).toList();

  /// 通常のお知らせを取得（ピン留め以外）
  List<AnnouncementItem> get regularAnnouncements =>
      announcements.where((item) => !item.isPinned).toList();
}

// ===== Data Layer =====

/// お知らせデータのリポジトリ
class AnnouncementRepository {
  /// お知らせ一覧を取得
  Future<List<AnnouncementItem>> getAnnouncements() async {
    // データ取得をシミュレート
    await Future.delayed(const Duration(seconds: 1));

    return [
      AnnouncementItem(
        id: 'ann_001',
        title: 'アプリバージョン1.0.0リリース',
        content: '''
新しいバージョン1.0.0がリリースされました！

【新機能】
• プロフィール編集機能
• 通知設定機能
• SNS連携機能
• ヘルプ・サポート機能

【改善点】
• パフォーマンスの向上
• UIの改善
• セキュリティの強化

ぜひ新機能をお試しください！
        ''',
        type: AnnouncementType.update,
        publishedAt: DateTime.now().subtract(const Duration(hours: 2)),
        isPinned: true,
      ),
      AnnouncementItem(
        id: 'ann_002',
        title: '【重要】利用規約の改定について',
        content: '''
利用規約を改定いたします。

【改定内容】
• プライバシーポリシーの更新
• データ取り扱いに関する条項の追加
• サービス利用条件の明確化

【施行日】
2025年10月1日より適用

詳細は利用規約ページをご確認ください。
        ''',
        type: AnnouncementType.important,
        publishedAt: DateTime.now().subtract(const Duration(days: 1)),
        isPinned: true,
      ),
      AnnouncementItem(
        id: 'ann_003',
        title: '新機能：カメラ・ギャラリー連携',
        content: '''
プロフィール画像の設定がさらに便利になりました！

【新機能】
• カメラでの直接撮影
• ギャラリーからの画像選択
• 画像の自動リサイズ

アカウント設定画面からお試しください。
        ''',
        type: AnnouncementType.feature,
        publishedAt: DateTime.now().subtract(const Duration(days: 2)),
        isRead: true,
      ),
      AnnouncementItem(
        id: 'ann_004',
        title: 'メンテナンス実施のお知らせ',
        content: '''
下記日程でメンテナンスを実施いたします。

【日時】
2025年9月30日（月）
午前2:00 ～ 午前6:00（予定）

【内容】
• サーバーの定期メンテナンス
• システムの安定性向上
• セキュリティアップデート

メンテナンス中はアプリをご利用いただけません。
ご不便をおかけいたしますが、ご理解のほどよろしくお願いいたします。
        ''',
        type: AnnouncementType.maintenance,
        publishedAt: DateTime.now().subtract(const Duration(days: 3)),
        isRead: true,
      ),
      AnnouncementItem(
        id: 'ann_005',
        title: '秋のキャンペーン開催中！',
        content: '''
お得な秋のキャンペーンを開催中です！

【キャンペーン内容】
• 新規登録で500ポイントプレゼント
• 友達紹介でさらに300ポイント
• 期間限定の特別機能を無料開放

【期間】
2025年9月15日 ～ 2025年10月15日

この機会をお見逃しなく！
        ''',
        type: AnnouncementType.campaign,
        publishedAt: DateTime.now().subtract(const Duration(days: 5)),
        isRead: true,
      ),
    ];
  }

  /// お知らせを既読にする
  Future<void> markAsRead(String announcementId) async {
    debugPrint('お知らせ $announcementId を既読にしました');
    await Future.delayed(const Duration(milliseconds: 300));
  }

  /// すべてのお知らせを既読にする
  Future<void> markAllAsRead() async {
    debugPrint('すべてのお知らせを既読にしました');
    await Future.delayed(const Duration(milliseconds: 500));
  }
}

// ===== Application Layer =====

/// お知らせリポジトリのプロバイダー
final announcementRepositoryProvider = Provider<AnnouncementRepository>(
  (ref) => AnnouncementRepository(),
);

/// お知らせ状態管理
class AnnouncementNotifier extends StateNotifier<AnnouncementState> {
  final AnnouncementRepository _repository;

  AnnouncementNotifier(this._repository)
      : super(const AnnouncementState(announcements: []));

  /// お知らせを読み込み
  Future<void> loadAnnouncements() async {
    state = state.copyWith(isLoading: true);

    try {
      final announcements = await _repository.getAnnouncements();
      state = state.copyWith(
        announcements: announcements,
        isLoading: false,
      );
    } catch (e) {
      debugPrint('お知らせの読み込みに失敗: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  /// お知らせを既読にする
  Future<void> markAsRead(String announcementId) async {
    await _repository.markAsRead(announcementId);

    final updatedAnnouncements = state.announcements.map((item) {
      if (item.id == announcementId) {
        return item.copyWith(isRead: true);
      }
      return item;
    }).toList();

    state = state.copyWith(announcements: updatedAnnouncements);
  }

  /// すべてのお知らせを既読にする
  Future<void> markAllAsRead() async {
    await _repository.markAllAsRead();

    final updatedAnnouncements = state.announcements.map((item) {
      return item.copyWith(isRead: true);
    }).toList();

    state = state.copyWith(announcements: updatedAnnouncements);
  }
}

/// お知らせのStateNotifierProvider
final announcementProvider = StateNotifierProvider<AnnouncementNotifier, AnnouncementState>(
  (ref) {
    final repository = ref.watch(announcementRepositoryProvider);
    return AnnouncementNotifier(repository);
  },
);

// ===== Presentation Layer =====

/// お知らせ画面
class AnnouncementScreen extends ConsumerStatefulWidget {
  const AnnouncementScreen({super.key});

  @override
  ConsumerState<AnnouncementScreen> createState() => _AnnouncementScreenState();
}

class _AnnouncementScreenState extends ConsumerState<AnnouncementScreen> {
  @override
  void initState() {
    super.initState();
    // 画面初期化時にお知らせを読み込み
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(announcementProvider.notifier).loadAnnouncements();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(announcementProvider);
    final notifier = ref.read(announcementProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Row(
          children: [
            const Text(
              'お知らせ',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (state.unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${state.unreadCount}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        foregroundColor: Colors.black87,
        actions: [
          if (state.unreadCount > 0)
            TextButton(
              onPressed: () => notifier.markAllAsRead(),
              child: const Text(
                'すべて既読',
                style: TextStyle(fontSize: 14),
              ),
            ),
          IconButton(
            onPressed: () => notifier.loadAnnouncements(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.announcements.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: () => notifier.loadAnnouncements(),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // ピン留めされたお知らせ
                      if (state.pinnedAnnouncements.isNotEmpty) ...[
                        _buildSectionHeader('ピン留め', Icons.push_pin),
                        const SizedBox(height: 12),
                        ...state.pinnedAnnouncements.map((item) => _buildAnnouncementCard(item, notifier)),
                        const SizedBox(height: 24),
                      ],

                      // 通常のお知らせ
                      if (state.regularAnnouncements.isNotEmpty) ...[
                        _buildSectionHeader('お知らせ', Icons.notifications_outlined),
                        const SizedBox(height: 12),
                        ...state.regularAnnouncements.map((item) => _buildAnnouncementCard(item, notifier)),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'お知らせはありません',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '新しいお知らせがあるとここに表示されます',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue.shade600, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.blue.shade800,
          ),
        ),
      ],
    );
  }

  Widget _buildAnnouncementCard(AnnouncementItem item, AnnouncementNotifier notifier) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: item.isRead ? null : Border.all(color: Colors.blue.shade200, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showAnnouncementDetail(item, notifier),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ヘッダー部分
              Row(
                children: [
                  // タイプアイコンとラベル
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: item.type.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          item.type.icon,
                          size: 14,
                          color: item.type.color,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          item.type.displayName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: item.type.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // 日付
                  Text(
                    _formatDate(item.publishedAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  // 未読バッジ
                  if (!item.isRead) ...[
                    const SizedBox(width: 8),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                  // ピン留めアイコン
                  if (item.isPinned) ...[
                    const SizedBox(width: 8),
                    Icon(
                      Icons.push_pin,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 12),

              // タイトル
              Text(
                item.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: item.isRead ? Colors.grey.shade700 : Colors.black87,
                ),
              ),

              const SizedBox(height: 8),

              // プレビューテキスト
              Text(
                item.content.replaceAll('\n', ' ').trim(),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAnnouncementDetail(AnnouncementItem item, AnnouncementNotifier notifier) {
    // 未読の場合は既読にする
    if (!item.isRead) {
      notifier.markAsRead(item.id);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AnnouncementDetailSheet(announcement: item),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}分前';
      }
      return '${difference.inHours}時間前';
    } else if (difference.inDays == 1) {
      return '昨日';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}日前';
    } else {
      return '${date.year}/${date.month}/${date.day}';
    }
  }
}

/// お知らせ詳細のボトムシート
class AnnouncementDetailSheet extends StatelessWidget {
  final AnnouncementItem announcement;

  const AnnouncementDetailSheet({
    super.key,
    required this.announcement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // ハンドル
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // ヘッダー
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: announcement.type.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        announcement.type.icon,
                        size: 14,
                        color: announcement.type.color,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        announcement.type.displayName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: announcement.type.color,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  '${announcement.publishedAt.year}/${announcement.publishedAt.month}/${announcement.publishedAt.day}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          const Divider(),

          // コンテンツ
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    announcement.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    announcement.content,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}