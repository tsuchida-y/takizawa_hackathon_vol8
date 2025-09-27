import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:takizawa_hackathon_vol8/screens/pointget.dart';


/// ガチャの景品レアリティを定義する列挙型
/// 各レアリティは排出確率と表示色が異なり、ユーザーの期待値を決定する重要な要素
enum GachaRarity {
  common, // コモン（最も一般的、高確率で排出）
  rare, // レア（やや珍しい、中確率で排出）
  superRare, // スーパーレア（稀少、低確率で排出）
  ultraRare, // ウルトラレア（最高レアリティ、極低確率で排出）
}

/// 各景品のメタデータと排出確率を管理する
class GachaItem {
  final String id; // 景品の一意識別子
  final String name; // 景品の表示名
  final String description; // 景品の詳細説明
  final GachaRarity rarity; // 景品のレアリティ（排出確率に影響）
  final double probability; // 排出確率（0.0 - 1.0の範囲）

  const GachaItem({
    required this.id,
    required this.name,
    required this.description,
    required this.rarity,
    required this.probability,
  });
}

/// ガチャの結果を格納するクラス
/// 単一のガチャ実行結果を表現し、履歴管理やモーダル表示に使用
class GachaResult {
  final GachaItem item; // 獲得した景品
  final DateTime timestamp; // ガチャを実行した日時

  const GachaResult({required this.item, required this.timestamp});
}

/// ガチャの設定を格納するクラス
/// ガチャのコストや回数などのゲームバランスを管理
class GachaConfig {
  final int singleCost; // 1回ガチャのポイントコスト
  final int multiCost; // 連続ガチャのポイントコスト（通常お得に設定）
  final int multiCount; // 連続ガチャの実行回数

  const GachaConfig({
    this.singleCost = 500,
    this.multiCost = 5000,
    this.multiCount = 10,
  });
}

/// ガチャの景品リスト
final gachaItemsProvider = Provider<List<GachaItem>>((ref) {
  return const [
    // コモン (70%)
    GachaItem(
      id: 'item_1',
      name: '地域特産品クーポン',
      description: '地元の美味しい特産品が10%オフになるクーポン',
      rarity: GachaRarity.common,
      probability: 0.25,
    ),
    GachaItem(
      id: 'item_2',
      name: 'カフェ割引券',
      description: '地域のカフェで使える200円割引券',
      rarity: GachaRarity.common,
      probability: 0.25,
    ),
    GachaItem(
      id: 'item_3',
      name: 'コンビニ商品券',
      description: '近隣コンビニで使える500円分の商品券',
      rarity: GachaRarity.common,
      probability: 0.2,
    ),
    // レア (20%)
    GachaItem(
      id: 'item_4',
      name: '地域レストラン割引券',
      description: '人気レストランで使える1000円割引券',
      rarity: GachaRarity.rare,
      probability: 0.12,
    ),
    GachaItem(
      id: 'item_5',
      name: '温泉入浴券',
      description: '地域の温泉施設で使える入浴券',
      rarity: GachaRarity.rare,
      probability: 0.08,
    ),
    // スーパーレア (8%)
    GachaItem(
      id: 'item_6',
      name: '地域イベント参加券',
      description: '限定地域イベントに参加できる特別券',
      rarity: GachaRarity.superRare,
      probability: 0.05,
    ),
    GachaItem(
      id: 'item_7',
      name: '高級特産品セット',
      description: '地域の高級特産品が詰まった特別セット',
      rarity: GachaRarity.superRare,
      probability: 0.03,
    ),
    // ウルトラレア (2%)
    GachaItem(
      id: 'item_8',
      name: '市長との食事券',
      description: '市長と一緒に地域の名店で食事できる権利',
      rarity: GachaRarity.ultraRare,
      probability: 0.01,
    ),
    GachaItem(
      id: 'item_9',
      name: '特別体験ツアー',
      description: '非公開の地域スポットを巡る特別ツアー',
      rarity: GachaRarity.ultraRare,
      probability: 0.01,
    ),
  ];
});

/// ガチャの設定
final gachaConfigProvider = Provider<GachaConfig>((ref) {
  return const GachaConfig();
});

/// ガチャの抽選ロジックを提供するクラス
class GachaService {
  static final Random _random = Random();

  /// ガチャを実行して景品を抽選
  static GachaItem drawGacha(List<GachaItem> items) {
    final randomValue = _random.nextDouble();
    double cumulativeProbability = 0.0;

    for (final item in items) {
      cumulativeProbability += item.probability;
      if (randomValue <= cumulativeProbability) {
        return item;
      }
    }

    // フォールバック（通常は発生しない）
    return items.first;
  }

  /// 複数回ガチャを実行
  static List<GachaItem> drawMultiGacha(List<GachaItem> items, int count) {
    return List.generate(count, (_) => drawGacha(items));
  }
}

/// ガチャマシンの回転アニメーションウィジェット
class GachaAnimation extends StatefulWidget {
  final bool isSpinning;
  final int currentPoints;
  final VoidCallback? onAnimationComplete;

  const GachaAnimation({
    super.key,
    this.isSpinning = false,
    required this.currentPoints,
    this.onAnimationComplete,
  });

  @override
  State<GachaAnimation> createState() => _GachaAnimationState();
}

class _GachaAnimationState extends State<GachaAnimation>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _scaleController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _rotationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _rotationAnimation =
        Tween<double>(
          begin: 0,
          end: 4 * 2 * pi, // 4回転
        ).animate(
          CurvedAnimation(parent: _rotationController, curve: Curves.easeInOut),
        );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _rotationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onAnimationComplete?.call();
      }
    });
  }

  @override
  void didUpdateWidget(GachaAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 新しいガチャが開始された場合
    if (widget.isSpinning && !oldWidget.isSpinning) {
      _startAnimation();
    }
    // ガチャが停止された場合（連続ガチャ対応）
    else if (!widget.isSpinning && oldWidget.isSpinning) {
      _resetAnimation();
    }
  }

  /// アニメーションを開始する
  void _startAnimation() {
    _scaleController.forward();
    _rotationController.forward();
  }

  /// アニメーションをリセットする（連続ガチャ用）
  void _resetAnimation() {
    _rotationController.reset();
    _scaleController.reset();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_rotationAnimation, _scaleAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // ガチャマシン本体
              Transform.rotate(
                angle: _rotationAnimation.value,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        Colors.amber.shade300,
                        Colors.orange.shade400,
                        Colors.red.shade400,
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha:0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha:0.9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.diamond,
                        size: 40,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                ),
              ),
              // ポイント表示（ガチャマシンに重ねて）
              Positioned(
                top: 15,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha:0.9),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha:0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    '${widget.currentPoints}pt',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// ガチャ結果を表示するモーダルウィジェット
class ResultModal extends StatelessWidget {
  final List<GachaResult> results;
  final VoidCallback? onClose;

  const ResultModal({super.key, required this.results, this.onClose});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              results.length == 1 ? 'ガチャ結果' : '${results.length}連ガチャ結果',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: results.length == 1
                  ? _buildSingleResult(results.first)
                  : _buildMultipleResults(),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onClose ?? () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('閉じる'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSingleResult(GachaResult result) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getRarityColor(result.item.rarity).withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getRarityColor(result.item.rarity),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 景品アイコン
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _getRarityColor(result.item.rarity).withValues(alpha:0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.card_giftcard,
              size: 40,
              color: _getRarityColor(result.item.rarity),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            result.item.name,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            result.item.description,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          // レアリティ表示
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: _getRarityColor(result.item.rarity),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _getRarityText(result.item.rarity),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMultipleResults() {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: results.length,
      itemBuilder: (context, index) {
        final result = results[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _getRarityColor(result.item.rarity).withValues(alpha:0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _getRarityColor(result.item.rarity).withValues(alpha:0.5),
            ),
          ),
          child: Row(
            children: [
              // レアリティインジケーター
              Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(
                  color: _getRarityColor(result.item.rarity),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              // 景品アイコン
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getRarityColor(result.item.rarity).withValues(alpha:0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.card_giftcard,
                  size: 20,
                  color: _getRarityColor(result.item.rarity),
                ),
              ),
              const SizedBox(width: 12),
              // 景品情報
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.item.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _getRarityText(result.item.rarity),
                      style: TextStyle(
                        fontSize: 12,
                        color: _getRarityColor(result.item.rarity),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // 順番表示
              Text(
                '${index + 1}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// レアリティに応じた色を取得
  Color _getRarityColor(GachaRarity rarity) {
    switch (rarity) {
      case GachaRarity.common:
        return Colors.grey;
      case GachaRarity.rare:
        return Colors.blue;
      case GachaRarity.superRare:
        return Colors.purple;
      case GachaRarity.ultraRare:
        return Colors.orange;
    }
  }

  /// レアリティのテキストを取得
  String _getRarityText(GachaRarity rarity) {
    switch (rarity) {
      case GachaRarity.common:
        return 'コモン';
      case GachaRarity.rare:
        return 'レア';
      case GachaRarity.superRare:
        return 'スーパーレア';
      case GachaRarity.ultraRare:
        return 'ウルトラレア';
    }
  }
}

/// メインのガチャ画面
class GachaScreen extends ConsumerStatefulWidget {
  const GachaScreen({super.key});

  @override
  ConsumerState<GachaScreen> createState() => _GachaScreenState();
}

class _GachaScreenState extends ConsumerState<GachaScreen> {
  bool _isSpinning = false;
  List<GachaResult> _lastResults = [];

  @override
  Widget build(BuildContext context) {
    final pointState = ref.watch(pointProvider);
    final gachaConfig = ref.watch(gachaConfigProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'ガチャ',
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
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettingsDialog(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // コンテンツ領域
            Expanded(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    const SizedBox(height: 40),

                    // ガチャマシンのアニメーション（ポイント表示付き）
                    GachaAnimation(
                      isSpinning: _isSpinning,
                      currentPoints: pointState.currentPoints,
                      onAnimationComplete: _onAnimationComplete,
                    ),

                    const SizedBox(height: 40),

                    // ガチャボタン
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        children: [
                          // 1回ガチャボタン
                          Container(
                            width: double.infinity,
                            height: 56,
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ElevatedButton(
                              onPressed:
                                  _isSpinning ||
                                      pointState.currentPoints <
                                          gachaConfig.singleCost
                                  ? null
                                  : _performSingleGacha,
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    pointState.currentPoints >=
                                        gachaConfig.singleCost
                                    ? Colors.blue
                                    : Colors.grey.shade400,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (_isSpinning)
                                    const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  else ...[
                                    const Icon(Icons.casino, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      '1回 (${gachaConfig.singleCost}pt)',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),

                          // 10連ガチャボタン
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed:
                                  _isSpinning ||
                                      _getMaxMultiCount(
                                            pointState,
                                            gachaConfig,
                                          ) ==
                                          0
                                  ? null
                                  : _performMultiGacha,
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    _getMaxMultiCount(pointState, gachaConfig) >
                                        0
                                    ? Colors.orange
                                    : Colors.grey.shade400,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (_isSpinning)
                                    const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  else ...[
                                    const Icon(Icons.casino, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${_getMaxMultiCount(pointState, gachaConfig)}回 (${_getMaxMultiCount(pointState, gachaConfig) * gachaConfig.singleCost}pt)',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _getMaxMultiCount(PointState pointState, GachaConfig gachaConfig) {
    final maxMultiCount = (pointState.currentPoints / gachaConfig.singleCost)
        .floor();
    return maxMultiCount > gachaConfig.multiCount
        ? gachaConfig.multiCount
        : maxMultiCount;
  }

  /// 1回ガチャを実行
  void _performSingleGacha() {
    final gachaItems = ref.read(gachaItemsProvider);
    final gachaConfig = ref.read(gachaConfigProvider);

    if (!ref
        .read(pointProvider.notifier)
        .consumePoints(gachaConfig.singleCost)) {
      return;
    }

    setState(() {
      _isSpinning = true;
    });

    // ガチャを実行
    final item = GachaService.drawGacha(gachaItems);
    final result = GachaResult(item: item, timestamp: DateTime.now());

    _lastResults = [result];
  }

  /// 10連ガチャを実行
  void _performMultiGacha() {
    final gachaItems = ref.read(gachaItemsProvider);
    final gachaConfig = ref.read(gachaConfigProvider);
    final pointState = ref.read(pointProvider);

    // 現在のポイントで何回ガチャができるかを計算
    final maxMultiCount = (pointState.currentPoints / gachaConfig.singleCost)
        .floor();
    final actualMultiCount = maxMultiCount > gachaConfig.multiCount
        ? gachaConfig.multiCount
        : maxMultiCount;

    final totalCost = actualMultiCount * gachaConfig.singleCost;

    if (!ref.read(pointProvider.notifier).consumePoints(totalCost)) {
      return;
    }

    setState(() {
      _isSpinning = true;
    });

    // 複数回ガチャを実行
    final items = GachaService.drawMultiGacha(gachaItems, actualMultiCount);
    final results = items
        .map((item) => GachaResult(item: item, timestamp: DateTime.now()))
        .toList();

    _lastResults = results; // 全ての結果を表示用に保存
  }

  /// アニメーション完了時の処理
  /// ガチャの回転アニメーションが完了した際に呼ばれる
  /// ローディング状態を解除し、結果モーダルを表示する
  void _onAnimationComplete() {
    // ローディング状態を解除（重要：これにより連続ガチャが可能になる）
    setState(() {
      _isSpinning = false;
    });

    // 結果が存在する場合、モーダルを表示
    if (_lastResults.isNotEmpty) {
      _showResultModal(_lastResults);
      // 結果表示後、結果データをクリア
      _lastResults = [];
    }
  }

  /// 結果モーダルを表示
  void _showResultModal(List<GachaResult> results) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ResultModal(
        results: results,
        onClose: () => Navigator.of(context).pop(),
      ),
    );
  }

  /// 設定ダイアログを表示
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

  /// レアリティに対応する色を取得するヘルパーメソッド
  /// ユーザー体験向上のため、視覚的にレアリティを区別する
  Color _getRarityColor(GachaRarity rarity) {
    switch (rarity) {
      case GachaRarity.common:
        return Colors.grey; // コモン: グレー（一般的）
      case GachaRarity.rare:
        return Colors.blue; // レア: ブルー（珍しい）
      case GachaRarity.superRare:
        return Colors.purple; // スーパーレア: パープル（稀少）
      case GachaRarity.ultraRare:
        return Colors.orange; // ウルトラレア: オレンジ（最高級）
    }
  }

  /// レアリティに対応するテキストを取得するヘルパーメソッド
  /// 日本語での表示用レアリティ名を提供
  String _getRarityText(GachaRarity rarity) {
    switch (rarity) {
      case GachaRarity.common:
        return 'コモン';
      case GachaRarity.rare:
        return 'レア';
      case GachaRarity.superRare:
        return 'スーパーレア';
      case GachaRarity.ultraRare:
        return 'ウルトラレア';
    }
  }
}