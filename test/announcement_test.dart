import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takizawa_hackathon_vol8/screens/settings_screen/announcement.dart';

void main() {
  group('お知らせ機能のモデルテスト', () {
    test('AnnouncementType enum のテスト', () {
      expect(AnnouncementType.update.displayName, 'アップデート');
      expect(AnnouncementType.maintenance.displayName, 'メンテナンス');
      expect(AnnouncementType.campaign.displayName, 'キャンペーン');
      expect(AnnouncementType.feature.displayName, '新機能');
      expect(AnnouncementType.important.displayName, '重要');

      // 色の確認
      expect(AnnouncementType.update.color, Colors.blue);
      expect(AnnouncementType.maintenance.color, Colors.orange);
      expect(AnnouncementType.campaign.color, Colors.purple);
      expect(AnnouncementType.feature.color, Colors.green);
      expect(AnnouncementType.important.color, Colors.red);

      // アイコンの確認
      expect(AnnouncementType.update.icon, Icons.system_update);
      expect(AnnouncementType.maintenance.icon, Icons.build);
      expect(AnnouncementType.campaign.icon, Icons.local_offer);
      expect(AnnouncementType.feature.icon, Icons.new_releases);
      expect(AnnouncementType.important.icon, Icons.priority_high);
    });

    test('AnnouncementItem モデルのテスト', () {
      final item = AnnouncementItem(
        id: 'test_01',
        title: 'テストお知らせ',
        content: 'テスト内容',
        type: AnnouncementType.update,
        publishedAt: DateTime.now(),
        isRead: false,
        isPinned: true,
      );

      expect(item.id, 'test_01');
      expect(item.title, 'テストお知らせ');
      expect(item.content, 'テスト内容');
      expect(item.type, AnnouncementType.update);
      expect(item.isRead, false);
      expect(item.isPinned, true);
    });

    test('AnnouncementItem copyWith のテスト', () {
      final original = AnnouncementItem(
        id: 'test_01',
        title: 'テストお知らせ',
        content: 'テスト内容',
        type: AnnouncementType.update,
        publishedAt: DateTime.now(),
        isRead: false,
        isPinned: false,
      );

      final updated = original.copyWith(
        isRead: true,
        isPinned: true,
      );

      expect(updated.id, original.id);
      expect(updated.title, original.title);
      expect(updated.isRead, true);
      expect(updated.isPinned, true);
    });

    test('AnnouncementState のテスト', () {
      final announcements = [
        AnnouncementItem(
          id: '1',
          title: 'テスト1',
          content: '内容1',
          type: AnnouncementType.update,
          publishedAt: DateTime.now(),
          isRead: false,
          isPinned: true,
        ),
        AnnouncementItem(
          id: '2',
          title: 'テスト2',
          content: '内容2',
          type: AnnouncementType.feature,
          publishedAt: DateTime.now(),
          isRead: true,
          isPinned: false,
        ),
      ];

      final state = AnnouncementState(announcements: announcements);

      expect(state.unreadCount, 1);
      expect(state.pinnedAnnouncements.length, 1);
      expect(state.regularAnnouncements.length, 1);
      expect(state.isLoading, false);
    });
  });

  group('お知らせリポジトリのテスト', () {
    late AnnouncementRepository repository;

    setUp(() {
      repository = AnnouncementRepository();
    });

    test('お知らせ一覧の取得テスト', () async {
      final announcements = await repository.getAnnouncements();

      expect(announcements, isNotEmpty);
      expect(announcements.length, greaterThan(3));
      expect(announcements.first, isA<AnnouncementItem>());
    });

    test('お知らせを既読にするテスト', () async {
      await expectLater(
        repository.markAsRead('test_id'),
        completes,
      );
    });

    test('すべてのお知らせを既読にするテスト', () async {
      await expectLater(
        repository.markAllAsRead(),
        completes,
      );
    });
  });

  group('お知らせ状態管理のテスト', () {
    late ProviderContainer container;
    late AnnouncementNotifier notifier;

    setUp(() {
      container = ProviderContainer();
      notifier = container.read(announcementProvider.notifier);
    });

    tearDown(() {
      container.dispose();
    });

    test('初期状態のテスト', () {
      final state = container.read(announcementProvider);

      expect(state.announcements, isEmpty);
      expect(state.isLoading, false);
    });

    test('お知らせ読み込みのテスト', () async {
      await notifier.loadAnnouncements();
      final state = container.read(announcementProvider);

      expect(state.announcements, isNotEmpty);
      expect(state.isLoading, false);
    });

    test('お知らせを既読にするテスト', () async {
      // まずお知らせを読み込み
      await notifier.loadAnnouncements();
      
      final stateBefore = container.read(announcementProvider);
      final firstUnread = stateBefore.announcements.firstWhere((item) => !item.isRead);
      
      // 既読にする
      await notifier.markAsRead(firstUnread.id);
      
      final stateAfter = container.read(announcementProvider);
      final updatedItem = stateAfter.announcements.firstWhere((item) => item.id == firstUnread.id);
      
      expect(updatedItem.isRead, true);
    });

    test('すべてのお知らせを既読にするテスト', () async {
      // まずお知らせを読み込み
      await notifier.loadAnnouncements();
      
      // すべて既読にする
      await notifier.markAllAsRead();
      
      final state = container.read(announcementProvider);
      final allRead = state.announcements.every((item) => item.isRead);
      
      expect(allRead, true);
      expect(state.unreadCount, 0);
    });
  });

  group('お知らせ画面のウィジェットテスト', () {
    testWidgets('お知らせ画面の基本表示テスト', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const AnnouncementScreen(),
          ),
        ),
      );

      // 初期状態（ローディング）
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // データ読み込み完了まで待機
      await tester.pumpAndSettle();

      // AppBarの確認
      expect(find.text('お知らせ'), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);

      // リフレッシュボタンの確認
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('お知らせ項目の表示テスト', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const AnnouncementScreen(),
          ),
        ),
      );

      // データ読み込み完了まで待機
      await tester.pumpAndSettle();

      // お知らせ項目が表示されているか確認
      expect(find.textContaining('アプリバージョン'), findsOneWidget);
      expect(find.textContaining('利用規約'), findsOneWidget);
      expect(find.textContaining('新機能'), findsOneWidget);

      // タイプラベルが表示されているか確認
      expect(find.text('アップデート'), findsAtLeastNWidgets(1));
      expect(find.text('重要'), findsAtLeastNWidgets(1));
      expect(find.text('新機能'), findsAtLeastNWidgets(1));
    });

    testWidgets('ピン留めセクションの表示テスト', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const AnnouncementScreen(),
          ),
        ),
      );

      // データ読み込み完了まで待機
      await tester.pumpAndSettle();

      // ピン留めセクションが表示されているか確認
      expect(find.text('ピン留め'), findsOneWidget);
      expect(find.byIcon(Icons.push_pin), findsAtLeastNWidgets(1));
    });

    testWidgets('未読バッジの表示テスト', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const AnnouncementScreen(),
          ),
        ),
      );

      // データ読み込み完了まで待機
      await tester.pumpAndSettle();

      // 未読カウントバッジが表示されているか確認
      // (実際のデータに未読があれば表示される)
      expect(find.text('すべて既読'), findsAny);
    });

    testWidgets('お知らせ詳細の表示テスト', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const AnnouncementScreen(),
          ),
        ),
      );

      // データ読み込み完了まで待機
      await tester.pumpAndSettle();

      // 最初のお知らせ項目をタップ
      final firstAnnouncement = find.textContaining('アプリバージョン').first;
      await tester.tap(firstAnnouncement);
      await tester.pumpAndSettle();

      // 詳細ボトムシートが表示されることを確認
      expect(find.byType(AnnouncementDetailSheet), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('すべて既読ボタンのテスト', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const AnnouncementScreen(),
          ),
        ),
      );

      // データ読み込み完了まで待機
      await tester.pumpAndSettle();

      // すべて既読ボタンがあればタップ
      final markAllReadButton = find.text('すべて既読');
      if (tester.any(markAllReadButton)) {
        await tester.tap(markAllReadButton);
        await tester.pumpAndSettle();

        // 未読バッジが消えることを確認
        expect(find.text('すべて既読'), findsNothing);
      }
    });

    testWidgets('プルリフレッシュのテスト', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const AnnouncementScreen(),
          ),
        ),
      );

      // データ読み込み完了まで待機
      await tester.pumpAndSettle();

      // プルリフレッシュを実行
      await tester.fling(find.byType(RefreshIndicator), const Offset(0, 300), 1000);
      await tester.pump();

      // リフレッシュインジケーターが表示されることを確認
      expect(find.byType(RefreshProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle();
    });

    testWidgets('空の状態の表示テスト', (WidgetTester tester) async {
      // 空のデータを返すモックプロバイダーを作成
      final container = ProviderContainer(
        overrides: [
          announcementProvider.overrideWith((ref) {
            return AnnouncementNotifier(AnnouncementRepository())
              ..state = const AnnouncementState(announcements: []);
          }),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: const AnnouncementScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 空の状態が表示されることを確認
      expect(find.text('お知らせはありません'), findsOneWidget);
      expect(find.text('新しいお知らせがあるとここに表示されます'), findsOneWidget);
      expect(find.byIcon(Icons.notifications_none), findsOneWidget);

      container.dispose();
    });
  });
}