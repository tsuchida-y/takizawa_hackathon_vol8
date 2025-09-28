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
      debugPrint('初期化開始: _isInitialized = $_isInitialized');
      if (_isInitialized) {
        debugPrint('既に初期化済みです');
        return;
      }

      debugPrint('最小限の初期化設定を作成中...');
      // 最小限のAndroid設定
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // 最小限のiOS設定
      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings();

      // 初期化設定
      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      debugPrint('通知プラグインを初期化中...');
      // 通知プラグインの初期化（最小限）
      final bool? result = await _flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
      );
      debugPrint('通知プラグイン初期化結果: $result');

      _isInitialized = true;
      debugPrint('通知サービスが初期化されました');

      // 初期化後に非同期でチャンネル作成
      if (defaultTargetPlatform == TargetPlatform.android) {
        debugPrint('Androidチャンネルを非同期で作成開始...');
        createNotificationChannels().then((_) {
          debugPrint('Androidチャンネル作成完了');
        }).catchError((e) {
          debugPrint('Androidチャンネル作成エラー: $e');
        });
      }
    } catch (e, stackTrace) {
      debugPrint('通知サービスの初期化エラー: $e');
      debugPrint('スタックトレース: $stackTrace');
      _isInitialized = false;
      rethrow;
    }
  }

  /// 通知権限のリクエスト
  Future<bool> requestPermission() async {
    try {
      debugPrint('通知権限のリクエストを開始します');
      
      // iOS固有の権限リクエスト
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        debugPrint('iOS向け通知権限をリクエスト中...');
        final bool? result = await _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            );
        debugPrint('iOS通知権限リクエスト結果: $result');
        return result ?? false;
      }

      // Android 13+ (API 33+) では通知権限のリクエストが必要
      debugPrint('Android向け通知権限をリクエスト中...');
      final permission = await Permission.notification.request();
      debugPrint('通知権限ステータス: $permission');
      
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
      debugPrint('現在の通知権限ステータス: $permission');
      debugPrint('権限が許可されているか: ${permission.isGranted}');
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
      debugPrint('お知らせ通知送信開始: $title');
      
      if (!_isInitialized) {
        debugPrint('通知サービス未初期化、初期化を実行中...');
        await initialize();
      }
      
      if (!await hasPermission()) {
        debugPrint('通知権限がありません');
        return;
      }

      debugPrint('通知の詳細設定を作成中...');
      final AndroidNotificationDetails androidPlatformChannelSpecifics =
          const AndroidNotificationDetails(
        'information_channel',
        'お知らせ通知',
        channelDescription: '新しいインフォメーションが配信された時の通知',
        importance: Importance.max,
        priority: Priority.max,
        icon: '@mipmap/ic_launcher',
        color: Color(0xFF2196F3),
        showWhen: true,
        enableVibration: true,
        playSound: true,
        visibility: NotificationVisibility.public,
        // 画面上部から通知を降ろすためのオプション
        fullScreenIntent: true,
        // 通知をヘッドアップで表示
        category: AndroidNotificationCategory.message,
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

      debugPrint('通知を表示中...');
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
      rethrow; // エラーを再スローして、呼び出し元でもエラーハンドリングできるようにする
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
        importance: Importance.max,
        priority: Priority.max,
        icon: '@mipmap/ic_launcher',
        color: Color(0xFF4CAF50),
        showWhen: true,
        enableVibration: true,
        playSound: true,
        visibility: NotificationVisibility.public,
        // 画面上部から通知を降ろすためのオプション
        fullScreenIntent: true,
        // 通知をヘッドアップで表示
        category: AndroidNotificationCategory.message,
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
      debugPrint('通知チャンネル作成開始');
      if (defaultTargetPlatform != TargetPlatform.android) {
        debugPrint('Android以外のプラットフォームなのでスキップ');
        return;
      }

      if (!_isInitialized) {
        debugPrint('未初期化なので初期化を実行');
        await initialize();
      }

      debugPrint('お知らせ通知チャンネルを作成中...');
      // お知らせ通知チャンネル
      const AndroidNotificationChannel informationChannel =
          AndroidNotificationChannel(
        'information_channel',
        'お知らせ通知',
        description: '新しいインフォメーションが配信された時の通知',
        importance: Importance.max,
        enableVibration: true,
        playSound: true,
        showBadge: true,
      );

      debugPrint('ポイント獲得通知チャンネルを作成中...');
      // ポイント獲得通知チャンネル
      const AndroidNotificationChannel pointChannel =
          AndroidNotificationChannel(
        'point_channel',
        'ポイント獲得通知',
        description: 'ポイントを獲得した時の通知',
        importance: Importance.max,
        enableVibration: true,
        playSound: true,
        showBadge: true,
      );

      debugPrint('Androidプラグインを取得中...');
      final androidPlugin = _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin == null) {
        debugPrint('Androidプラグインが取得できませんでした');
        return;
      }

      debugPrint('お知らせ通知チャンネルを登録中...');
      await androidPlugin.createNotificationChannel(informationChannel);

      debugPrint('ポイント獲得通知チャンネルを登録中...');
      await androidPlugin.createNotificationChannel(pointChannel);

      debugPrint('通知チャンネルを作成しました');
    } catch (e, stackTrace) {
      debugPrint('通知チャンネル作成エラー: $e');
      debugPrint('スタックトレース: $stackTrace');
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