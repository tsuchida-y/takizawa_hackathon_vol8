import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../service/location_service_lite.dart';

/// 軽量版位置情報設定画面
class LocationScreenLite extends ConsumerStatefulWidget {
  const LocationScreenLite({super.key});

  @override
  ConsumerState<LocationScreenLite> createState() => _LocationScreenLiteState();
}

class _LocationScreenLiteState extends ConsumerState<LocationScreenLite> {
  @override
  Widget build(BuildContext context) {
    final locationAvailability = ref.watch(locationAvailabilityProvider);
    final manualLocation = ref.watch(manualLocationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('位置情報設定（軽量版）'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 位置情報の利用可能性
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '位置情報サービス状態',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    locationAvailability.when(
                      data: (available) => Row(
                        children: [
                          Icon(
                            available ? Icons.check_circle : Icons.error,
                            color: available ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            available ? '利用可能' : '利用不可',
                            style: TextStyle(
                              color: available ? Colors.green : Colors.red,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      loading: () => const Row(
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 8),
                          Text('確認中...'),
                        ],
                      ),
                      error: (error, _) => Row(
                        children: [
                          const Icon(Icons.error, color: Colors.red),
                          const SizedBox(width: 8),
                          Text('エラー: $error'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 現在位置取得
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '現在位置',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // 位置情報表示
                    manualLocation.when(
                      data: (location) {
                        if (location == null) {
                          return const Text('位置情報が取得されていません');
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '緯度: ${location.latitude.toStringAsFixed(6)}',
                              style: const TextStyle(fontFamily: 'monospace'),
                            ),
                            Text(
                              '経度: ${location.longitude.toStringAsFixed(6)}',
                              style: const TextStyle(fontFamily: 'monospace'),
                            ),
                            Text(
                              '精度: ${location.accuracy.toStringAsFixed(1)}m',
                              style: const TextStyle(fontFamily: 'monospace'),
                            ),
                            Text(
                              '取得時刻: ${_formatDateTime(location.timestamp)}',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                color: Colors.grey[600],
                              ),
                            ),
                            if (location.address != null) ...[
                              const SizedBox(height: 8),
                              const Divider(),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.location_city, size: 16, color: Colors.blue),
                                  const SizedBox(width: 4),
                                  const Text(
                                    '住所:',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                location.address!,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ],
                        );
                      },
                      loading: () => const Column(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 8),
                          Text('位置情報を取得中...'),
                        ],
                      ),
                      error: (error, _) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.error, color: Colors.red),
                          const SizedBox(height: 8),
                          Text(
                            'エラー: $error',
                            style: const TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // 位置取得ボタン（座標のみ）
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: manualLocation.isLoading ? null : () {
                          ref.read(manualLocationProvider.notifier)
                              .refreshLocation(
                                settings: AppLocationSettingsLite.performance,
                              );
                        },
                        icon: manualLocation.isLoading 
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.my_location),
                        label: Text(manualLocation.isLoading ? '取得中...' : '現在位置を取得'),
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // 位置取得+住所変換ボタン
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: manualLocation.isLoading ? null : () {
                          ref.read(manualLocationProvider.notifier)
                              .refreshLocationWithAddress(
                                settings: AppLocationSettingsLite.performance,
                              );
                        },
                        icon: manualLocation.isLoading 
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.location_city),
                        label: Text(manualLocation.isLoading ? '取得中...' : '位置＋住所を取得'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[600],
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // デバッグ用：権限とサービス状態を個別チェック
                    ElevatedButton.icon(
                      onPressed: () async {
                        final repo = ref.read(locationRepositoryLiteProvider);
                        final available = await repo.isLocationAvailable();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('位置情報利用可能: $available'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.info),
                      label: const Text('権限・サービス状態確認'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[300],
                        foregroundColor: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // パフォーマンス情報
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '軽量版設定',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('• 精度: 最低（パフォーマンス優先）'),
                    const Text('• タイムアウト: 15秒'),
                    const Text('• バックグラウンド: 無効'),
                    const Text('• フィルター距離: 100m'),
                    const SizedBox(height: 8),
                    Text(
                      'スマートフォンでの軽快な動作を重視した設定です',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:'
           '${dateTime.minute.toString().padLeft(2, '0')}:'
           '${dateTime.second.toString().padLeft(2, '0')}';
  }
}