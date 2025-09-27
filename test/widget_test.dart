// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:takizawa_hackathon_vol8/main.dart';

void main() {
  testWidgets('Main app displays settings screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the settings screen is displayed.
    expect(find.text('設定'), findsOneWidget);
    expect(find.text('アカウント'), findsOneWidget);
    expect(find.text('通知'), findsOneWidget);
    expect(find.text('SNS連携'), findsOneWidget);
    expect(find.text('お知らせ'), findsOneWidget);
    expect(find.text('ヘルプ'), findsOneWidget);
  });

  testWidgets('Settings items are tappable', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Find and tap the account setting.
    final accountSetting = find.text('アカウント');
    expect(accountSetting, findsOneWidget);
    
    // Verify tapping doesn't cause errors.
    await tester.tap(accountSetting);
    await tester.pump();
    
    // The app should still be running without errors.
    expect(find.text('設定'), findsOneWidget);
  });
}
