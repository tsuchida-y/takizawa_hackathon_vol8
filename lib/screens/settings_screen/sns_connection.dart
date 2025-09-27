import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ===== Domain Layer =====

/// SNS連携の種類
enum SNSType {
  google('Google', Icons.g_mobiledata, Color(0xFF4285F4)),
  x('X (Twitter)', Icons.close, Color(0xFF000000)),
  instagram('Instagram', Icons.camera_alt, Color(0xFFE4405F)),
  facebook('Facebook', Icons.facebook, Color(0xFF1877F2)),
  line('LINE', Icons.chat_bubble, Color(0xFF00B900)),
  apple('Apple Account', Icons.apple, Color(0xFF000000));

  const SNSType(this.displayName, this.icon, this.color);
  final String displayName;
  final IconData icon;
  final Color color;
}

/// SNS連携状態のモデル
class SNSConnectionStatus {
  final SNSType type;
  final bool isConnected;
  final String? accountName;
  final String? accountId;
  final DateTime? connectedAt;

  const SNSConnectionStatus({
    required this.type,
    required this.isConnected,
    this.accountName,
    this.accountId,
    this.connectedAt,
  });

  SNSConnectionStatus copyWith({
    SNSType? type,
    bool? isConnected,
    String? accountName,
    String? accountId,
    DateTime? connectedAt,
  }) {
    return SNSConnectionStatus(
      type: type ?? this.type,
      isConnected: isConnected ?? this.isConnected,
      accountName: accountName ?? this.accountName,
      accountId: accountId ?? this.accountId,
      connectedAt: connectedAt ?? this.connectedAt,
    );
  }
}

/// すべてのSNS連携状態
class SNSConnectionState {
  final Map<SNSType, SNSConnectionStatus> connections;

  const SNSConnectionState({
    required this.connections,
  });

  SNSConnectionState copyWith({
    Map<SNSType, SNSConnectionStatus>? connections,
  }) {
    return SNSConnectionState(
      connections: connections ?? this.connections,
    );
  }

  /// 連携済みのSNS数を取得
  int get connectedCount {
    return connections.values.where((status) => status.isConnected).length;
  }

  /// 特定のSNSの連携状態を取得
  SNSConnectionStatus getConnectionStatus(SNSType type) {
    return connections[type] ?? SNSConnectionStatus(type: type, isConnected: false);
  }
}

// ===== Data Layer =====

/// SNS連携のリポジトリ
class SNSRepository {
  /// 初期のSNS連携状態を取得
  SNSConnectionState getInitialConnectionState() {
    final connections = <SNSType, SNSConnectionStatus>{};
    
    for (final snsType in SNSType.values) {
      connections[snsType] = SNSConnectionStatus(
        type: snsType,
        isConnected: false,
      );
    }

    return SNSConnectionState(connections: connections);
  }

  /// SNS連携を実行（ダミー実装）
  Future<bool> connectSNS(SNSType type) async {
    debugPrint('${type.displayName}との連携を開始...');
    
    // 実際の連携処理をシミュレート
    await Future.delayed(const Duration(seconds: 2));
    
    // ダミーデータでの成功シミュレーション
    debugPrint('${type.displayName}との連携が完了しました');
    return true; // 実際はOAuth認証の結果
  }

  /// SNS連携を解除（ダミー実装）
  Future<bool> disconnectSNS(SNSType type) async {
    debugPrint('${type.displayName}との連携を解除...');
    
    // 実際の解除処理をシミュレート
    await Future.delayed(const Duration(seconds: 1));
    
    debugPrint('${type.displayName}との連携を解除しました');
    return true;
  }

  /// アカウント情報を取得（ダミー実装）
  Map<String, String> getAccountInfo(SNSType type) {
    // 実際はAPIから取得
    switch (type) {
      case SNSType.google:
        return {'name': 'test.user@gmail.com', 'id': 'google_123456'};
      case SNSType.x:
        return {'name': '@testuser', 'id': 'x_789012'};
      case SNSType.instagram:
        return {'name': 'test_insta', 'id': 'instagram_345678'};
      case SNSType.facebook:
        return {'name': 'Test User', 'id': 'facebook_901234'};
      case SNSType.line:
        return {'name': 'テストユーザー', 'id': 'line_567890'};
      case SNSType.apple:
        return {'name': 'Apple ID User', 'id': 'apple_123789'};
    }
  }
}

// ===== Application Layer =====

/// SNS連携のプロバイダー
final snsRepositoryProvider = Provider<SNSRepository>(
  (ref) => SNSRepository(),
);

/// SNS連携状態の管理
class SNSConnectionNotifier extends StateNotifier<SNSConnectionState> {
  final SNSRepository _repository;

  SNSConnectionNotifier(this._repository) : super(_repository.getInitialConnectionState());

  /// SNSとの連携を実行
  Future<bool> connectSNS(SNSType type) async {
    final success = await _repository.connectSNS(type);
    
    if (success) {
      final accountInfo = _repository.getAccountInfo(type);
      final updatedConnections = Map<SNSType, SNSConnectionStatus>.from(state.connections);
      
      updatedConnections[type] = SNSConnectionStatus(
        type: type,
        isConnected: true,
        accountName: accountInfo['name'],
        accountId: accountInfo['id'],
        connectedAt: DateTime.now(),
      );
      
      state = SNSConnectionState(connections: updatedConnections);
    }
    
    return success;
  }

  /// SNSとの連携を解除
  Future<bool> disconnectSNS(SNSType type) async {
    final success = await _repository.disconnectSNS(type);
    
    if (success) {
      final updatedConnections = Map<SNSType, SNSConnectionStatus>.from(state.connections);
      
      updatedConnections[type] = SNSConnectionStatus(
        type: type,
        isConnected: false,
      );
      
      state = SNSConnectionState(connections: updatedConnections);
    }
    
    return success;
  }
}

/// SNS連携状態のStateNotifierProvider
final snsConnectionProvider = StateNotifierProvider<SNSConnectionNotifier, SNSConnectionState>(
  (ref) {
    final repository = ref.watch(snsRepositoryProvider);
    return SNSConnectionNotifier(repository);
  },
);

// ===== Presentation Layer =====

/// SNS連携画面
class SNSConnectionScreen extends ConsumerWidget {
  const SNSConnectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionState = ref.watch(snsConnectionProvider);
    final notifier = ref.read(snsConnectionProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'SNS連携',
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
          // 説明セクション
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade600),
                    const SizedBox(width: 8),
                    Text(
                      'SNS連携について',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'SNSアカウントと連携することで、以下の機能が利用できます：\n'
                  '• 簡単ログイン機能\n'
                  '• プロフィール情報の同期\n'
                  '• SNSへの投稿連携',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 連携状況サマリー
          Container(
            padding: const EdgeInsets.all(16),
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
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.link,
                    color: Colors.green.shade600,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '連携済みアカウント',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${connectionState.connectedCount} / ${SNSType.values.length} 件',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: connectionState.connectedCount > 0 
                        ? Colors.green.shade100 
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    connectionState.connectedCount > 0 ? '連携中' : '未連携',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: connectionState.connectedCount > 0 
                          ? Colors.green.shade700 
                          : Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // SNS連携リスト
          ...SNSType.values.map((snsType) {
            final status = connectionState.getConnectionStatus(snsType);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildSNSConnectionCard(
                context,
                status,
                onConnect: () => _connectSNS(context, notifier, snsType),
                onDisconnect: () => _disconnectSNS(context, notifier, snsType),
              ),
            );
          }).toList(),

          const SizedBox(height: 32),

          // 注意事項
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
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
                  '• SNS連携時には各サービスの利用規約に同意が必要です\n'
                  '• 連携を解除してもアカウント情報は保持されます\n'
                  '• 連携情報は安全に暗号化して保存されます',
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

  /// SNS連携カードを構築
  Widget _buildSNSConnectionCard(
    BuildContext context,
    SNSConnectionStatus status, {
    required VoidCallback onConnect,
    required VoidCallback onDisconnect,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: status.isConnected 
            ? Border.all(color: Colors.green.shade300, width: 1.5)
            : Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: status.type.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            status.type.icon,
            color: status.type.color,
            size: 24,
          ),
        ),
        title: Text(
          status.type.displayName,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        subtitle: status.isConnected
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    status.accountName ?? '',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (status.connectedAt != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      '連携日: ${_formatDate(status.connectedAt!)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ],
              )
            : const Text(
                '未連携',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
        trailing: ElevatedButton(
          onPressed: status.isConnected ? onDisconnect : onConnect,
          style: ElevatedButton.styleFrom(
            backgroundColor: status.isConnected 
                ? Colors.red.shade100 
                : status.type.color,
            foregroundColor: status.isConnected 
                ? Colors.red.shade700 
                : Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            minimumSize: const Size(80, 36),
          ),
          child: Text(
            status.isConnected ? '解除' : '連携',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  /// 日付をフォーマット
  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }

  /// SNS連携を実行
  Future<void> _connectSNS(
    BuildContext context,
    SNSConnectionNotifier notifier,
    SNSType snsType,
  ) async {
    // ローディングダイアログを表示
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('${snsType.displayName}と連携中...'),
          ],
        ),
      ),
    );

    final success = await notifier.connectSNS(snsType);

    if (!context.mounted) return;
    Navigator.of(context).pop(); // ローディングダイアログを閉じる

    // 結果を表示
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success 
              ? '${snsType.displayName}との連携が完了しました' 
              : '${snsType.displayName}との連携に失敗しました',
        ),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  /// SNS連携を解除
  Future<void> _disconnectSNS(
    BuildContext context,
    SNSConnectionNotifier notifier,
    SNSType snsType,
  ) async {
    // 確認ダイアログを表示
    final shouldDisconnect = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${snsType.displayName}との連携解除'),
        content: Text('${snsType.displayName}との連携を解除しますか？\n解除後は再度連携が必要になります。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('解除'),
          ),
        ],
      ),
    );

    if (shouldDisconnect != true) return;

    // ローディングダイアログを表示
    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('${snsType.displayName}との連携を解除中...'),
          ],
        ),
      ),
    );

    await notifier.disconnectSNS(snsType);

    if (!context.mounted) return;
    Navigator.of(context).pop(); // ローディングダイアログを閉じる

    // 結果を表示
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${snsType.displayName}との連携を解除しました'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}