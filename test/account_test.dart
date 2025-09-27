import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:takizawa_hackathon_vol8/account.dart';

void main() {
  group('UserProfile', () {
    test('should create a UserProfile with required parameters', () {
      final profile = UserProfile(
        nickname: 'TestUser',
        userId: 'test123',
        email: 'test@example.com',
        selfIntroduction: 'Hello World',
        registrationDate: DateTime(2024, 1, 1),
      );

      expect(profile.nickname, 'TestUser');
      expect(profile.userId, 'test123');
      expect(profile.email, 'test@example.com');
      expect(profile.selfIntroduction, 'Hello World');
      expect(profile.registrationDate, DateTime(2024, 1, 1));
      expect(profile.gender, null);
      expect(profile.birthDate, null);
      expect(profile.profileImagePath, null);
    });

    test('should create a UserProfile with all parameters', () {
      final profile = UserProfile(
        nickname: 'TestUser',
        userId: 'test123',
        email: 'test@example.com',
        gender: '男性',
        birthDate: DateTime(1990, 5, 15),
        selfIntroduction: 'Hello World',
        registrationDate: DateTime(2024, 1, 1),
        profileImagePath: '/path/to/image.jpg',
      );

      expect(profile.nickname, 'TestUser');
      expect(profile.userId, 'test123');
      expect(profile.email, 'test@example.com');
      expect(profile.gender, '男性');
      expect(profile.birthDate, DateTime(1990, 5, 15));
      expect(profile.selfIntroduction, 'Hello World');
      expect(profile.registrationDate, DateTime(2024, 1, 1));
      expect(profile.profileImagePath, '/path/to/image.jpg');
    });

    test('should copy with new values', () {
      final profile = UserProfile(
        nickname: 'TestUser',
        userId: 'test123',
        email: 'test@example.com',
        selfIntroduction: 'Hello World',
        registrationDate: DateTime(2024, 1, 1),
      );

      final updatedProfile = profile.copyWith(
        nickname: 'UpdatedUser',
        gender: '女性',
      );

      expect(updatedProfile.nickname, 'UpdatedUser');
      expect(updatedProfile.userId, 'test123'); // unchanged
      expect(updatedProfile.gender, '女性');
    });
  });

  group('UserProfileRepository', () {
    late UserProfileRepository repository;

    setUp(() {
      repository = UserProfileRepository();
    });

    test('should return user profile', () {
      final profile = repository.getUserProfile();

      expect(profile, isA<UserProfile>());
      expect(profile.nickname, '做-ｻｸ-');
      expect(profile.userId, '91nw8l6r');
      expect(profile.email, 'qi652009@gmail.com');
    });

    test('should save user profile', () async {
      final profile = UserProfile(
        nickname: 'TestUser',
        userId: 'test123',
        email: 'test@example.com',
        selfIntroduction: 'Hello World',
        registrationDate: DateTime(2024, 1, 1),
      );

      final result = await repository.saveUserProfile(profile);
      expect(result, true);
    });

    test('should check user ID availability', () async {
      final isAvailable = await repository.checkUserIdAvailability('newuser');
      expect(isAvailable, true);

      final isUnavailable = await repository.checkUserIdAvailability('admin');
      expect(isUnavailable, false);
    });
  });

  group('AccountScreen Widget Tests', () {
    testWidgets('should display app bar with correct title', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AccountScreen(),
          ),
        ),
      );

      expect(find.text('プロフィール編集'), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('should display profile image placeholder', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AccountScreen(),
          ),
        ),
      );

      expect(find.byIcon(Icons.person), findsOneWidget);
      expect(find.byIcon(Icons.camera_alt), findsOneWidget);
    });

    testWidgets('should display nickname field', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AccountScreen(),
          ),
        ),
      );

      expect(find.text('ニックネーム'), findsOneWidget);
      expect(find.text('俺-サラー'), findsOneWidget);
    });

    testWidgets('should display user ID field', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AccountScreen(),
          ),
        ),
      );

      expect(find.text('ID'), findsOneWidget);
      expect(find.text('91nw8l6r'), findsOneWidget);
      expect(find.text('重複確認'), findsOneWidget);
    });

    testWidgets('should display email field', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AccountScreen(),
          ),
        ),
      );

      expect(find.text('電子メール'), findsOneWidget);
      expect(find.text('qi652009@gmail.com'), findsOneWidget);
    });

    testWidgets('should display gender selection buttons', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AccountScreen(),
          ),
        ),
      );

      expect(find.text('性別'), findsOneWidget);
      expect(find.text('選択しない'), findsOneWidget);
      expect(find.text('男性'), findsOneWidget);
      expect(find.text('女性'), findsOneWidget);
    });

    testWidgets('should display birth date field', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AccountScreen(),
          ),
        ),
      );

      expect(find.text('生年月日'), findsOneWidget);
      expect(find.text('2005.05.22'), findsOneWidget);
    });

    testWidgets('should display self introduction field', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AccountScreen(),
          ),
        ),
      );

      expect(find.text('自己紹介'), findsOneWidget);
      expect(find.text('Name 做-ｻｸ-\njob 大学生'), findsOneWidget);
    });

    testWidgets('should display registration date', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AccountScreen(),
          ),
        ),
      );

      expect(find.text('登録日'), findsOneWidget);
      expect(find.text('2024.10.14'), findsOneWidget);
    });

    testWidgets('should display save button', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AccountScreen(),
          ),
        ),
      );

      expect(find.text('保存'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsAtLeastNWidgets(1));
    });

    testWidgets('should handle gender selection', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AccountScreen(),
          ),
        ),
      );

      // 初期状態では男性が選択されている
      final maleButton = find.text('男性');
      expect(maleButton, findsOneWidget);

      // 女性ボタンをタップ
      await tester.tap(find.text('女性'));
      await tester.pump();

      // 女性が選択されていることを確認
      // （実際のテストでは、選択状態の見た目の変化を確認する）
    });
  });

  group('UserProfileNotifier Tests', () {
    test('should update nickname', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(userProfileProvider.notifier);
      final initialNickname = container.read(userProfileProvider).nickname;

      notifier.updateNickname('NewNickname');

      final updatedProfile = container.read(userProfileProvider);
      expect(updatedProfile.nickname, 'NewNickname');
      expect(updatedProfile.nickname, isNot(initialNickname));
    });

    test('should not update nickname if too long', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(userProfileProvider.notifier);
      final initialNickname = container.read(userProfileProvider).nickname;

      // 21文字のニックネーム（制限は20文字）
      notifier.updateNickname('VeryLongNicknameOver20Chars');

      final updatedProfile = container.read(userProfileProvider);
      expect(updatedProfile.nickname, initialNickname); // 変更されない
    });

    test('should update gender', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(userProfileProvider.notifier);

      notifier.updateGender('女性');

      final updatedProfile = container.read(userProfileProvider);
      expect(updatedProfile.gender, '女性');
    });

    test('should update birth date', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(userProfileProvider.notifier);
      final newBirthDate = DateTime(1995, 12, 25);

      notifier.updateBirthDate(newBirthDate);

      final updatedProfile = container.read(userProfileProvider);
      expect(updatedProfile.birthDate, newBirthDate);
    });

    test('should update self introduction', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(userProfileProvider.notifier);

      notifier.updateSelfIntroduction('New introduction');

      final updatedProfile = container.read(userProfileProvider);
      expect(updatedProfile.selfIntroduction, 'New introduction');
    });

    test('should not update self introduction if too long', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(userProfileProvider.notifier);
      final initialIntroduction = container.read(userProfileProvider).selfIntroduction;

      // 501文字の自己紹介（制限は500文字）
      final longIntroduction = 'a' * 501;
      notifier.updateSelfIntroduction(longIntroduction);

      final updatedProfile = container.read(userProfileProvider);
      expect(updatedProfile.selfIntroduction, initialIntroduction); // 変更されない
    });
  });
}