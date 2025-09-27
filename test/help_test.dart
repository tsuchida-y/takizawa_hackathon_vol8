import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:takizawa_hackathon_vol8/help.dart';

void main() {
  group('ヘルプ機能のモデルテスト', () {
    test('FAQItem モデルのテスト', () {
      const faq = FAQItem(
        id: 'test_01',
        question: 'テスト質問',
        answer: 'テスト回答',
        category: 'テスト',
      );

      expect(faq.id, 'test_01');
      expect(faq.question, 'テスト質問');
      expect(faq.answer, 'テスト回答');
      expect(faq.category, 'テスト');
    });

    test('ContactType enum のテスト', () {
      expect(ContactType.bug.displayName, '不具合報告');
      expect(ContactType.feature.displayName, '機能要望');
      expect(ContactType.account.displayName, 'アカウント');
      expect(ContactType.payment.displayName, '決済');
      expect(ContactType.other.displayName, 'その他');
    });

    test('ContactForm モデルのテスト', () {
      const form = ContactForm(
        type: ContactType.bug,
        email: 'test@example.com',
        subject: 'テスト件名',
        message: 'テストメッセージ',
      );

      expect(form.type, ContactType.bug);
      expect(form.email, 'test@example.com');
      expect(form.subject, 'テスト件名');
      expect(form.message, 'テストメッセージ');
    });
  });

  group('ヘルプリポジトリのテスト', () {
    late HelpRepository repository;

    setUp(() {
      repository = HelpRepository();
    });

    test('FAQ項目の取得テスト', () {
      final faqItems = repository.getFAQItems();

      expect(faqItems, isNotEmpty);
      expect(faqItems.length, greaterThan(5));
      expect(faqItems.first, isA<FAQItem>());
    });

    test('アプリ情報の取得テスト', () {
      final appInfo = repository.getAppInfo();

      expect(appInfo, isNotEmpty);
      expect(appInfo.containsKey('バージョン'), true);
      expect(appInfo.containsKey('ビルド番号'), true);
      expect(appInfo.containsKey('開発者'), true);
    });

    test('お問い合わせ送信のテスト', () async {
      const form = ContactForm(
        type: ContactType.bug,
        email: 'test@example.com',
        subject: 'テスト件名',
        message: 'テストメッセージ',
      );

      final result = await repository.sendContact(form);
      expect(result, true);
    });
  });

  group('ヘルプ画面のウィジェットテスト', () {
    testWidgets('ヘルプ画面の基本表示テスト', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const HelpScreen(),
          ),
        ),
      );

      // AppBarの確認
      expect(find.text('ヘルプ'), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);

      // セクションヘッダーの確認
      expect(find.text('よくある質問'), findsOneWidget);
      expect(find.text('お問い合わせ'), findsOneWidget);
      expect(find.text('アプリ情報'), findsOneWidget);

      // アイコンの確認
      expect(find.byIcon(Icons.help_outline), findsOneWidget);
      expect(find.byIcon(Icons.mail_outline), findsAtLeastNWidgets(1));
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });

    testWidgets('FAQ項目の表示テスト', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const HelpScreen(),
          ),
        ),
      );

      // FAQ項目が表示されているか確認
      expect(find.byType(ExpansionTile), findsAtLeastNWidgets(5));
      
      // カテゴリが表示されているか確認
      expect(find.text('アカウント'), findsAtLeastNWidgets(1));
      expect(find.text('通知'), findsAtLeastNWidgets(1));
      expect(find.text('SNS連携'), findsAtLeastNWidgets(1));
    });

    testWidgets('FAQ項目の展開テスト', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const HelpScreen(),
          ),
        ),
      );

      // 最初のFAQ項目をタップして展開
      final firstFAQ = find.byType(ExpansionTile).first;
      await tester.tap(firstFAQ);
      await tester.pumpAndSettle();

      // 展開されたことを確認（回答テキストが表示される）
      expect(find.textContaining('アプリを初回起動時に'), findsOneWidget);
    });

    testWidgets('お問い合わせフォームの表示テスト', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const HelpScreen(),
          ),
        ),
      );

      // お問い合わせカードをタップ
      final contactCard = find.text('お問い合わせフォーム');
      expect(contactCard, findsOneWidget);
      
      await tester.tap(contactCard);
      await tester.pumpAndSettle();

      // ボトムシートが表示されることを確認
      expect(find.text('お問い合わせ'), findsAtLeastNWidgets(1));
      expect(find.text('お問い合わせの種類'), findsOneWidget);
      expect(find.text('メールアドレス'), findsOneWidget);
      expect(find.text('件名'), findsOneWidget);
      expect(find.text('お問い合わせ内容'), findsOneWidget);
    });

    testWidgets('お問い合わせフォームのバリデーションテスト', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const HelpScreen(),
          ),
        ),
      );

      // お問い合わせフォームを開く
      await tester.tap(find.text('お問い合わせフォーム'));
      await tester.pumpAndSettle();

      // 空の状態で送信ボタンをタップ
      await tester.tap(find.text('送信'));
      await tester.pumpAndSettle();

      // バリデーションエラーが表示されることを確認
      expect(find.text('メールアドレスを入力してください'), findsOneWidget);
      expect(find.text('件名を入力してください'), findsOneWidget);
      expect(find.text('お問い合わせ内容を入力してください'), findsOneWidget);
    });

    testWidgets('お問い合わせフォームの入力テスト', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const HelpScreen(),
          ),
        ),
      );

      // お問い合わせフォームを開く
      await tester.tap(find.text('お問い合わせフォーム'));
      await tester.pumpAndSettle();

      // フォームに入力
      await tester.enterText(
        find.widgetWithText(TextFormField, 'example@email.com'),
        'test@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, '件名を入力してください'),
        'テスト件名',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'お問い合わせ内容を詳しく入力してください'),
        'これはテスト用のお問い合わせ内容です。',
      );

      await tester.pumpAndSettle();

      // 送信ボタンをタップ
      await tester.tap(find.text('送信'));
      await tester.pumpAndSettle();

      // 送信処理が開始されることを確認（ローディング表示）
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('アプリ情報の表示テスト', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const HelpScreen(),
          ),
        ),
      );

      // アプリ情報の項目が表示されているか確認
      expect(find.text('バージョン'), findsOneWidget);
      expect(find.text('ビルド番号'), findsOneWidget);
      expect(find.text('開発者'), findsOneWidget);
      expect(find.text('1.0.0'), findsOneWidget);
    });
  });
}