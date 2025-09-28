import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Firebase接続状態管理（軽量版）
class FirebaseStatusService {
  static FirebaseStatusService? _instance;
  static FirebaseStatusService get instance => _instance ??= FirebaseStatusService._();
  FirebaseStatusService._();

  /// Firebase初期化状態を確認
  bool get isInitialized {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (e) {
      debugPrint('Firebase状態確認エラー: $e');
      return false;
    }
  }

  /// Firebase接続情報を取得
  Map<String, dynamic> getConnectionInfo() {
    try {
      if (!isInitialized) {
        return {
          'status': 'disconnected',
          'message': 'Firebase未初期化',
          'apps_count': 0,
        };
      }

      final app = Firebase.app();
      return {
        'status': 'connected',
        'message': 'Firebase接続中',
        'project_id': app.options.projectId,
        'app_id': app.options.appId,
        'apps_count': Firebase.apps.length,
      };
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Firebase接続エラー: $e',
        'apps_count': 0,
      };
    }
  }
}

// ===== Riverpod Providers =====

/// Firebase状態サービスのプロバイダー
final firebaseStatusServiceProvider = Provider<FirebaseStatusService>(
  (ref) => FirebaseStatusService.instance,
);

/// Firebase接続状態のプロバイダー
final firebaseConnectionInfoProvider = Provider<Map<String, dynamic>>(
  (ref) {
    final service = ref.watch(firebaseStatusServiceProvider);
    return service.getConnectionInfo();
  },
);