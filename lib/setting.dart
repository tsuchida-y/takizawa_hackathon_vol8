import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ===== Domain Layer =====

/// 設定項目のモデル
class SettingItem {
  final String id;
  final String title;
  final IconData icon;
  final String? subtitle;
  final VoidCallback? onTap;

  const SettingItem({
    required this.id,
    required this.title,
    required this.icon,
    this.subtitle,
    this.onTap,
  });
}

// ===== Data Layer =====

/// 設定データのリポジトリ
class SettingsRepository {
  /// 設定項目のダミーデータを取得
  List<SettingItem> getSettingItems() {
    return [
      SettingItem(
        id: 'account',
        title: 'アカウント',
        icon: Icons.person_outline,
        subtitle: 'プロフィール設定',
        onTap: () => _navigateToAccount(),
      ),
      SettingItem(
        id: 'notifications',
        title: '通知',
        icon: Icons.notifications_outlined,
        subtitle: 'プッシュ通知設定',
        onTap: () => _navigateToNotifications(),
      ),
      SettingItem(
        id: 'social_connect',
        title: 'SNS連携',
        icon: Icons.link_outlined,
        subtitle: 'SNSアカウント連携',
        onTap: () => _navigateToSocialConnect(),
      ),
      SettingItem(
        id: 'announcements',
        title: 'お知らせ',
        icon: Icons.campaign_outlined,
        subtitle: '最新情報をチェック',
        onTap: () => _navigateToAnnouncements(),
      ),
      SettingItem(
        id: 'help',
        title: 'ヘルプ',
        icon: Icons.help_outline,
        subtitle: 'FAQ・お問い合わせ',
        onTap: () => _navigateToHelp(),
      ),
    ];
  }

  // ナビゲーション処理のプレースホルダー
  void _navigateToAccount() {
    debugPrint('アカウント設定画面へ遷移');
  }

  void _navigateToNotifications() {
    debugPrint('通知設定画面へ遷移');
  }

  void _navigateToSocialConnect() {
    debugPrint('SNS連携設定画面へ遷移');
  }

  void _navigateToAnnouncements() {
    debugPrint('お知らせ画面へ遷移');
  }

  void _navigateToHelp() {
    debugPrint('ヘルプ画面へ遷移');
  }
}

// ===== Application Layer =====

/// 設定データのプロバイダー（Riverpod）
final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(),
);

/// 設定項目リストのプロバイダー
final settingItemsProvider = Provider<List<SettingItem>>(
  (ref) => ref.watch(settingsRepositoryProvider).getSettingItems(),
);

// ===== Presentation Layer =====

/// 設定画面のメインウィジェット
class SettingScreen extends ConsumerWidget {
  const SettingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingItems = ref.watch(settingItemsProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          '設定',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        foregroundColor: Colors.black87,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 16),
        itemCount: settingItems.length,
        itemBuilder: (context, index) {
          final item = settingItems[index];
          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            child: SettingItemCard(item: item),
          );
        },
      ),
    );
  }
}

/// 再利用可能な設定項目カードコンポーネント
class SettingItemCard extends StatelessWidget {
  final SettingItem item;

  const SettingItemCard({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
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
        onTap: item.onTap,
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
                  item.icon,
                  color: Colors.blue.shade600,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              
              // テキスト部分
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    if (item.subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.subtitle!,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
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
    );
  }
}

/// アプリケーション全体のプロバイダーラッパー
class SettingApp extends StatelessWidget {
  const SettingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        title: 'Settings Demo',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
          fontFamily: 'NotoSansJP',
        ),
        home: const SettingScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

// デモ用のメイン関数（実際のアプリでは不要）
void main() {
  runApp(const SettingApp());
}