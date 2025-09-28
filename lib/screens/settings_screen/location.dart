import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../service/location_service_lite.dart';
import '../../service/local_storage_service_lite.dart';

/// 統合された位置情報設定画面
class LocationScreen extends ConsumerStatefulWidget {
  const LocationScreen({super.key});

  @override
  ConsumerState<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends ConsumerState<LocationScreen>
    with TickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locationAvailability = ref.watch(locationAvailabilityProvider);
    final manualLocation = ref.watch(manualLocationProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          '位置情報設定',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // サービス状態カード
            _buildServiceStatusCard(locationAvailability),
            const SizedBox(height: 16),
            
            // 現在位置カード
            _buildCurrentLocationCard(manualLocation),
            const SizedBox(height: 16),
            
            // アクションボタン
            _buildActionButtons(context, ref, manualLocation),
            const SizedBox(height: 16),
            
            // 履歴・詳細設定（展開可能）
            _buildExpandableSection(context, ref),
          ],
        ),
      ),
    );
  }

  /// サービス状態カード
  Widget _buildServiceStatusCard(AsyncValue<bool> locationAvailability) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.location_searching,
                    color: Colors.blue.shade600,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    '位置情報サービス',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            locationAvailability.when(
              data: (available) => _buildStatusIndicator(
                available ? '利用可能' : '利用不可',
                available ? Colors.green : Colors.red,
                available ? Icons.check_circle : Icons.error,
              ),
              loading: () => _buildStatusIndicator(
                '確認中...',
                Colors.orange,
                Icons.hourglass_empty,
              ),
              error: (error, _) => _buildStatusIndicator(
                'エラー',
                Colors.red,
                Icons.error,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 状態インジケータ
  Widget _buildStatusIndicator(String text, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  /// 現在位置カード
  Widget _buildCurrentLocationCard(AsyncValue<LocationDataLite?> manualLocation) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.my_location,
                    color: Colors.green.shade600,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    '現在の位置',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            manualLocation.when(
              data: (location) => location != null
                  ? _buildLocationDetails(location)
                  : _buildNoLocationMessage(),
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, _) => _buildErrorMessage(error.toString()),
            ),
          ],
        ),
      ),
    );
  }

  /// 位置詳細表示
  Widget _buildLocationDetails(LocationDataLite location) {
    return Column(
      children: [
        _buildLocationRow(
          '住所',
          location.address ?? '取得中...',
          Icons.location_on,
          Colors.red,
        ),
        const SizedBox(height: 12),
        _buildLocationRow(
          '緯度',
          location.latitude.toStringAsFixed(6),
          Icons.navigation,
          Colors.blue,
        ),
        const SizedBox(height: 12),
        _buildLocationRow(
          '経度',
          location.longitude.toStringAsFixed(6),
          Icons.navigation,
          Colors.blue,
        ),
        const SizedBox(height: 12),
        _buildLocationRow(
          '精度',
          '${location.accuracy.toStringAsFixed(1)}m',
          Icons.gps_fixed,
          Colors.orange,
        ),
        const SizedBox(height: 12),
        _buildLocationRow(
          '取得時刻',
          _formatTimestamp(location.timestamp),
          Icons.access_time,
          Colors.grey,
        ),
      ],
    );
  }

  /// 位置情報行
  Widget _buildLocationRow(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 位置情報なしメッセージ
  Widget _buildNoLocationMessage() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            Icons.location_off,
            color: Colors.grey.shade400,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            '位置情報が取得されていません',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '下のボタンから現在位置を取得してください',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  /// エラーメッセージ
  Widget _buildErrorMessage(String error) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error, color: Colors.red.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'エラー: $error',
              style: TextStyle(color: Colors.red.shade700),
            ),
          ),
        ],
      ),
    );
  }

  /// アクションボタン
  Widget _buildActionButtons(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<LocationDataLite?> manualLocation,
  ) {
    return Column(
      children: [
        // 位置取得ボタン
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: manualLocation.isLoading ? null : () {
              // 住所も同時に取得
              ref.read(manualLocationProvider.notifier).refreshLocationWithAddress();
            },
            icon: manualLocation.isLoading 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.my_location),
            label: Text(manualLocation.isLoading ? '取得中...' : '現在位置を取得'),
            style: ElevatedButton.styleFrom(
              backgroundColor: manualLocation.isLoading 
                  ? Colors.blue.shade400 
                  : Colors.blue.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // ローカル保存ボタン（位置情報がある場合のみ表示）
        if (manualLocation.hasValue && manualLocation.value != null)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                final location = manualLocation.value!;
                final localService = LocalStorageServiceLite.instance;
                final success = await localService.saveLocationHistory(location);
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? '位置履歴を保存しました' : '保存に失敗しました'),
                      backgroundColor: success ? Colors.green : Colors.red,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.save_alt),
              label: const Text('履歴に保存'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
      ],
    );
  }

  /// 展開可能セクション
  Widget _buildExpandableSection(BuildContext context, WidgetRef ref) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
                if (_isExpanded) {
                  _animationController.forward();
                } else {
                  _animationController.reverse();
                }
              });
            },
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.history,
                      color: Colors.purple.shade600,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      '履歴と詳細設定',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      Icons.expand_more,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizeTransition(
            sizeFactor: _expandAnimation,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                children: [
                  const Divider(),
                  const SizedBox(height: 16),
                  _buildExpandedContent(context, ref),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 展開コンテンツ
  Widget _buildExpandedContent(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        // 履歴表示ボタン
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _showLocationHistoryDialog(context),
            icon: const Icon(Icons.list_alt),
            label: const Text('位置履歴を表示'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // 権限設定ボタン
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _showPermissionDialog(context, ref),
            icon: const Icon(Icons.settings),
            label: const Text('権限設定'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 位置履歴ダイアログ
  void _showLocationHistoryDialog(BuildContext context) async {
    final localService = LocalStorageServiceLite.instance;
    final history = await localService.getRecentLocationHistory(limit: 10);
    final totalCount = await localService.getLocationHistoryCount();

    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('位置履歴'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '保存された履歴: $totalCount件',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: history.isEmpty
                      ? const Center(
                          child: Text('履歴がありません'),
                        )
                      : ListView.builder(
                          itemCount: history.length,
                          itemBuilder: (context, index) {
                            final item = history[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: Icon(
                                  Icons.location_on,
                                  color: Colors.red.shade400,
                                ),
                                title: Text(
                                  item.address ?? '住所不明',
                                  style: const TextStyle(fontSize: 14),
                                ),
                                subtitle: Text(
                                  '${item.latitude.toStringAsFixed(4)}, ${item.longitude.toStringAsFixed(4)}\n'
                                  '${_formatTimestamp(item.timestamp)}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                isThreeLine: true,
                                dense: true,
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('閉じる'),
            ),
            if (history.isNotEmpty)
              TextButton(
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove('location_history');
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('履歴をクリアしました'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                child: const Text('クリア', style: TextStyle(color: Colors.red)),
              ),
          ],
        ),
      );
    }
  }

  /// 権限設定ダイアログ
  void _showPermissionDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('位置情報の権限設定'),
        content: const Text(
          '位置情報を正常に取得するには、アプリの権限設定で位置情報へのアクセスを許可してください。\n\n'
          '設定 > アプリ > takizawa_hackathon_vol8 > 権限 > 位置情報',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final repo = ref.read(locationRepositoryLiteProvider);
              await repo.getCurrentLocation();
            },
            child: const Text('権限をリクエスト'),
          ),
        ],
      ),
    );
  }

  /// タイムスタンプフォーマット
  String _formatTimestamp(DateTime timestamp) {
    return '${timestamp.month}/${timestamp.day} '
        '${timestamp.hour.toString().padLeft(2, '0')}:'
        '${timestamp.minute.toString().padLeft(2, '0')}';
  }
}