import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../service/notification_service.dart';

// ===== Domain Layer =====

/// 通知設定のモデル
class NotificationSettings {
  final bool pushNotificationEnabled;
  final bool informationNotificationEnabled;
  final bool pointNotificationEnabled;

  const NotificationSettings({
    required this.pushNotificationEnabled,
    required this.informationNotificationEnabled,
    required this.pointNotificationEnabled,
  });

  NotificationSettings copyWith({
    bool? pushNotificationEnabled,
    bool? informationNotificationEnabled,
    bool? pointNotificationEnabled,
  }) {
    return NotificationSettings(
      pushNotificationEnabled: pushNotificationEnabled ?? this.pushNotificationEnabled,
      informationNotificationEnabled: informationNotificationEnabled ?? this.informationNotificationEnabled,
      pointNotificationEnabled: pointNotificationEnabled ?? this.pointNotificationEnabled,
    );
  }
}

// ===== Data Layer =====

/// 通知設定のリポジトリ
class NotificationRepository {
  /// 通知設定の初期データを取得
  NotificationSettings getNotificationSettings() {
    return const NotificationSettings(
      pushNotificationEnabled: true,
      informationNotificationEnabled: true,
      pointNotificationEnabled: true,
    );
  }

  /// 通知設定を保存（ダミー実装）
  Future<void> saveNotificationSettings(NotificationSettings settings) async {
    // TODO: 実際の保存処理を実装
    await Future.delayed(const Duration(milliseconds: 500));
    debugPrint('通知設定を保存しました: $settings');
  }
}

// ===== Application Layer =====

/// 通知設定のプロバイダー
final notificationRepositoryProvider = Provider<NotificationRepository>(
  (ref) => NotificationRepository(),
);

/// 通知設定の状態管理
class NotificationNotifier extends StateNotifier<NotificationSettings> {
  final NotificationRepository _repository;

  NotificationNotifier(this._repository) : super(_repository.getNotificationSettings());

  /// プッシュ通知の設定を切り替え
  void togglePushNotification(bool enabled) {
    state = state.copyWith(pushNotificationEnabled: enabled);
    _saveSettings();
  }

  /// インフォメーション通知の設定を切り替え
  void toggleInformationNotification(bool enabled) {
    state = state.copyWith(informationNotificationEnabled: enabled);
    _saveSettings();
  }

  /// ポイント通知の設定を切り替え
  void togglePointNotification(bool enabled) {
    state = state.copyWith(pointNotificationEnabled: enabled);
    _saveSettings();
  }

  /// 設定を保存
  void _saveSettings() {
    _repository.saveNotificationSettings(state);
  }
}

/// 通知設定のStateNotifierProvider
final notificationProvider = StateNotifierProvider<NotificationNotifier, NotificationSettings>(
  (ref) {
    final repository = ref.watch(notificationRepositoryProvider);
    return NotificationNotifier(repository);
  },
);

// ===== Presentation Layer =====

/// 通知設定画面
class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(notificationProvider);
    final notifier = ref.read(notificationProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          '通知設定',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        foregroundColor: Colors.black87,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 説明テキスト
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade600),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'アプリからの通知を受け取るかどうかを設定できます。',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue.shade800,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // プッシュ通知設定
          _buildNotificationCard(
            title: 'プッシュ通知',
            subtitle: 'アプリからの通知を受け取る',
            icon: Icons.notifications_outlined,
            value: settings.pushNotificationEnabled,
            onChanged: notifier.togglePushNotification,
          ),

          const SizedBox(height: 16),

          // インフォメーション通知設定
          _buildNotificationCard(
            title: 'お知らせ通知',
            subtitle: '新しいインフォメーションが配信された時に通知',
            icon: Icons.campaign_outlined,
            value: settings.informationNotificationEnabled,
            onChanged: notifier.toggleInformationNotification,
            enabled: settings.pushNotificationEnabled,
          ),

          const SizedBox(height: 16),

          // ポイント通知設定
          _buildNotificationCard(
            title: 'ポイント獲得通知',
            subtitle: 'ポイントを獲得した時に通知',
            icon: Icons.stars_outlined,
            value: settings.pointNotificationEnabled,
            onChanged: notifier.togglePointNotification,
            enabled: settings.pushNotificationEnabled,
          ),

          const SizedBox(height: 32),

          // テスト通知ボタン
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.play_arrow, color: Colors.green.shade600),
                    const SizedBox(width: 8),
                    Text(
                      'テスト通知',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.green.shade800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: settings.pushNotificationEnabled && settings.informationNotificationEnabled
                            ? () => _sendTestInformationNotification(context)
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('お知らせ通知'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: settings.pushNotificationEnabled && settings.pointNotificationEnabled
                            ? () => _sendTestPointNotification(context)
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('ポイント通知'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 注意事項
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning_amber_outlined, color: Colors.orange.shade600),
                    const SizedBox(width: 8),
                    Text(
                      '注意事項',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange.shade800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '• プッシュ通知をオフにすると、すべての通知が届かなくなります\n'
                  '• 端末の設定でも通知を許可する必要があります\n'
                  '• 通知設定の変更は即座に反映されます',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.orange.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 通知設定カードを構築
  Widget _buildNotificationCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required Function(bool) onChanged,
    bool enabled = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: enabled ? Colors.blue.shade50 : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: enabled ? Colors.blue.shade600 : Colors.grey.shade400,
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: enabled ? Colors.black87 : Colors.grey.shade600,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: enabled ? Colors.grey.shade600 : Colors.grey.shade400,
            ),
          ),
        ),
        trailing: Switch(
          value: enabled ? value : false,
          onChanged: enabled ? onChanged : null,
          activeColor: Colors.green,
          inactiveThumbColor: Colors.grey.shade400,
          inactiveTrackColor: Colors.grey.shade200,
        ),
      ),
    );
  }

  /// テスト用お知らせ通知を送信
  Future<void> _sendTestInformationNotification(BuildContext context) async {
    try {
      debugPrint('=== テスト通知開始 ===');
      debugPrint('テスト通知ボタンが押されました');
      
      debugPrint('NotificationService インスタンス作成中...');
      final notificationService = NotificationService();
      
      debugPrint('通知サービス初期化中...');
      await notificationService.initialize();
      debugPrint('通知サービス初期化完了');
      
      debugPrint('通知権限をリクエスト中...');
      final hasPermission = await notificationService.requestPermission();
      debugPrint('通知権限結果: $hasPermission');
      
      if (!hasPermission) {
        debugPrint('通知権限がありません');
        // 権限がない場合の処理
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('通知権限が必要です。設定から許可してください。'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      debugPrint('お知らせ通知を送信中...');
      await notificationService.showInformationNotification(
        title: '新しいお知らせ',
        body: 'テスト用のお知らせ通知です。実際の通知設定が正常に動作しています。',
        payload: 'test_information',
      );
      debugPrint('お知らせ通知送信完了');

      debugPrint('成功メッセージを表示中...');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('お知らせ通知を送信しました'),
          backgroundColor: Colors.blue,
        ),
      );
      debugPrint('=== テスト通知終了 ===');
    } catch (e, stackTrace) {
      debugPrint('テスト通知送信でエラーが発生: $e');
      debugPrint('スタックトレース: $stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('通知送信でエラーが発生しました: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// テスト用ポイント獲得通知を送信
  Future<void> _sendTestPointNotification(BuildContext context) async {
    try {
      debugPrint('テストポイント通知ボタンが押されました');
      
      final notificationService = NotificationService();
      await notificationService.initialize();
      
      final hasPermission = await notificationService.requestPermission();
      if (!hasPermission) {
        // 権限がない場合の処理
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('通知権限が必要です。設定から許可してください。'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      await notificationService.showPointNotification(
        title: 'ポイント獲得！',
        body: '100ポイントを獲得しました！テスト用のポイント通知です。',
        payload: 'test_point',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ポイント獲得通知を送信しました'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint('テストポイント通知送信でエラーが発生: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('通知送信でエラーが発生しました: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}