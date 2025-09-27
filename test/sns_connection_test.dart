import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takizawa_hackathon_vol8/screens/settings_screen/sns_connection.dart';

void main() {
  group('SNS連携モデルのテスト', () {
    test('SNSType enum のテスト', () {
      expect(SNSType.google.displayName, 'Google');
      expect(SNSType.x.displayName, 'X (Twitter)');
      expect(SNSType.instagram.displayName, 'Instagram');
      expect(SNSType.facebook.displayName, 'Facebook');
      expect(SNSType.line.displayName, 'LINE');
      expect(SNSType.apple.displayName, 'Apple Account');
    });

    test('SNSConnectionStatus モデルのテスト', () {
      final status = SNSConnectionStatus(
        type: SNSType.google,
        isConnected: true,
        accountName: 'test@example.com',
        accountId: 'google_123',
        connectedAt: DateTime.now(),
      );

      expect(status.type, SNSType.google);
      expect(status.isConnected, true);
      expect(status.accountName, 'test@example.com');
      expect(status.accountId, 'google_123');
      expect(status.connectedAt, isNotNull);
    });

    test('SNSConnectionStatus copyWith のテスト', () {
      const original = SNSConnectionStatus(
        type: SNSType.google,
        isConnected: false,
      );

      final updated = original.copyWith(
        isConnected: true,
        accountName: 'test@example.com',
      );

      expect(updated.type, SNSType.google);
      expect(updated.isConnected, true);
      expect(updated.accountName, 'test@example.com');
    });

    test('SNSConnectionState のテスト', () {
      final connections = {
        SNSType.google: const SNSConnectionStatus(
          type: SNSType.google,
          isConnected: true,
        ),
        SNSType.x: const SNSConnectionStatus(
          type: SNSType.x,
          isConnected: false,
        ),
      };

      final state = SNSConnectionState(connections: connections);

      expect(state.connectedCount, 1);
      expect(state.getConnectionStatus(SNSType.google).isConnected, true);
      expect(state.getConnectionStatus(SNSType.x).isConnected, false);
    });
  });

  group('SNS連携リポジトリのテスト', () {
    late SNSRepository repository;

    setUp(() {
      repository = SNSRepository();
    });

    test('初期状態の取得テスト', () {
      final state = repository.getInitialConnectionState();

      expect(state.connections.length, SNSType.values.length);
      expect(state.connectedCount, 0);
      
      for (final snsType in SNSType.values) {
        expect(state.getConnectionStatus(snsType).isConnected, false);
      }
    });

    test('SNS連携のテスト', () async {
      final result = await repository.connectSNS(SNSType.google);
      expect(result, true);
    });

    test('SNS連携解除のテスト', () async {
      final result = await repository.disconnectSNS(SNSType.google);
      expect(result, true);
    });

    test('アカウント情報取得のテスト', () {
      final googleInfo = repository.getAccountInfo(SNSType.google);
      expect(googleInfo['name'], isNotNull);
      expect(googleInfo['id'], isNotNull);

      final xInfo = repository.getAccountInfo(SNSType.x);
      expect(xInfo['name'], isNotNull);
      expect(xInfo['id'], isNotNull);
    });
  });

  group('SNS連携状態管理のテスト', () {
    late ProviderContainer container;
    late SNSConnectionNotifier notifier;

    setUp(() {
      container = ProviderContainer();
      notifier = container.read(snsConnectionProvider.notifier);
    });

    tearDown(() {
      container.dispose();
    });

    test('初期状態のテスト', () {
      final state = container.read(snsConnectionProvider);

      expect(state.connectedCount, 0);
      for (final snsType in SNSType.values) {
        expect(state.getConnectionStatus(snsType).isConnected, false);
      }
    });

    test('SNS連携のテスト', () async {
      await notifier.connectSNS(SNSType.google);
      final state = container.read(snsConnectionProvider);

      expect(state.getConnectionStatus(SNSType.google).isConnected, true);
      expect(state.getConnectionStatus(SNSType.google).accountName, isNotNull);
      expect(state.connectedCount, 1);
    });

    test('SNS連携解除のテスト', () async {
      // まず連携
      await notifier.connectSNS(SNSType.google);
      expect(container.read(snsConnectionProvider).connectedCount, 1);

      // 連携解除
      await notifier.disconnectSNS(SNSType.google);
      final state = container.read(snsConnectionProvider);

      expect(state.getConnectionStatus(SNSType.google).isConnected, false);
      expect(state.connectedCount, 0);
    });

    test('複数SNS連携のテスト', () async {
      await notifier.connectSNS(SNSType.google);
      await notifier.connectSNS(SNSType.x);
      await notifier.connectSNS(SNSType.instagram);

      final state = container.read(snsConnectionProvider);

      expect(state.connectedCount, 3);
      expect(state.getConnectionStatus(SNSType.google).isConnected, true);
      expect(state.getConnectionStatus(SNSType.x).isConnected, true);
      expect(state.getConnectionStatus(SNSType.instagram).isConnected, true);
    });
  });

  group('SNS連携画面のウィジェットテスト', () {
    testWidgets('SNS連携画面の基本表示テスト', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const SNSConnectionScreen(),
          ),
        ),
      );

      // AppBarの確認
      expect(find.text('SNS連携'), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);

      // 説明セクションの確認
      expect(find.text('SNS連携について'), findsOneWidget);
      expect(find.textContaining('SNSアカウントと連携することで'), findsOneWidget);

      // 連携状況サマリーの確認
      expect(find.text('連携済みアカウント'), findsOneWidget);
      expect(find.text('0 / 6 件'), findsOneWidget);

      // すべてのSNS項目の確認
      for (final snsType in SNSType.values) {
        expect(find.text(snsType.displayName), findsOneWidget);
      }

      // 連携ボタンの確認
      expect(find.text('連携'), findsNWidgets(6));
    });

    testWidgets('Google連携ボタンのテスト', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const SNSConnectionScreen(),
          ),
        ),
      );

      // Googleの連携ボタンを探す
      final googleConnectButton = find.ancestor(
        of: find.text('連携'),
        matching: find.ancestor(
          of: find.text('Google'),
          matching: find.byType(Container),
        ),
      ).first;

      // ボタンをタップ
      await tester.tap(find.descendant(
        of: googleConnectButton,
        matching: find.text('連携'),
      ));
      await tester.pump();

      // ローディングダイアログが表示されることを確認
      expect(find.text('Googleと連携中...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('連携状況の更新テスト', (WidgetTester tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: const SNSConnectionScreen(),
          ),
        ),
      );

      // 初期状態の確認
      expect(find.text('0 / 6 件'), findsOneWidget);
      expect(find.text('未連携'), findsOneWidget);

      // Google連携を実行
      final notifier = container.read(snsConnectionProvider.notifier);
      await notifier.connectSNS(SNSType.google);
      await tester.pumpAndSettle();

      // 連携後の状態確認
      expect(find.text('1 / 6 件'), findsOneWidget);
      expect(find.text('連携中'), findsOneWidget);
    });

    testWidgets('連携解除の確認ダイアログテスト', (WidgetTester tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // まずGoogle連携を実行
      final notifier = container.read(snsConnectionProvider.notifier);
      await notifier.connectSNS(SNSType.google);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: const SNSConnectionScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 解除ボタンをタップ
      await tester.tap(find.text('解除').first);
      await tester.pumpAndSettle();

      // 確認ダイアログが表示されることを確認
      expect(find.text('Googleとの連携解除'), findsOneWidget);
      expect(find.text('キャンセル'), findsOneWidget);
      expect(find.text('解除'), findsNWidgets(2)); // ダイアログ内とボタン
    });

    testWidgets('アイコンの表示テスト', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const SNSConnectionScreen(),
          ),
        ),
      );

      // 各SNSのアイコンが表示されていることを確認
      expect(find.byIcon(Icons.g_mobiledata), findsOneWidget); // Google
      expect(find.byIcon(Icons.close), findsOneWidget); // X
      expect(find.byIcon(Icons.camera_alt), findsOneWidget); // Instagram
      expect(find.byIcon(Icons.facebook), findsOneWidget); // Facebook
      expect(find.byIcon(Icons.chat_bubble), findsOneWidget); // LINE
      expect(find.byIcon(Icons.apple), findsOneWidget); // Apple

      // その他のアイコン
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
      expect(find.byIcon(Icons.link), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_outlined), findsOneWidget);
    });

    testWidgets('注意事項の表示テスト', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const SNSConnectionScreen(),
          ),
        ),
      );

      // 注意事項セクションの確認
      expect(find.text('注意事項'), findsOneWidget);
      expect(find.textContaining('SNS連携時には各サービスの利用規約'), findsOneWidget);
      expect(find.textContaining('連携を解除してもアカウント情報は保持'), findsOneWidget);
      expect(find.textContaining('連携情報は安全に暗号化'), findsOneWidget);
    });
  });
}