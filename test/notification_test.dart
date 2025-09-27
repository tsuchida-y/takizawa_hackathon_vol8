import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takizawa_hackathon_vol8/notification.dart';

void main() {
  group('通知設定モデルのテスト', () {
    test('NotificationSettings モデルのテスト', () {
      const settings = NotificationSettings(
        pushNotificationEnabled: true,
        informationNotificationEnabled: false,
        pointNotificationEnabled: true,
      );

      expect(settings.pushNotificationEnabled, true);
      expect(settings.informationNotificationEnabled, false);
      expect(settings.pointNotificationEnabled, true);
    });

    test('NotificationSettings copyWith のテスト', () {
      const original = NotificationSettings(
        pushNotificationEnabled: true,
        informationNotificationEnabled: true,
        pointNotificationEnabled: true,
      );

      final updated = original.copyWith(
        informationNotificationEnabled: false,
      );

      expect(updated.pushNotificationEnabled, true);
      expect(updated.informationNotificationEnabled, false);
      expect(updated.pointNotificationEnabled, true);
    });
  });

  group('通知設定リポジトリのテスト', () {
    late NotificationRepository repository;

    setUp(() {
      repository = NotificationRepository();
    });

    test('初期設定の取得テスト', () {
      final settings = repository.getNotificationSettings();

      expect(settings.pushNotificationEnabled, true);
      expect(settings.informationNotificationEnabled, true);
      expect(settings.pointNotificationEnabled, true);
    });

    test('設定の保存テスト', () async {
      const settings = NotificationSettings(
        pushNotificationEnabled: false,
        informationNotificationEnabled: true,
        pointNotificationEnabled: false,
      );

      await expectLater(
        repository.saveNotificationSettings(settings),
        completes,
      );
    });
  });

  group('通知設定状態管理のテスト', () {
    late ProviderContainer container;
    late NotificationNotifier notifier;

    setUp(() {
      container = ProviderContainer();
      notifier = container.read(notificationProvider.notifier);
    });

    tearDown(() {
      container.dispose();
    });

    test('初期状態のテスト', () {
      final settings = container.read(notificationProvider);

      expect(settings.pushNotificationEnabled, true);
      expect(settings.informationNotificationEnabled, true);
      expect(settings.pointNotificationEnabled, true);
    });

    test('プッシュ通知の切り替えテスト', () {
      notifier.togglePushNotification(false);
      final settings = container.read(notificationProvider);

      expect(settings.pushNotificationEnabled, false);
    });

    test('インフォメーション通知の切り替えテスト', () {
      notifier.toggleInformationNotification(false);
      final settings = container.read(notificationProvider);

      expect(settings.informationNotificationEnabled, false);
    });

    test('ポイント通知の切り替えテスト', () {
      notifier.togglePointNotification(false);
      final settings = container.read(notificationProvider);

      expect(settings.pointNotificationEnabled, false);
    });
  });

  group('通知設定画面のウィジェットテスト', () {
    testWidgets('通知設定画面の基本表示テスト', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const NotificationScreen(),
          ),
        ),
      );

      // AppBarの確認
      expect(find.text('通知設定'), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);

      // 説明テキストの確認
      expect(find.text('アプリからの通知を受け取るかどうかを設定できます。'), findsOneWidget);

      // 各設定項目の確認
      expect(find.text('プッシュ通知'), findsOneWidget);
      expect(find.text('お知らせ通知'), findsOneWidget);
      expect(find.text('ポイント獲得通知'), findsOneWidget);

      // スイッチの確認
      expect(find.byType(Switch), findsNWidgets(3));
    });

    testWidgets('プッシュ通知スイッチの操作テスト', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const NotificationScreen(),
          ),
        ),
      );

      // プッシュ通知のスイッチを探して操作
      final pushNotificationSwitch = find.byType(Switch).first;
      
      // 初期状態はON
      Switch initialSwitch = tester.widget(pushNotificationSwitch);
      expect(initialSwitch.value, true);

      // スイッチをタップしてOFFにする
      await tester.tap(pushNotificationSwitch);
      await tester.pumpAndSettle();

      // 状態が変わったことを確認
      Switch updatedSwitch = tester.widget(pushNotificationSwitch);
      expect(updatedSwitch.value, false);
    });

    testWidgets('お知らせ通知スイッチの操作テスト', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const NotificationScreen(),
          ),
        ),
      );

      // お知らせ通知のスイッチを探して操作
      final informationSwitch = find.byType(Switch).at(1);
      
      // 初期状態はON
      Switch initialSwitch = tester.widget(informationSwitch);
      expect(initialSwitch.value, true);

      // スイッチをタップしてOFFにする
      await tester.tap(informationSwitch);
      await tester.pumpAndSettle();

      // 状態が変わったことを確認
      Switch updatedSwitch = tester.widget(informationSwitch);
      expect(updatedSwitch.value, false);
    });

    testWidgets('ポイント獲得通知スイッチの操作テスト', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const NotificationScreen(),
          ),
        ),
      );

      // ポイント獲得通知のスイッチを探して操作
      final pointSwitch = find.byType(Switch).at(2);
      
      // 初期状態はON
      Switch initialSwitch = tester.widget(pointSwitch);
      expect(initialSwitch.value, true);

      // スイッチをタップしてOFFにする
      await tester.tap(pointSwitch);
      await tester.pumpAndSettle();

      // 状態が変わったことを確認
      Switch updatedSwitch = tester.widget(pointSwitch);
      expect(updatedSwitch.value, false);
    });

    testWidgets('プッシュ通知OFF時の子項目無効化テスト', (WidgetTester tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: const NotificationScreen(),
          ),
        ),
      );

      // プッシュ通知をOFFにする
      final notifier = container.read(notificationProvider.notifier);
      notifier.togglePushNotification(false);
      await tester.pumpAndSettle();

      // お知らせ通知とポイント通知のスイッチが無効になっていることを確認
      final informationSwitch = find.byType(Switch).at(1);
      final pointSwitch = find.byType(Switch).at(2);

      Switch infoSwitchWidget = tester.widget(informationSwitch);
      Switch pointSwitchWidget = tester.widget(pointSwitch);

      expect(infoSwitchWidget.onChanged, null); // 無効状態
      expect(pointSwitchWidget.onChanged, null); // 無効状態
    });

    testWidgets('注意事項の表示テスト', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const NotificationScreen(),
          ),
        ),
      );

      // 注意事項セクションの確認
      expect(find.text('注意事項'), findsOneWidget);
      expect(find.textContaining('プッシュ通知をオフにすると'), findsOneWidget);
      expect(find.textContaining('端末の設定でも通知を許可'), findsOneWidget);
      expect(find.textContaining('通知設定の変更は即座に反映'), findsOneWidget);
    });

    testWidgets('アイコンの表示テスト', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const NotificationScreen(),
          ),
        ),
      );

      // 各設定項目のアイコンを確認
      expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
      expect(find.byIcon(Icons.campaign_outlined), findsOneWidget);
      expect(find.byIcon(Icons.stars_outlined), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_outlined), findsOneWidget);
    });
  });
}