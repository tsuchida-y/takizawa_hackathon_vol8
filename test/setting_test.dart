import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:takizawa_hackathon_vol8/setting.dart';

void main() {
  group('SettingItem', () {
    test('should create a SettingItem with required parameters', () {
      const settingItem = SettingItem(
        id: 'test_id',
        title: 'Test Title',
        icon: Icons.settings,
      );

      expect(settingItem.id, 'test_id');
      expect(settingItem.title, 'Test Title');
      expect(settingItem.icon, Icons.settings);
      expect(settingItem.subtitle, null);
      expect(settingItem.onTap, null);
    });

    test('should create a SettingItem with all parameters', () {
      void testCallback() {}
      
      final settingItem = SettingItem(
        id: 'test_id',
        title: 'Test Title',
        icon: Icons.settings,
        subtitle: 'Test Subtitle',
        onTap: testCallback,
      );

      expect(settingItem.id, 'test_id');
      expect(settingItem.title, 'Test Title');
      expect(settingItem.icon, Icons.settings);
      expect(settingItem.subtitle, 'Test Subtitle');
      expect(settingItem.onTap, testCallback);
    });
  });

  group('SettingsRepository', () {
    late SettingsRepository repository;

    setUp(() {
      repository = SettingsRepository();
    });

    test('should return list of setting items', () {
      final items = repository.getSettingItems();

      expect(items, isA<List<SettingItem>>());
      expect(items.length, 5);
    });

    test('should return correct setting items', () {
      final items = repository.getSettingItems();

      expect(items[0].id, 'account');
      expect(items[0].title, 'アカウント');
      expect(items[0].icon, Icons.person_outline);
      expect(items[0].subtitle, 'プロフィール設定');

      expect(items[1].id, 'notifications');
      expect(items[1].title, '通知');
      expect(items[1].icon, Icons.notifications_outlined);

      expect(items[2].id, 'social_connect');
      expect(items[2].title, 'SNS連携');
      expect(items[2].icon, Icons.link_outlined);

      expect(items[3].id, 'announcements');
      expect(items[3].title, 'お知らせ');
      expect(items[3].icon, Icons.campaign_outlined);

      expect(items[4].id, 'help');
      expect(items[4].title, 'ヘルプ');
      expect(items[4].icon, Icons.help_outline);
    });
  });

  group('SettingScreen Widget Tests', () {
    testWidgets('should display app bar with correct title', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SettingScreen(),
          ),
        ),
      );

      expect(find.text('設定'), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('should display all setting items', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SettingScreen(),
          ),
        ),
      );

      // 全ての設定項目が表示されることを確認
      expect(find.text('アカウント'), findsOneWidget);
      expect(find.text('通知'), findsOneWidget);
      expect(find.text('SNS連携'), findsOneWidget);
      expect(find.text('お知らせ'), findsOneWidget);
      expect(find.text('ヘルプ'), findsOneWidget);
    });

    testWidgets('should display setting item cards', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SettingScreen(),
          ),
        ),
      );

      expect(find.byType(SettingItemCard), findsNWidgets(5));
    });

    testWidgets('should have scrollable list', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SettingScreen(),
          ),
        ),
      );

      expect(find.byType(ListView), findsOneWidget);
    });
  });

  group('SettingItemCard Widget Tests', () {
    testWidgets('should display setting item correctly', (tester) async {
      const testItem = SettingItem(
        id: 'test',
        title: 'Test Title',
        icon: Icons.settings,
        subtitle: 'Test Subtitle',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingItemCard(item: testItem),
          ),
        ),
      );

      expect(find.text('Test Title'), findsOneWidget);
      expect(find.text('Test Subtitle'), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('should handle tap correctly', (tester) async {
      bool tapped = false;
      final testItem = SettingItem(
        id: 'test',
        title: 'Test Title',
        icon: Icons.settings,
        onTap: () => tapped = true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingItemCard(item: testItem),
          ),
        ),
      );

      await tester.tap(find.byType(SettingItemCard));
      expect(tapped, true);
    });

    testWidgets('should not display subtitle when null', (tester) async {
      const testItem = SettingItem(
        id: 'test',
        title: 'Test Title',
        icon: Icons.settings,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingItemCard(item: testItem),
          ),
        ),
      );

      expect(find.text('Test Title'), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);
      // subtitleがnullの場合は表示されない
      expect(find.text('Test Subtitle'), findsNothing);
    });
  });

  group('Riverpod Providers Tests', () {
    test('settingsRepositoryProvider should provide SettingsRepository', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final repository = container.read(settingsRepositoryProvider);
      expect(repository, isA<SettingsRepository>());
    });

    test('settingItemsProvider should provide list of SettingItem', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final items = container.read(settingItemsProvider);
      expect(items, isA<List<SettingItem>>());
      expect(items.length, 5);
    });
  });
}