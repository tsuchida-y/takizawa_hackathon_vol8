import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';

// ===== Domain Layer =====

/// 位置情報データのモデル
class LocationData {
  final double latitude;
  final double longitude;
  final String? address;
  final DateTime timestamp;
  final double? accuracy;

  const LocationData({
    required this.latitude,
    required this.longitude,
    this.address,
    required this.timestamp,
    this.accuracy,
  });

  @override
  String toString() {
    return 'LocationData(lat: $latitude, lng: $longitude, address: $address, timestamp: $timestamp)';
  }
}

/// 位置情報設定のモデル
class AppLocationSettings {
  final bool isEnabled;
  final bool backgroundUpdates;
  final LocationAccuracy accuracy;
  final int updateInterval; // 秒
  final bool enableAddressLookup; // 住所取得の有効/無効

  const AppLocationSettings({
    required this.isEnabled,
    required this.backgroundUpdates,
    required this.accuracy,
    required this.updateInterval,
    this.enableAddressLookup = false, // デフォルトで無効
  });

  AppLocationSettings copyWith({
    bool? isEnabled,
    bool? backgroundUpdates,
    LocationAccuracy? accuracy,
    int? updateInterval,
    bool? enableAddressLookup,
  }) {
    return AppLocationSettings(
      isEnabled: isEnabled ?? this.isEnabled,
      backgroundUpdates: backgroundUpdates ?? this.backgroundUpdates,
      accuracy: accuracy ?? this.accuracy,
      updateInterval: updateInterval ?? this.updateInterval,
      enableAddressLookup: enableAddressLookup ?? this.enableAddressLookup,
    );
  }
}

// ===== Data Layer =====

/// 位置情報サービスのリポジトリ
class LocationRepository {
  /// 位置情報の権限を確認
  Future<bool> checkLocationPermission() async {
    final permission = await Permission.location.status;
    return permission.isGranted;
  }

  /// 位置情報の権限をリクエスト
  Future<bool> requestLocationPermission() async {
    final permission = await Permission.location.request();
    return permission.isGranted;
  }

  /// デバイスの位置情報サービスが有効かチェック
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// 現在の位置情報を取得
  Future<LocationData?> getCurrentLocation() async {
    try {
      // 権限チェック
      if (!await checkLocationPermission()) {
        final granted = await requestLocationPermission();
        if (!granted) return null;
      }

      // 位置情報サービスの確認
      if (!await isLocationServiceEnabled()) {
        throw Exception('位置情報サービスが無効です');
      }

      // 位置情報を取得（Android最適化：最低精度・超短タイムアウト）
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.lowest, // 最低精度で最軽量
        timeLimit: const Duration(seconds: 5), // 5秒でタイムアウト
      );

      // 住所取得（Android最適化：完全無効化で最軽量）
      String? address = null; // 住所取得を無効化してパフォーマンス重視

      return LocationData(
        latitude: position.latitude,
        longitude: position.longitude,
        address: address,
        timestamp: DateTime.now(),
        accuracy: position.accuracy,
      );
    } catch (e) {
      debugPrint('位置情報取得エラー: $e');
      return null;
    }
  }

  /// 位置情報の監視を開始（最大パフォーマンス最適化）
  Stream<LocationData> watchLocation() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.low, // さらに精度を下げて負荷軽減
        distanceFilter: 100, // 距離フィルターを大きくして更新頻度を大幅減
        timeLimit: Duration(seconds: 30), // タイムアウト設定
      ),
    )
    .where((position) => 
        position.accuracy < 200 && // 精度が悪いデータを除外
        position.latitude != 0 && 
        position.longitude != 0
    )
    .map((position) {
      return LocationData(
        latitude: position.latitude,
        longitude: position.longitude,
        address: null, // 住所は別途取得
        timestamp: DateTime.now(),
        accuracy: position.accuracy,
      );
    });
  }

  /// 住所を非同期で取得（最適化版：タイムアウト付き）
  Future<String?> getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      // 3秒でタイムアウトして軽量化
      final placemarks = await placemarkFromCoordinates(latitude, longitude)
          .timeout(const Duration(seconds: 3));
      
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        // より詳細な住所情報を取得
        final parts = <String>[];
        if (placemark.administrativeArea != null) parts.add(placemark.administrativeArea!);
        if (placemark.locality != null) parts.add(placemark.locality!);
        if (placemark.subLocality != null) parts.add(placemark.subLocality!);
        if (placemark.thoroughfare != null) parts.add(placemark.thoroughfare!);
        
        return parts.join('');
      }
    } catch (e) {
      debugPrint('住所取得エラーまたはタイムアウト: $e');
    }
    return null;
  }
}

// ===== Application Layer =====

/// 位置情報リポジトリのプロバイダー
final locationRepositoryProvider = Provider<LocationRepository>(
  (ref) => LocationRepository(),
);

/// 位置情報設定の状態管理
class LocationSettingsNotifier extends StateNotifier<AppLocationSettings> {
  LocationSettingsNotifier()
      : super(const AppLocationSettings(
          isEnabled: false,
          backgroundUpdates: false, // バックグラウンド更新完全無効
          accuracy: LocationAccuracy.lowest, // 最低精度で最軽量
          updateInterval: 300, // 5分間隔で最小負荷
          enableAddressLookup: false, // 住所取得無効でさらに軽量化
        ));

  void updateEnabled(bool enabled) {
    state = state.copyWith(isEnabled: enabled);
  }

  void updateBackgroundUpdates(bool enabled) {
    state = state.copyWith(backgroundUpdates: enabled);
  }

  void updateAccuracy(LocationAccuracy accuracy) {
    state = state.copyWith(accuracy: accuracy);
  }

  void updateInterval(int interval) {
    state = state.copyWith(updateInterval: interval);
  }

  void updateAddressLookup(bool enabled) {
    state = state.copyWith(enableAddressLookup: enabled);
  }
}

/// 位置情報設定のプロバイダー
final locationSettingsProvider =
    StateNotifierProvider<LocationSettingsNotifier, AppLocationSettings>(
  (ref) => LocationSettingsNotifier(),
);

/// 現在の位置情報のプロバイダー（Android最軽量版：完全無効化）
final currentLocationProvider = FutureProvider<LocationData?>((ref) async {
  // Android パフォーマンス問題解決のため位置情報取得を完全無効化
  return null;
});

/// 位置情報監視のプロバイダー（Android最適化：完全無効化）
final locationStreamProvider = StreamProvider<LocationData>((ref) {
  // Android パフォーマンス改善のため完全無効化
  return const Stream.empty();
});

/// 位置情報の住所取得用プロバイダー（必要時のみ使用）
final addressProvider = FutureProvider.family<String?, LocationData>((ref, location) async {
  final repository = ref.watch(locationRepositoryProvider);
  return await repository.getAddressFromCoordinates(location.latitude, location.longitude);
});