import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../service/location_service_lite.dart';
import '../../service/firestore_service_lite.dart';
import '../../service/local_storage_service_lite.dart';

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
                    
                    // ローカル履歴保存ボタン（現在の位置情報がある場合のみ表示）
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
                                  content: Text(success ? 'ローカル履歴を保存しました' : 'ローカル履歴保存に失敗しました'),
                                  backgroundColor: success ? Colors.green : Colors.red,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.save_alt),
                          label: const Text('ローカル履歴に保存'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[600],
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    
                    const SizedBox(height: 8),
                    
                    // Firestore接続テストボタン
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final service = ref.read(firestoreServiceLiteProvider);
                          final success = await service.testFirestoreConnection();
                          
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(success ? 'Firestore接続成功' : 'Firestore接続失敗'),
                                backgroundColor: success ? Colors.green : Colors.red,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.cloud_sync),
                        label: const Text('Firestore接続テスト'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[600],
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // ローカル履歴表示ボタン
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final localService = LocalStorageServiceLite.instance;
                          final history = await localService.getRecentLocationHistory(limit: 10);
                          final totalCount = await localService.getLocationHistoryCount();
                          
                          if (context.mounted) {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('ローカル履歴'),
                                content: SizedBox(
                                  width: double.maxFinite,
                                  height: 400,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('統計: 合計${totalCount}件の履歴があります'),
                                      const SizedBox(height: 16),
                                      const Text('最新の履歴:', style: TextStyle(fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 8),
                                      Expanded(
                                        child: ListView.builder(
                                          itemCount: history.length,
                                          itemBuilder: (context, index) {
                                            final item = history[index];
                                            return Card(
                                              child: ListTile(
                                                leading: const Icon(Icons.location_on),
                                                title: Text(item.address ?? '住所不明'),
                                                subtitle: Text(
                                                  '${item.latitude.toStringAsFixed(6)}, ${item.longitude.toStringAsFixed(6)}\n'
                                                  '${item.timestamp.toString().substring(0, 19)}',
                                                ),
                                                isThreeLine: true,
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
                                  TextButton(
                                    onPressed: () async {
                                      final prefs = await SharedPreferences.getInstance();
                                      final clearSuccess = await prefs.remove('location_history');
                                      if (context.mounted) {
                                        Navigator.of(context).pop();
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(clearSuccess ? '履歴をクリアしました' : '履歴クリアに失敗しました'),
                                            backgroundColor: clearSuccess ? Colors.green : Colors.red,
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
                        },
                        icon: const Icon(Icons.history),
                        label: const Text('ローカル履歴表示'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple[600],
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
            
            // 位置履歴表示
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '最近の位置履歴',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    Consumer(
                      builder: (context, ref, child) {
                        final historyAsync = ref.watch(recentLocationHistoryProvider);
                        
                        return historyAsync.when(
                          data: (history) {
                            if (history.isEmpty) {
                              return const Text('履歴がありません');
                            }
                            
                            return Column(
                              children: history.take(3).map((item) => 
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.history, size: 16),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.address ?? '${item.latitude.toStringAsFixed(4)}, ${item.longitude.toStringAsFixed(4)}',
                                              style: const TextStyle(fontSize: 12),
                                            ),
                                            Text(
                                              _formatDateTime(item.timestamp),
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ).toList(),
                            );
                          },
                          loading: () => const Text('履歴読み込み中...'),
                          error: (error, _) => Text('履歴読み込みエラー: $error'),
                        );
                      },
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
                    const Text('• Firebase: Firestore連携'),
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