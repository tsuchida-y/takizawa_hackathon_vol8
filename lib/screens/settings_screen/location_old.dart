import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../service/location_service_lite.dart';
import '../../service/local_storage_service_lite.dart';

// ===== Presentation Layer =====

/// 位置情報設定画面（軽量版統合）
class LocationScreen extends ConsumerStatefulWidget {
  const LocationScreen({super.key});

  @override
  ConsumerState<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends ConsumerState<LocationScreen> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationSettings = ref.watch(locationSettingsProvider);
    // 最大パフォーマンス向上のため、条件付きでストリーム監視
    final locationStreamAsync = (locationSettings.isEnabled && locationSettings.backgroundUpdates) 
        ? ref.watch(locationStreamProvider)
        : const AsyncValue.data(null);
    // 現在位置は必要時のみ取得
    final currentLocationAsync = locationSettings.isEnabled 
        ? ref.watch(currentLocationProvider)
        : const AsyncValue.data(null);

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
            // 現在の位置情報表示
            _buildLocationInfoCard(currentLocationAsync, locationStreamAsync),
            const SizedBox(height: 16),
            
            // 位置情報設定
            _buildSettingsCard(context, ref, locationSettings),
            const SizedBox(height: 16),
            
            // 位置情報取得ボタン
            _buildActionButtons(context, ref),
          ],
        ),
      ),
    );
  }

  /// 位置情報表示カード
  Widget _buildLocationInfoCard(
    AsyncValue<LocationData?> currentLocation,
    AsyncValue<LocationData?> locationStream,
  ) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: Colors.blue.shade600,
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  '現在の位置情報',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // リアルタイム位置情報の表示（パフォーマンス最適化）
            locationStream.when(
              data: (location) => location != null 
                  ? _buildLocationInfo(location, isRealtime: true)
                  : currentLocation.when(
                      data: (location) => location != null 
                          ? _buildLocationInfo(location, isRealtime: false)
                          : const Text('位置情報が取得されていません'),
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (error, stack) => Text('エラー: $error', style: TextStyle(color: Colors.red.shade600))
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => currentLocation.when(
                data: (location) => location != null 
                    ? _buildLocationInfo(location, isRealtime: false)
                    : Text('エラー: $error', style: TextStyle(color: Colors.red.shade600)),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Text('エラー: $error', style: TextStyle(color: Colors.red.shade600))
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 位置情報詳細表示
  Widget _buildLocationInfo(LocationData location, {required bool isRealtime}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isRealtime)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.radio_button_checked,
                  color: Colors.green.shade600,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  'リアルタイム更新中',
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        
        _buildInfoRow('緯度', location.latitude.toStringAsFixed(6)),
        _buildInfoRow('経度', location.longitude.toStringAsFixed(6)),
        if (location.address != null)
          _buildInfoRow('住所', location.address!),
        if (location.accuracy != null)
          _buildInfoRow('精度', '${location.accuracy!.toStringAsFixed(1)}m'),
        _buildInfoRow('取得時刻', 
          '${location.timestamp.hour.toString().padLeft(2, '0')}:'
          '${location.timestamp.minute.toString().padLeft(2, '0')}:'
          '${location.timestamp.second.toString().padLeft(2, '0')}'
        ),
      ],
    );
  }

  /// 情報行の表示
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 設定カード
  Widget _buildSettingsCard(
    BuildContext context,
    WidgetRef ref,
    AppLocationSettings settings,
  ) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '位置情報設定',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            
            // 位置情報有効/無効
            SwitchListTile(
              title: const Text('位置情報サービス'),
              subtitle: const Text('アプリで位置情報を使用'),
              value: settings.isEnabled,
              onChanged: (value) {
                ref.read(locationSettingsProvider.notifier).updateEnabled(value);
              },
              contentPadding: EdgeInsets.zero,
            ),
            
            // バックグラウンド更新
            SwitchListTile(
              title: const Text('バックグラウンド更新'),
              subtitle: const Text('アプリが非アクティブ時も位置情報を更新'),
              value: settings.backgroundUpdates,
              onChanged: settings.isEnabled ? (value) {
                ref.read(locationSettingsProvider.notifier).updateBackgroundUpdates(value);
              } : null,
              contentPadding: EdgeInsets.zero,
            ),
            
            // 住所取得設定
            SwitchListTile(
              title: const Text('住所自動取得'),
              subtitle: const Text('位置情報から住所を自動取得（通信を使用）'),
              value: settings.enableAddressLookup,
              onChanged: settings.isEnabled ? (value) {
                ref.read(locationSettingsProvider.notifier).updateAddressLookup(value);
              } : null,
              contentPadding: EdgeInsets.zero,
            ),
            
            const SizedBox(height: 16),
            
            // 精度設定
            Text(
              '位置情報の精度',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            _buildAccuracyOptions(ref, settings),
            
            const SizedBox(height: 16),
            
            // 更新間隔
            Text(
              '更新間隔: ${settings.updateInterval}秒',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Slider(
              value: settings.updateInterval.toDouble(),
              min: 5,
              max: 300,
              divisions: 11,
              label: '${settings.updateInterval}秒',
              onChanged: settings.isEnabled ? (value) {
                ref.read(locationSettingsProvider.notifier).updateInterval(value.round());
              } : null,
            ),
          ],
        ),
      ),
    );
  }

  /// 精度オプション
  Widget _buildAccuracyOptions(WidgetRef ref, AppLocationSettings settings) {
    final accuracyOptions = [
      (LocationAccuracy.lowest, '低精度（省電力）'),
      (LocationAccuracy.low, '低精度'),
      (LocationAccuracy.medium, '中精度'),
      (LocationAccuracy.high, '高精度'),
      (LocationAccuracy.best, '最高精度'),
      (LocationAccuracy.bestForNavigation, 'ナビゲーション用'),
    ];

    return Column(
      children: accuracyOptions.map((option) {
        return RadioListTile<LocationAccuracy>(
          title: Text(option.$2),
          value: option.$1,
          groupValue: settings.accuracy,
          onChanged: settings.isEnabled ? (value) {
            if (value != null) {
              ref.read(locationSettingsProvider.notifier).updateAccuracy(value);
            }
          } : null,
          contentPadding: EdgeInsets.zero,
          dense: true,
        );
      }).toList(),
    );
  }

  /// アクションボタン
  Widget _buildActionButtons(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              ref.invalidate(currentLocationProvider);
            },
            icon: const Icon(Icons.my_location),
            label: const Text('現在の位置情報を取得'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _showLocationPermissionDialog(context, ref),
            icon: const Icon(Icons.settings),
            label: const Text('権限設定を開く'),
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

  /// 権限設定ダイアログ
  void _showLocationPermissionDialog(BuildContext context, WidgetRef ref) {
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
              final repository = ref.read(locationRepositoryProvider);
              await repository.requestLocationPermission();
            },
            child: const Text('権限をリクエスト'),
          ),
        ],
      ),
    );
  }
}