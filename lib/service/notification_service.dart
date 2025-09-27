import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

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
    if (_isInitialized) return;

    // Android設定
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS設定
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // 初期化設定
    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    // 通知プラグインの初期化
    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _isInitialized = true;
    debugPrint('通知サービスが初期化されました');
  }

  /// 通知権限のリクエスト
  Future<bool> requestPermission() async {
    try {
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
    final permission = await Permission.notification.status;
    return permission.isGranted;
  }

  /// お知らせ通知を送信
  Future<void> showInformationNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_isInitialized) await initialize();
    
    if (!await hasPermission()) {
      debugPrint('通知権限がありません');
      return;
    }

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'information_channel',
      'お知らせ通知',
      channelDescription: '新しいインフォメーションが配信された時の通知',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF2196F3),
      showWhen: true,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
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
  }

  /// ポイント獲得通知を送信
  Future<void> showPointNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_isInitialized) await initialize();
    
    if (!await hasPermission()) {
      debugPrint('通知権限がありません');
      return;
    }

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'point_channel',
      'ポイント獲得通知',
      channelDescription: 'ポイントを獲得した時の通知',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF4CAF50),
      showWhen: true,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
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
  }

  /// 通知がタップされた時の処理
  void _onNotificationTapped(NotificationResponse notificationResponse) {
    final String? payload = notificationResponse.payload;
    debugPrint('通知がタップされました: $payload');
    
    // TODO: 必要に応じて画面遷移などの処理を実装
    if (payload != null) {
      // payloadに基づいて適切な画面に遷移
    }
  }

  /// 通知チャンネルの作成（Android）
  Future<void> createNotificationChannels() async {
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
  }

  /// すべての通知をキャンセル
  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
    debugPrint('すべての通知をキャンセルしました');
  }

  /// 特定の通知をキャンセル
  Future<void> cancelNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
    debugPrint('通知ID $id をキャンセルしました');
  }
}