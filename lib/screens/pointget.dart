import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:takizawa_hackathon_vol8/widgets/setting_button.dart';
import 'package:takizawa_hackathon_vol8/service/location_service_lite.dart';
import 'package:takizawa_hackathon_vol8/service/notification_service.dart';
import 'package:takizawa_hackathon_vol8/providers/user_profile_provider.dart';
import 'package:takizawa_hackathon_vol8/screens/ranking.dart';

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

/// ポイント管理の状態を定義するクラス
/// アプリ全体で共有されるポイント系システムの状態管理
class PointState {
  final int currentPoints; // ユーザーの現在所持ポイント
  final bool isLoading; // ポイント操作中のローディング状態
  final String? errorMessage; // エラーメッセージ（オプション）
  final bool isLocationTrackingEnabled; // 現在地追跡機能のON/OFF状態
  final bool isLocationLoading; // 位置情報取得中のローディング状態

  const PointState({
    this.currentPoints = 1000, // 初期ポイント
    this.isLoading = false,
    this.errorMessage,
    this.isLocationTrackingEnabled = false,
    this.isLocationLoading = false,
  });

  PointState copyWith({
    int? currentPoints,
    bool? isLoading,
    String? errorMessage,
    bool? isLocationTrackingEnabled,
    bool? isLocationLoading,
  }) {
    return PointState(
      currentPoints: currentPoints ?? this.currentPoints,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      isLocationTrackingEnabled:
          isLocationTrackingEnabled ?? this.isLocationTrackingEnabled,
      isLocationLoading: isLocationLoading ?? this.isLocationLoading,
    );
  }
}

/// ポイント管理のコントローラー
class PointController extends StateNotifier<PointState> {
  final LocationRepositoryLite _locationRepository;
  final NotificationService _notificationService;
  final Ref _ref;

  PointController(this._locationRepository, this._notificationService, this._ref) 
      : super(const PointState());

  void addPoints(int points) {
    if (points <= 0) return;

    final newTotalPoints = state.currentPoints + points;
    state = state.copyWith(
      currentPoints: newTotalPoints,
      errorMessage: null,
    );
    
    // プロフィールのポイント情報も更新
    _ref.read(sharedUserProfileProvider.notifier).updatePoints(
      newTotalPoints,
      state.currentPoints, // 現在の連続日数（実際は日数ロジックが必要）
      state.currentPoints, // 最長連続日数（実際はロジックが必要）
    );
    
    // ランキングデータも無効化して再計算を促す
    _ref.invalidate(rankingDataProvider);
  }

  bool consumePoints(int points) {
    if (points <= 0) return false;
    if (state.currentPoints < points) {
      state = state.copyWith(errorMessage: 'ポイントが不足しています');
      return false;
    }

    state = state.copyWith(
      currentPoints: state.currentPoints - points,
      errorMessage: null,
    );
    return true;
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  /// 位置情報追跡の有効/無効を切り替え
  void toggleLocationTracking() {
    state = state.copyWith(
      isLocationTrackingEnabled: !state.isLocationTrackingEnabled,
    );
  }

  /// 位置情報を取得してポイントを獲得
  Future<bool> getLocationAndEarnPoints() async {
    state = state.copyWith(isLocationLoading: true, errorMessage: null);
    
    try {
      final location = await _locationRepository.getCurrentLocationWithAddress(
        settings: AppLocationSettingsLite.balanced,
      );
      
      if (location != null) {
        const points = 100;
        addPoints(points);
        
        // ポイント獲得通知を送信
        await _notificationService.showPointNotification(
          title: '\u4f4d\u7f6e\u60c5\u5831\u53d6\u5f97\u5b8c\u4e86\uff01',
          body: '+${points}pt\u7372\u5f97\u3057\u307e\u3057\u305f\u3002\u4f4d\u7f6e: ${location.address ?? "\u4f4d\u7f6e\u60c5\u5831\u3092\u53d6\u5f97\u3057\u307e\u3057\u305f"}',
        );
        
        state = state.copyWith(isLocationLoading: false);
        return true;
      } else {
        state = state.copyWith(
          isLocationLoading: false,
          errorMessage: '位置情報の取得に失敗しました。権限を確認してください。',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLocationLoading: false,
        errorMessage: '位置情報の取得中にエラーが発生しました: $e',
      );
      return false;
    }
  }

  /// ポイント獲得時に通知を送信
  Future<void> addPointsWithNotification(int points, String title, String description) async {
    if (points <= 0) return;

    addPoints(points);
    
    // ポイント獲得通知を送信
    await _notificationService.showPointNotification(
      title: title,
      body: '+${points}pt\u7372\u5f97\uff01 $description',
    );
  }
}

/// ポイント管理のプロバイダー
final pointProvider = StateNotifierProvider<PointController, PointState>((ref) {
  final locationRepository = ref.watch(locationRepositoryLiteProvider);
  final notificationService = NotificationService();
  return PointController(locationRepository, notificationService, ref);
});

/// ポイント獲得アクションのサンプルデータ
final pointActionsProvider = Provider<List<PointAction>>((ref) {
  return const [
    PointAction(
      type: PointActionType.location,
      title: '現在地登録',
      description: '位置情報を取得してポイントを獲得',
      points: 100,
      icon: Icons.location_on,
    ),
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
    PointAction(
      type: PointActionType.socialComment,
      title: 'SNS投稿',
      description: '地域に関するコメントを投稿してポイントを獲得',
      points: 50,
      icon: Icons.comment,
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
                                      onPressed: (action.type == PointActionType.location && pointState.isLocationLoading) 
                                          ? null 
                                          : () => _handlePointAction(
                                                ref,
                                                context,
                                                action,
                                              ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: (action.type == PointActionType.location && pointState.isLocationLoading)
                                            ? Colors.blue.shade400
                                            : Colors.blue,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                      ),
                                      child: (action.type == PointActionType.location && pointState.isLocationLoading)
                                          ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                              ),
                                            )
                                          : const Text('実行'),
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
  ) async {
    switch (action.type) {
      case PointActionType.location:
        // 位置情報取得の実際の処理
        final success = await ref.read(pointProvider.notifier).getLocationAndEarnPoints();
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${action.title}完了！+${action.points}pt獲得'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
        break;
      case PointActionType.event:
      case PointActionType.product:
      case PointActionType.socialComment:
        // その他のアクションは通知付きポイント獲得
        await ref.read(pointProvider.notifier).addPointsWithNotification(
          action.points,
          '${action.title}完了！',
          action.description,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${action.title}完了！+${action.points}pt獲得'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        break;
    }
  }

  void _handleSocialAction(
    WidgetRef ref,
    BuildContext context,
    SocialPlatformInfo platform,
  ) async {
    await ref.read(pointProvider.notifier).addPointsWithNotification(
      platform.points,
      '${platform.name}投稿完了！',
      '地域に関するコメントを投稿しました',
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${platform.name}でコメント投稿完了！+${platform.points}pt獲得'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
