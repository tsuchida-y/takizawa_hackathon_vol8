import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

/// バックグラウンド通知ハンドラー
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  // バックグラウンド処理（別プロセスで実行されるため、アプリケーション状態にアクセスできない）
  debugPrint('バックグラウンドでの通知タップ: ${notificationResponse.payload}');
}

/// ローカル通知サービス
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// 通知サービスの初期化
  Future<void> initialize() async {
    try {
      if (_isInitialized) return;

      // Android設定
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS設定
      final DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
        // iOSのバックグラウンド通知処理設定
        notificationCategories: <DarwinNotificationCategory>[
          DarwinNotificationCategory(
            'actionable',
            actions: <DarwinNotificationAction>[
              DarwinNotificationAction.plain('id_1', 'アクション1'),
              DarwinNotificationAction.plain('id_2', 'アクション2'),
            ],
          )
        ],
      );

      // 初期化設定
      final InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      // 通知プラグインの初期化
      await _flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        // フォアグラウンドでの通知タップハンドラー
        onDidReceiveNotificationResponse: _onNotificationTapped,
        // バックグラウンドでの通知タップハンドラー
        onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
      );

      // Androidの場合はチャンネル作成
      if (defaultTargetPlatform == TargetPlatform.android) {
        await createNotificationChannels();
      }

      _isInitialized = true;
      debugPrint('通知サービスが初期化されました');
    } catch (e) {
      debugPrint('通知サービスの初期化エラー: $e');
      _isInitialized = false;
    }
  }

  /// 通知権限のリクエスト
  Future<bool> requestPermission() async {
    try {
      // iOS固有の権限リクエスト
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final bool? result = await _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            );
        return result ?? false;
      }

      // Android 13+ (API 33+) では通知権限のリクエストが必要
      final permission = await Permission.notification.request();
      
      if (permission.isGranted) {
        debugPrint('通知権限が許可されました');
        return true;
      } else if (permission.isDenied) {
        debugPrint('通知権限が拒否されました');
        return false;
      } else if (permission.isPermanentlyDenied) {
        debugPrint('通知権限が永続的に拒否されました');
        // ユーザーを設定画面に誘導
        await openAppSettings();
        return false;
      }
    } catch (e) {
      debugPrint('通知権限リクエストエラー: $e');
    }
    return false;
  }

  /// 通知権限の確認
  Future<bool> hasPermission() async {
    try {
      final permission = await Permission.notification.status;
      return permission.isGranted;
    } catch (e) {
      debugPrint('通知権限確認エラー: $e');
      return false;
    }
  }

  /// お知らせ通知を送信
  Future<void> showInformationNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      if (!_isInitialized) await initialize();
      
      if (!await hasPermission()) {
        debugPrint('通知権限がありません');
        return;
      }

      final AndroidNotificationDetails androidPlatformChannelSpecifics =
          const AndroidNotificationDetails(
        'information_channel',
        'お知らせ通知',
        channelDescription: '新しいインフォメーションが配信された時の通知',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        color: Color(0xFF2196F3),
        showWhen: true,
      );

      final DarwinNotificationDetails iOSPlatformChannelSpecifics =
          const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      await _flutterLocalNotificationsPlugin.show(
        1, // notification ID
        title,
        body,
        platformChannelSpecifics,
        payload: payload,
      );

      debugPrint('お知らせ通知を送信しました: $title');
    } catch (e) {
      debugPrint('お知らせ通知送信エラー: $e');
    }
  }

  /// ポイント獲得通知を送信
  Future<void> showPointNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      if (!_isInitialized) await initialize();
      
      if (!await hasPermission()) {
        debugPrint('通知権限がありません');
        return;
      }

      final AndroidNotificationDetails androidPlatformChannelSpecifics =
          const AndroidNotificationDetails(
        'point_channel',
        'ポイント獲得通知',
        channelDescription: 'ポイントを獲得した時の通知',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        color: Color(0xFF4CAF50),
        showWhen: true,
      );

      final DarwinNotificationDetails iOSPlatformChannelSpecifics =
          const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      await _flutterLocalNotificationsPlugin.show(
        2, // notification ID
        title,
        body,
        platformChannelSpecifics,
        payload: payload,
      );

      debugPrint('ポイント獲得通知を送信しました: $title');
    } catch (e) {
      debugPrint('ポイント獲得通知送信エラー: $e');
    }
  }

  /// 通知がタップされた時の処理
  void _onNotificationTapped(NotificationResponse notificationResponse) {
    try {
      final String? payload = notificationResponse.payload;
      debugPrint('通知がタップされました: $payload');
      
      // TODO: 必要に応じて画面遷移などの処理を実装
      if (payload != null) {
        // payloadに基づいて適切な画面に遷移
      }
    } catch (e) {
      debugPrint('通知タップ処理エラー: $e');
    }
  }

  /// 通知チャンネルの作成（Android）
  Future<void> createNotificationChannels() async {
    try {
      if (defaultTargetPlatform != TargetPlatform.android) {
        return;
      }

      if (!_isInitialized) await initialize();

      // お知らせ通知チャンネル
      const AndroidNotificationChannel informationChannel =
          AndroidNotificationChannel(
        'information_channel',
        'お知らせ通知',
        description: '新しいインフォメーションが配信された時の通知',
        importance: Importance.high,
      );

      // ポイント獲得通知チャンネル
      const AndroidNotificationChannel pointChannel =
          AndroidNotificationChannel(
        'point_channel',
        'ポイント獲得通知',
        description: 'ポイントを獲得した時の通知',
        importance: Importance.high,
      );

      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(informationChannel);

      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(pointChannel);

      debugPrint('通知チャンネルを作成しました');
    } catch (e) {
      debugPrint('通知チャンネル作成エラー: $e');
    }
  }

  /// すべての通知をキャンセル
  Future<void> cancelAllNotifications() async {
    try {
      await _flutterLocalNotificationsPlugin.cancelAll();
      debugPrint('すべての通知をキャンセルしました');
    } catch (e) {
      debugPrint('通知キャンセルエラー: $e');
    }
  }

  /// 特定の通知をキャンセル
  Future<void> cancelNotification(int id) async {
    try {
      await _flutterLocalNotificationsPlugin.cancel(id);
      debugPrint('通知ID $id をキャンセルしました');
    } catch (e) {
      debugPrint('通知キャンセルエラー: $e');
    }
  }
}