import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'location_service_lite.dart';

// ===== Domain Layer =====

/// ローカル位置履歴データモデル
class LocalLocationHistoryItem {
  final String id;
  final double latitude;
  final double longitude;
  final String? address;
  final DateTime timestamp;
  final double accuracy;

  const LocalLocationHistoryItem({
    required this.id,
    required this.latitude,
    required this.longitude,
    this.address,
    required this.timestamp,
    required this.accuracy,
  });

  /// LocationDataLiteから変換
  factory LocalLocationHistoryItem.fromLocationData(LocationDataLite locationData) {
    return LocalLocationHistoryItem(
      id: '${locationData.timestamp.millisecondsSinceEpoch}',
      latitude: locationData.latitude,
      longitude: locationData.longitude,
      address: locationData.address,
      timestamp: locationData.timestamp,
      accuracy: locationData.accuracy,
    );
  }

  /// JSONから変換
  factory LocalLocationHistoryItem.fromJson(Map<String, dynamic> json) {
    return LocalLocationHistoryItem(
      id: json['id'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      address: json['address'] as String?,
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int),
      accuracy: (json['accuracy'] as num).toDouble(),
    );
  }

  /// JSONに変換
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'accuracy': accuracy,
    };
  }
}

// ===== Data Layer =====

/// 軽量なローカルストレージデータ管理サービス
class LocalStorageServiceLite {
  static LocalStorageServiceLite? _instance;
  static LocalStorageServiceLite get instance => _instance ??= LocalStorageServiceLite._();
  LocalStorageServiceLite._();

  static const String _locationHistoryKey = 'location_history';

  /// 位置履歴をローカルに保存
  Future<bool> saveLocationHistory(LocationDataLite locationData) async {
    try {
      debugPrint('LocalStorageServiceLite: 位置履歴ローカル保存開始...');
      
      final prefs = await SharedPreferences.getInstance();
      final existingData = prefs.getString(_locationHistoryKey) ?? '[]';
      final List<dynamic> existingList = jsonDecode(existingData);
      
      final newItem = LocalLocationHistoryItem.fromLocationData(locationData);
      existingList.insert(0, newItem.toJson()); // 最新を先頭に
      
      // 最大20件まで保持
      if (existingList.length > 20) {
        existingList.removeLast();
      }
      
      await prefs.setString(_locationHistoryKey, jsonEncode(existingList));
      
      debugPrint('LocalStorageServiceLite: 位置履歴ローカル保存成功');
      return true;
    } catch (e) {
      debugPrint('LocalStorageServiceLite: 位置履歴ローカル保存エラー: $e');
      return false;
    }
  }

  /// 最新の位置履歴を取得
  Future<List<LocalLocationHistoryItem>> getRecentLocationHistory({int limit = 5}) async {
    try {
      debugPrint('LocalStorageServiceLite: 位置履歴ローカル取得開始...');
      
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_locationHistoryKey) ?? '[]';
      final List<dynamic> jsonList = jsonDecode(data);
      
      final items = jsonList
          .take(limit)
          .map((json) => LocalLocationHistoryItem.fromJson(json as Map<String, dynamic>))
          .toList();
      
      debugPrint('LocalStorageServiceLite: 位置履歴ローカル取得成功 (${items.length}件)');
      return items;
    } catch (e) {
      debugPrint('LocalStorageServiceLite: 位置履歴ローカル取得エラー: $e');
      return [];
    }
  }

  /// 位置履歴の件数を取得
  Future<int> getLocationHistoryCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_locationHistoryKey) ?? '[]';
      final List<dynamic> jsonList = jsonDecode(data);
      return jsonList.length;
    } catch (e) {
      debugPrint('LocalStorageServiceLite: 履歴件数取得エラー: $e');
      return 0;
    }
  }

  /// 接続テスト用：ローカルストレージのテスト
  Future<bool> testLocalStorageConnection() async {
    try {
      debugPrint('LocalStorageServiceLite: ローカルストレージテスト開始...');
      
      final prefs = await SharedPreferences.getInstance();
      final testKey = 'test_${DateTime.now().millisecondsSinceEpoch}';
      final testValue = 'Connection test from Flutter';
      
      await prefs.setString(testKey, testValue);
      final retrieved = prefs.getString(testKey);
      await prefs.remove(testKey); // クリーンアップ
      
      debugPrint('LocalStorageServiceLite: ローカルストレージテスト成功');
      return retrieved == testValue;
    } catch (e) {
      debugPrint('LocalStorageServiceLite: ローカルストレージテストエラー: $e');
      return false;
    }
  }
}

// ===== Application Layer (Riverpod Providers) =====

/// ローカルストレージサービスのプロバイダー  
final localStorageServiceLiteProvider = Provider<LocalStorageServiceLite>(
  (ref) => LocalStorageServiceLite.instance,
);

/// 最新ローカル位置履歴取得のプロバイダー
final recentLocalLocationHistoryProvider = FutureProvider.autoDispose<List<LocalLocationHistoryItem>>(
  (ref) async {
    final service = ref.watch(localStorageServiceLiteProvider);
    return await service.getRecentLocationHistory();
  },
);

/// ローカルストレージ接続テストのプロバイダー
final localStorageConnectionTestProvider = FutureProvider.autoDispose<bool>(
  (ref) async {
    final service = ref.watch(localStorageServiceLiteProvider);
    return await service.testLocalStorageConnection();
  },
);