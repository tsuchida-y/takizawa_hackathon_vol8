import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'location_service_lite.dart';

// ===== Domain Layer =====

/// 位置履歴データモデル
class LocationHistoryItem {
  final String id;
  final double latitude;
  final double longitude;
  final String? address;
  final DateTime timestamp;
  final double accuracy;

  const LocationHistoryItem({
    required this.id,
    required this.latitude,
    required this.longitude,
    this.address,
    required this.timestamp,
    required this.accuracy,
  });

  /// LocationDataLiteから変換
  factory LocationHistoryItem.fromLocationData(LocationDataLite locationData) {
    return LocationHistoryItem(
      id: '${locationData.timestamp.millisecondsSinceEpoch}',
      latitude: locationData.latitude,
      longitude: locationData.longitude,
      address: locationData.address,
      timestamp: locationData.timestamp,
      accuracy: locationData.accuracy,
    );
  }

  /// Firestoreドキュメントから変換
  factory LocationHistoryItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LocationHistoryItem(
      id: doc.id,
      latitude: (data['latitude'] as num).toDouble(),
      longitude: (data['longitude'] as num).toDouble(),
      address: data['address'] as String?,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      accuracy: (data['accuracy'] as num).toDouble(),
    );
  }

  /// Firestoreドキュメント用のマップに変換
  Map<String, dynamic> toFirestore() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'timestamp': Timestamp.fromDate(timestamp),
      'accuracy': accuracy,
    };
  }
}

// ===== Data Layer =====

/// 軽量なFirestoreデータ管理サービス
class FirestoreServiceLite {
  static FirestoreServiceLite? _instance;
  static FirestoreServiceLite get instance => _instance ??= FirestoreServiceLite._();
  FirestoreServiceLite._();

  /// Firestoreインスタンス
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  /// 位置履歴コレクション名
  static const String _locationHistoryCollection = 'location_history';

  /// 位置履歴を保存（軽量版）
  Future<bool> saveLocationHistory(LocationDataLite locationData) async {
    try {
      debugPrint('FirestoreServiceLite: 位置履歴保存開始...');
      
      final historyItem = LocationHistoryItem.fromLocationData(locationData);
      
      await _firestore
          .collection(_locationHistoryCollection)
          .doc(historyItem.id)
          .set(historyItem.toFirestore());
      
      debugPrint('FirestoreServiceLite: 位置履歴保存成功');
      return true;
    } catch (e) {
      debugPrint('FirestoreServiceLite: 位置履歴保存エラー: $e');
      return false;
    }
  }

  /// 最新の位置履歴を取得（軽量版）
  Future<List<LocationHistoryItem>> getRecentLocationHistory({int limit = 5}) async {
    try {
      debugPrint('FirestoreServiceLite: 位置履歴取得開始...');
      
      final querySnapshot = await _firestore
          .collection(_locationHistoryCollection)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();
      
      final items = querySnapshot.docs
          .map((doc) => LocationHistoryItem.fromFirestore(doc))
          .toList();
      
      debugPrint('FirestoreServiceLite: 位置履歴取得成功 (${items.length}件)');
      return items;
    } catch (e) {
      debugPrint('FirestoreServiceLite: 位置履歴取得エラー: $e');
      return [];
    }
  }

  /// 位置履歴の件数を取得
  Future<int> getLocationHistoryCount() async {
    try {
      final querySnapshot = await _firestore
          .collection(_locationHistoryCollection)
          .count()
          .get();
      
      return querySnapshot.count ?? 0;
    } catch (e) {
      debugPrint('FirestoreServiceLite: 履歴件数取得エラー: $e');
      return 0;
    }
  }

  /// 接続テスト用：簡単なドキュメント書き込み
  Future<bool> testFirestoreConnection() async {
    try {
      debugPrint('FirestoreServiceLite: 接続テスト開始...');
      
      await _firestore
          .collection('connection_test')
          .doc('test_${DateTime.now().millisecondsSinceEpoch}')
          .set({
            'message': 'Connection test from Flutter',
            'timestamp': FieldValue.serverTimestamp(),
            'device': 'Android',
          });
      
      debugPrint('FirestoreServiceLite: 接続テスト成功');
      return true;
    } catch (e) {
      debugPrint('FirestoreServiceLite: 接続テストエラー: $e');
      return false;
    }
  }
}

// ===== Application Layer (Riverpod Providers) =====

/// Firestoreサービスのプロバイダー  
final firestoreServiceLiteProvider = Provider<FirestoreServiceLite>(
  (ref) => FirestoreServiceLite.instance,
);

/// 位置履歴保存の非同期プロバイダー
final saveLocationHistoryProvider = FutureProvider.family.autoDispose<bool, LocationDataLite>(
  (ref, locationData) async {
    final service = ref.watch(firestoreServiceLiteProvider);
    return await service.saveLocationHistory(locationData);
  },
);

/// 最新位置履歴取得のプロバイダー
final recentLocationHistoryProvider = FutureProvider.autoDispose<List<LocationHistoryItem>>(
  (ref) async {
    final service = ref.watch(firestoreServiceLiteProvider);
    return await service.getRecentLocationHistory();
  },
);

/// Firestore接続テストのプロバイダー
final firestoreConnectionTestProvider = FutureProvider.autoDispose<bool>(
  (ref) async {
    final service = ref.watch(firestoreServiceLiteProvider);
    return await service.testFirestoreConnection();
  },
);