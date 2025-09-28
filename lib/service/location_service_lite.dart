import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/foundation.dart';

// ===== Domain Layer =====

/// 位置情報データモデル（軽量版）
class LocationDataLite {
  final double latitude;
  final double longitude;
  final double accuracy;
  final DateTime timestamp;
  final String? address;  // ジオコーディング結果

  const LocationDataLite({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.timestamp,
    this.address,
  });

  /// 住所情報付きのコピーを作成
  LocationDataLite copyWithAddress(String address) {
    return LocationDataLite(
      latitude: latitude,
      longitude: longitude,
      accuracy: accuracy,
      timestamp: timestamp,
      address: address,
    );
  }

  @override
  String toString() {
    return 'LocationDataLite(lat: ${latitude.toStringAsFixed(6)}, '
           'lng: ${longitude.toStringAsFixed(6)}, '
           'accuracy: ${accuracy.toStringAsFixed(1)}m'
           '${address != null ? ', address: $address' : ''})';
  }
}

/// 位置情報設定（最適化版）
class AppLocationSettingsLite {
  final LocationAccuracy accuracy;
  final int distanceFilter;
  final Duration timeLimit;
  final bool enableBackgroundLocation;

  const AppLocationSettingsLite({
    this.accuracy = LocationAccuracy.low,  // 最初は低精度で軽量化
    this.distanceFilter = 50,  // 50m以上移動で更新
    this.timeLimit = const Duration(seconds: 15),  // タイムアウト15秒に延長
    this.enableBackgroundLocation = false,  // バックグラウンド無効
  });

  /// パフォーマンス重視の設定
  static const AppLocationSettingsLite performance = AppLocationSettingsLite(
    accuracy: LocationAccuracy.lowest,
    distanceFilter: 100,
    timeLimit: Duration(seconds: 15),  // 15秒に延長
    enableBackgroundLocation: false,
  );

  /// バランス型の設定
  static const AppLocationSettingsLite balanced = AppLocationSettingsLite(
    accuracy: LocationAccuracy.low,
    distanceFilter: 50,
    timeLimit: Duration(seconds: 20),  // 20秒に延長
    enableBackgroundLocation: false,
  );
}

// ===== Data Layer =====

/// 位置情報リポジトリ（軽量版）
class LocationRepositoryLite {
  static LocationRepositoryLite? _instance;
  static LocationRepositoryLite get instance => _instance ??= LocationRepositoryLite._();
  LocationRepositoryLite._();

  /// 現在位置を一度だけ取得（軽量版）
  Future<LocationDataLite?> getCurrentLocation({
    AppLocationSettingsLite? settings,
  }) async {
    try {
      settings ??= const AppLocationSettingsLite();
      debugPrint('LocationServiceLite: 位置取得開始...');
      
      // パーミッションチェック（詳細ログ付き）
      debugPrint('LocationServiceLite: 権限チェック中...');
      final permission = await Geolocator.checkPermission();
      debugPrint('LocationServiceLite: 現在の権限状態: $permission');
      
      if (permission == LocationPermission.denied) {
        debugPrint('LocationServiceLite: 権限要求中...');
        final requestResult = await Geolocator.requestPermission();
        debugPrint('LocationServiceLite: 権限要求結果: $requestResult');
        
        if (requestResult == LocationPermission.denied ||
            requestResult == LocationPermission.deniedForever) {
          debugPrint('LocationServiceLite: 権限が拒否されました');
          return null;
        }
      }

      // 位置情報サービス確認（詳細ログ付き）
      debugPrint('LocationServiceLite: 位置情報サービス確認中...');
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      debugPrint('LocationServiceLite: 位置情報サービス状態: $serviceEnabled');
      
      if (!serviceEnabled) {
        debugPrint('LocationServiceLite: 位置情報サービスが無効です');
        return null;
      }

      // 最後の既知位置を試す（高速化）
      debugPrint('LocationServiceLite: 最後の既知位置を確認中...');
      try {
        final lastPosition = await Geolocator.getLastKnownPosition();
        if (lastPosition != null) {
          debugPrint('LocationServiceLite: 最後の既知位置を取得: ${lastPosition.latitude}, ${lastPosition.longitude}');
          return LocationDataLite(
            latitude: lastPosition.latitude,
            longitude: lastPosition.longitude,
            accuracy: lastPosition.accuracy,
            timestamp: lastPosition.timestamp,
          );
        }
      } catch (e) {
        debugPrint('LocationServiceLite: 最後の既知位置取得エラー: $e');
      }

      // 現在位置を取得（詳細ログ付き）
      debugPrint('LocationServiceLite: 現在位置取得中（精度: ${settings.accuracy}, タイムアウト: ${settings.timeLimit}）...');
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: settings.accuracy,
        timeLimit: settings.timeLimit,
      );

      debugPrint('LocationServiceLite: 位置取得成功: ${position.latitude}, ${position.longitude}');
      return LocationDataLite(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        timestamp: position.timestamp,
      );

    } catch (e) {
      debugPrint('LocationServiceLite Error: $e');
      return null;
    }
  }

  /// 位置情報の利用可能性をチェック
  Future<bool> isLocationAvailable() async {
    try {
      final permission = await Geolocator.checkPermission();
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      
      return serviceEnabled && 
             permission != LocationPermission.denied &&
             permission != LocationPermission.deniedForever;
    } catch (e) {
      debugPrint('LocationServiceLite availability check error: $e');
      return false;
    }
  }

  /// 座標から住所を取得（ジオコーディング）
  Future<String?> getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      debugPrint('LocationServiceLite: ジオコーディング開始 ($latitude, $longitude)');
      
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        final address = _formatAddress(placemark);
        debugPrint('LocationServiceLite: ジオコーディング成功: $address');
        return address;
      }
      
      debugPrint('LocationServiceLite: ジオコーディング結果なし');
      return null;
    } catch (e) {
      debugPrint('LocationServiceLite: ジオコーディングエラー: $e');
      return null;
    }
  }

  /// 住所を日本語形式でフォーマット
  String _formatAddress(Placemark placemark) {
    final parts = <String>[];
    
    // 日本の住所形式で組み立て
    if (placemark.country != null) parts.add(placemark.country!);
    if (placemark.administrativeArea != null) parts.add(placemark.administrativeArea!);
    if (placemark.locality != null) parts.add(placemark.locality!);
    if (placemark.subLocality != null) parts.add(placemark.subLocality!);
    if (placemark.thoroughfare != null) parts.add(placemark.thoroughfare!);
    if (placemark.subThoroughfare != null) parts.add(placemark.subThoroughfare!);
    
    return parts.join(' ');
  }

  /// 位置情報と住所を同時に取得
  Future<LocationDataLite?> getCurrentLocationWithAddress({
    AppLocationSettingsLite? settings,
  }) async {
    final location = await getCurrentLocation(settings: settings);
    if (location == null) return null;

    final address = await getAddressFromCoordinates(location.latitude, location.longitude);
    
    return location.copyWithAddress(address ?? '住所取得失敗');
  }
}

// ===== Application Layer (Riverpod Providers) =====

/// 位置情報リポジトリのプロバイダー
final locationRepositoryLiteProvider = Provider<LocationRepositoryLite>(
  (ref) => LocationRepositoryLite.instance,
);

/// 現在位置取得の非同期プロバイダー（軽量版）
final currentLocationLiteProvider = FutureProvider.autoDispose<LocationDataLite?>(
  (ref) async {
    final repo = ref.watch(locationRepositoryLiteProvider);
    // パフォーマンス重視設定を使用
    return await repo.getCurrentLocation(
      settings: AppLocationSettingsLite.performance,
    );
  },
);

/// 位置情報利用可能性のプロバイダー
final locationAvailabilityProvider = FutureProvider.autoDispose<bool>(
  (ref) async {
    final repo = ref.watch(locationRepositoryLiteProvider);
    return await repo.isLocationAvailable();
  },
);

/// 手動で位置取得をトリガーするプロバイダー
final manualLocationProvider = StateNotifierProvider.autoDispose<ManualLocationNotifier, AsyncValue<LocationDataLite?>>(
  (ref) => ManualLocationNotifier(ref.watch(locationRepositoryLiteProvider)),
);

class ManualLocationNotifier extends StateNotifier<AsyncValue<LocationDataLite?>> {
  final LocationRepositoryLite _repository;

  ManualLocationNotifier(this._repository) : super(const AsyncValue.data(null));

  /// 手動で位置情報を更新（座標のみ）
  Future<void> refreshLocation({AppLocationSettingsLite? settings}) async {
    state = const AsyncValue.loading();
    try {
      final location = await _repository.getCurrentLocation(settings: settings);
      state = AsyncValue.data(location);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// 手動で位置情報と住所を同時取得
  Future<void> refreshLocationWithAddress({AppLocationSettingsLite? settings}) async {
    state = const AsyncValue.loading();
    try {
      final location = await _repository.getCurrentLocationWithAddress(settings: settings);
      state = AsyncValue.data(location);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}