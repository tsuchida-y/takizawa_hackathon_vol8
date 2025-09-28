import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:takizawa_hackathon_vol8/screens/settings_screen/location.dart';
import 'package:takizawa_hackathon_vol8/service/location_service.dart';

void main() {
  group('LocationScreen Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    testWidgets('位置情報画面が正しく表示される', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const LocationScreen(),
          ),
        ),
      );

      // AppBarのタイトルを確認
      expect(find.text('位置情報設定'), findsOneWidget);
      
      // 基本的なUIコンポーネントの存在確認
      expect(find.text('現在の位置情報'), findsOneWidget);
      expect(find.text('位置情報設定'), findsWidgets);
      expect(find.text('現在の位置情報を取得'), findsOneWidget);
      expect(find.text('権限設定を開く'), findsOneWidget);
    });

    testWidgets('位置情報サービスのスイッチが動作する', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const LocationScreen(),
          ),
        ),
      );

      // 位置情報サービスのスイッチを探す
      final switchFinder = find.byType(Switch).first;
      expect(switchFinder, findsOneWidget);

      // 初期状態では無効
      Switch switchWidget = tester.widget(switchFinder);
      expect(switchWidget.value, false);

      // スイッチをタップ
      await tester.tap(switchFinder);
      await tester.pump();
    });

    testWidgets('精度設定のラジオボタンが表示される', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const LocationScreen(),
          ),
        ),
      );

      // ラジオボタンの存在確認
      expect(find.byType(RadioListTile), findsWidgets);
      
      // 精度オプションのテキスト確認
      expect(find.text('低精度（省電力）'), findsOneWidget);
      expect(find.text('高精度'), findsOneWidget);
      expect(find.text('最高精度'), findsOneWidget);
    });

    testWidgets('更新間隔のスライダーが表示される', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const LocationScreen(),
          ),
        ),
      );

      // スライダーの存在確認
      expect(find.byType(Slider), findsOneWidget);
      
      // 更新間隔のテキスト確認
      expect(find.textContaining('更新間隔:'), findsOneWidget);
    });

    testWidgets('アクションボタンが正しく表示される', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const LocationScreen(),
          ),
        ),
      );

      // ボタンの存在確認
      expect(find.widgetWithText(ElevatedButton, '現在の位置情報を取得'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, '権限設定を開く'), findsOneWidget);
    });
  });

  group('AppLocationSettings Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('AppLocationSettingsの初期状態が正しい', () {
      final settings = container.read(locationSettingsProvider);
      
      expect(settings.isEnabled, false);
      expect(settings.backgroundUpdates, false);
      expect(settings.updateInterval, 60);
      expect(settings.enableAddressLookup, false);
    });

    test('AppLocationSettings の更新が正しく動作する', () {
      final notifier = container.read(locationSettingsProvider.notifier);
      
      // 有効化
      notifier.updateEnabled(true);
      var settings = container.read(locationSettingsProvider);
      expect(settings.isEnabled, true);
      
      // バックグラウンド更新有効化
      notifier.updateBackgroundUpdates(true);
      settings = container.read(locationSettingsProvider);
      expect(settings.backgroundUpdates, true);
      
      // 更新間隔変更
      notifier.updateInterval(60);
      settings = container.read(locationSettingsProvider);
      expect(settings.updateInterval, 60);
    });
  });

  group('LocationData Tests', () {
    test('LocationData モデルが正しく作成される', () {
      final locationData = LocationData(
        latitude: 35.6762,
        longitude: 139.6503,
        address: '東京都',
        timestamp: DateTime.now(),
        accuracy: 10.0,
      );

      expect(locationData.latitude, 35.6762);
      expect(locationData.longitude, 139.6503);
      expect(locationData.address, '東京都');
      expect(locationData.accuracy, 10.0);
    });

    test('LocationData の toString が正しく動作する', () {
      final timestamp = DateTime.now();
      final locationData = LocationData(
        latitude: 35.6762,
        longitude: 139.6503,
        address: '東京都',
        timestamp: timestamp,
        accuracy: 10.0,
      );

      final stringRepresentation = locationData.toString();
      expect(stringRepresentation, contains('35.6762'));
      expect(stringRepresentation, contains('139.6503'));
      expect(stringRepresentation, contains('東京都'));
    });
  });
}