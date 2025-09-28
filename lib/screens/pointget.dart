import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'gacha.dart'; // ポイントシステムを共有するためのインポート

/// ポイント獲得アクションの種類を定義する列挙型
/// 各アクションに対応するポイント獲得手段を区別し、地域活性化を促進する
enum PointActionType {
  location, // 現在地情報取得（GPSベースの位置情報収集）
  event, // イベント参加（地域イベントへの参加登録）
  product, // 特産品購入登録（地元商品の購入履歴登録）
  socialComment, // SNSで地域関連コメント投稿（地域コンテンツのシェア）
}

/// ポイント獲得アクションの情報を格納するクラス
/// 各アクションの表示情報とポイント報酬を一元管理
class PointAction {
  final PointActionType type; // アクションの種類
  final String title; // アクションの表示タイトル
  final String description; // アクションの詳細説明
  final int points; // 獲得できるポイント数
  final IconData icon; // アクションを表すアイコン

  const PointAction({
    required this.type,
    required this.title,
    required this.description,
    required this.points,
    required this.icon,
  });
}

/// SNSプラットフォームの種類を定義する列挙型
/// 各プラットフォームでのポイント獲得機能を管理し、地域情報の拡散を促進
enum SocialPlatform {
  twitter, // X（旧Twitter）での投稿・シェア
  youtube, // YouTubeでの動画投稿・コメント
  instagram, // Instagramでの写真投稿・ストーリーズ
  other, // その他のSNSプラットフォーム（LINEなど）
}

/// SNSプラットフォームの情報を格納するクラス
class SocialPlatformInfo {
  final SocialPlatform platform;
  final String name;
  final IconData icon;
  final int points;
  final Color color;
  final String? iconPath;

  const SocialPlatformInfo({
    required this.platform,
    required this.name,
    required this.icon,
    required this.points,
    required this.color,
    this.iconPath,
  });
}

// ポイントシステムはgacha.dartから共有

/// ポイント獲得アクションのサンプルデータ
final pointActionsProvider = Provider<List<PointAction>>((ref) {
  return const [
    PointAction(
      type: PointActionType.event,
      title: 'イベント参加',
      description: '地域イベントに参加してポイントを獲得',
      points: 200,
      icon: Icons.event,
    ),
    PointAction(
      type: PointActionType.product,
      title: '特産品購入',
      description: '特産品の購入を登録してポイントを獲得',
      points: 300,
      icon: Icons.shopping_bag,
    ),
  ];
});

/// SNSプラットフォームのサンプルデータ
final socialPlatformsProvider = Provider<List<SocialPlatformInfo>>((ref) {
  return const [
    SocialPlatformInfo(
      platform: SocialPlatform.twitter,
      name: 'X',
      icon: Icons.alternate_email,
      points: 50,
      color: Colors.black,
      iconPath: 'lib/icon/logo-black.png',
    ),
    SocialPlatformInfo(
      platform: SocialPlatform.instagram,
      name: 'Instagram',
      icon: Icons.camera_alt,
      points: 60,
      color: Colors.purple,
      iconPath: 'lib/icon/Instagram_Glyph_Gradient.png',
    ),
    SocialPlatformInfo(
      platform: SocialPlatform.other,
      name: 'LINE',
      icon: Icons.chat,
      points: 45,
      color: Colors.green,
      iconPath: 'lib/icon/LINE_Brand_icon.png',
    ),
    SocialPlatformInfo(
      platform: SocialPlatform.youtube,
      name: 'Facebook',
      icon: Icons.facebook,
      points: 55,
      color: Colors.blue,
      iconPath: 'lib/icon/Facebook_Logo_Primary.png',
    ),
  ];
});

/// ポイントゲット画面
class PointGetScreen extends ConsumerWidget {
  const PointGetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pointState = ref.watch(pointProvider);
    final pointActions = ref.watch(pointActionsProvider);
    final socialPlatforms = ref.watch(socialPlatformsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            // ヘッダー
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Text(
                    '${pointState.currentPoints}pt',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue,
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Pt',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SettingsButton(),
                ],
              ),
            ),

            // エラーメッセージ
            if (pointState.errorMessage != null)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        pointState.errorMessage!,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                    IconButton(
                      onPressed: () =>
                          ref.read(pointProvider.notifier).clearError(),
                      icon: Icon(Icons.close, color: Colors.red.shade600),
                    ),
                  ],
                ),
              ),

            // メインコンテンツ（すべてスクロール可能）
            Expanded(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // 現在地記録設定（スクロール内に移動）
                    Container(
                      margin: const EdgeInsets.all(16),
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
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '現在地記録',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '1h 0.1pt',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: pointState.isLocationTrackingEnabled,
                            onChanged: (value) {
                              ref
                                  .read(pointProvider.notifier)
                                  .toggleLocationTracking();
                              if (value) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('現在地記録を開始しました'),
                                    backgroundColor: Colors.green,
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('現在地記録を停止しました'),
                                    backgroundColor: Colors.orange,
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                            activeColor: Colors.green,
                          ),
                        ],
                      ),
                    ),
                    // ポイント獲得アクション
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: pointActions
                            .map(
                              (action) => Container(
                                margin: const EdgeInsets.only(bottom: 12),
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
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        action.icon,
                                        color: Colors.blue,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            action.title,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            '+${action.points}pt',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.blue.shade600,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => _handlePointAction(
                                        ref,
                                        context,
                                        action,
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                      ),
                                      child: const Text('実行'),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // SNSセクション
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      width: double.infinity,
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'SNS',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 3,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                ),
                            itemCount: socialPlatforms.length,
                            itemBuilder: (context, index) {
                              final platform = socialPlatforms[index];
                              return InkWell(
                                onTap: () =>
                                    _handleSocialAction(ref, context, platform),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: platform.iconPath != null
                                            ? ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                                child: Image.asset(
                                                  platform.iconPath!,
                                                  width: 24,
                                                  height: 24,
                                                  fit: BoxFit.contain,
                                                  errorBuilder:
                                                      (
                                                        context,
                                                        error,
                                                        stackTrace,
                                                      ) {
                                                        return Icon(
                                                          platform.icon,
                                                          color: platform.color,
                                                          size: 16,
                                                        );
                                                      },
                                                ),
                                              )
                                            : Icon(
                                                platform.icon,
                                                color: platform.color,
                                                size: 16,
                                              ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          platform.name,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handlePointAction(
    WidgetRef ref,
    BuildContext context,
    PointAction action,
  ) {
    ref.read(pointProvider.notifier).addPoints(action.points);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${action.title}完了！+${action.points}pt獲得'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handleSocialAction(
    WidgetRef ref,
    BuildContext context,
    SocialPlatformInfo platform,
  ) {
    ref.read(pointProvider.notifier).addPoints(platform.points);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${platform.name}でコメント投稿完了！+${platform.points}pt獲得'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
