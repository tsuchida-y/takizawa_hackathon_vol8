import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'setting.dart';
import 'package:takizawa_hackathon_vol8/service/location_service_lite.dart';
import 'package:takizawa_hackathon_vol8/service/notification_service.dart';
import 'package:takizawa_hackathon_vol8/providers/user_profile_provider.dart';
import 'package:takizawa_hackathon_vol8/screens/ranking.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
enum SocialPlatform {
  twitter, // X（旧Twitter）での投稿・シェア
  instagram, // Instagramでの写真投稿・ストーリーズ
  facebook, // Facebookでの投稿・シェア
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

  Future<void> addPoints(int points) async {
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
    
    // Firestoreのポイント情報を更新
    try {
      final firestore = FirebaseFirestore.instance;
      const String userId = '1'; // 固定のユーザーID
      final pointsRef = firestore.collection('point').doc(userId);
      
      // 日付ベースの期間ポイントも更新
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
      
      // ドキュメントが存在するか確認し、存在しなければ作成
      final docSnapshot = await pointsRef.get();
      if (!docSnapshot.exists) {
        await pointsRef.set({
          'totalPoint': newTotalPoints,
          'nowPoint': newTotalPoints, // nowPointも追加
          'dayPoint': points,
          'monthPoint': points,
          'yearPoint': points,
          'updatedAt': FieldValue.serverTimestamp(),
          'lastPointDate': today,
        });
      } else {
        // 既存ドキュメントの更新
        await pointsRef.update({
          'totalPoint': newTotalPoints,
          'nowPoint': newTotalPoints, // nowPointも更新
          'dayPoint': FieldValue.increment(points),
          'monthPoint': FieldValue.increment(points),
          'yearPoint': FieldValue.increment(points),
          'updatedAt': FieldValue.serverTimestamp(),
          'lastPointDate': today,
        });
      }
    } catch (e) {
      debugPrint('Firestoreポイント更新エラー: $e');
    }
    
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
  
  /// Firestoreからポイント情報を最新化
  Future<void> refreshPoints() async {
    try {
      final firestore = FirebaseFirestore.instance;
      const String userId = '1'; // 固定のユーザーID
      final pointDoc = await firestore.collection('point').doc(userId).get();
      
      if (pointDoc.exists) {
        final data = pointDoc.data();
        if (data != null) {
          // nowPointを優先的に取得、存在しなければtotalPointを使用
          final points = data.containsKey('nowPoint') ? 
              data['nowPoint'] as int : 
              data.containsKey('totalPoint') ? 
                  data['totalPoint'] as int : 
                  state.currentPoints;
                  
          state = state.copyWith(currentPoints: points);
          
          // プロフィール情報も更新
          _ref.read(sharedUserProfileProvider.notifier).updatePoints(
            points,
            state.currentPoints, // 連続日数
            state.currentPoints, // 最長連続日数
          );
        }
      }
    } catch (e) {
      debugPrint('Firestoreポイント取得エラー: $e');
    }
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

    await addPoints(points);
    
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

/// SNS投稿データのモデル
class SocialPostData {
  final String content;
  final String? imagePath;

  const SocialPostData({required this.content, this.imagePath});
}

/// SNS投稿状態のプロバイダー
final socialPostDataProvider = StateProvider<SocialPostData?>((ref) => null);

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
      platform: SocialPlatform.facebook,
      name: 'Facebook',
      icon: Icons.facebook,
      points: 55,
      color: Colors.blue,
      iconPath: 'lib/icon/Facebook_Logo_Primary.png',
    ),
  ];
});

/// ポイントゲット画面
class PointGetScreen extends ConsumerStatefulWidget {
  const PointGetScreen({super.key});

  @override
  ConsumerState<PointGetScreen> createState() => _PointGetScreenState();
}

class _PointGetScreenState extends ConsumerState<PointGetScreen> {
  @override
  void initState() {
    super.initState();
    
    // 画面表示時にFirestoreからポイント情報を取得
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(pointProvider.notifier).refreshPoints();
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final pointState = ref.watch(pointProvider);
    final pointActions = ref.watch(pointActionsProvider);

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
                      'ポイントゲット',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.settings),
                  ),
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
                                  '1s 1pt',
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

                    // SNS投稿セクション
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
                            'SNS投稿',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // 投稿ボタン
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () =>
                                  _showSocialPostDialog(context, ref),
                              icon: const Icon(Icons.edit, size: 20),
                              label: const Text('投稿を作成'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
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

  Future<void> _handlePointAction(
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

  /// SNS投稿ダイアログを表示
  void _showSocialPostDialog(BuildContext context, WidgetRef ref) {
    final TextEditingController contentController = TextEditingController();
    String? selectedImagePath;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('SNS投稿作成'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 投稿内容入力
                TextField(
                  controller: contentController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: '投稿内容',
                    hintText: '地域の素敵な情報をシェアしよう！',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // 写真選択ボタン
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          // 実際のアプリではimage_pickerを使用
                          setState(() {
                            selectedImagePath = 'ダミー画像パス';
                          });
                        },
                        icon: const Icon(Icons.photo),
                        label: Text(
                          selectedImagePath != null ? '画像選択済み' : '画像を選択',
                        ),
                      ),
                    ),
                    if (selectedImagePath != null) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            selectedImagePath = null;
                          });
                        },
                        icon: const Icon(Icons.close, color: Colors.red),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: contentController.text.isNotEmpty
                  ? () {
                      final postData = SocialPostData(
                        content: contentController.text,
                        imagePath: selectedImagePath,
                      );
                      ref.read(socialPostDataProvider.notifier).state =
                          postData;
                      Navigator.of(context).pop();
                      _showSocialPlatformSelection(context, ref, postData);
                    }
                  : null,
              child: const Text('次へ'),
            ),
          ],
        ),
      ),
    );
  }

  /// SNSプラットフォーム選択ダイアログを表示
  void _showSocialPlatformSelection(
    BuildContext context,
    WidgetRef ref,
    SocialPostData postData,
  ) {
    final socialPlatforms = ref.read(socialPlatformsProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('投稿先を選択'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: socialPlatforms.map((platform) {
            return ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: platform.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: platform.iconPath != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.asset(
                          platform.iconPath!,
                          width: 24,
                          height: 24,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              platform.icon,
                              color: platform.color,
                              size: 20,
                            );
                          },
                        ),
                      )
                    : Icon(platform.icon, color: platform.color, size: 20),
              ),
              title: Text(platform.name),
              subtitle: Text('+${platform.points}pt'),
              onTap: () {
                Navigator.of(context).pop();
                _handleSocialPost(ref, context, platform, postData);
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
        ],
      ),
    );
  }

  /// SNS投稿処理
  Future<void> _handleSocialPost(
    WidgetRef ref,
    BuildContext context,
    SocialPlatformInfo platform,
    SocialPostData postData,
  ) async {
    // 実際のアプリではここで各SNSのAPIを呼び出し
    // 今回はダミー処理

    await ref.read(pointProvider.notifier).addPoints(platform.points);
    ref.read(socialPostDataProvider.notifier).state = null; // 投稿データをクリア

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${platform.name}への投稿が完了しました！+${platform.points}pt獲得'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
