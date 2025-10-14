import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:takizawa_hackathon_vol8/model/user_profile.dart';
import 'package:takizawa_hackathon_vol8/screens/settings_screen/account.dart';

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
      expect(profile.residence, null);
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
        residence: '東京都',
      );

      expect(profile.nickname, 'TestUser');
      expect(profile.userId, 'test123');
      expect(profile.email, 'test@example.com');
      expect(profile.gender, '男性');
      expect(profile.birthDate, DateTime(1990, 5, 15));
      expect(profile.selfIntroduction, 'Hello World');
      expect(profile.registrationDate, DateTime(2024, 1, 1));
      expect(profile.profileImagePath, '/path/to/image.jpg');
      expect(profile.residence, '東京都');
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
        residence: '大阪府',
      );

      expect(updatedProfile.nickname, 'UpdatedUser');
      expect(updatedProfile.userId, 'test123'); // unchanged
      expect(updatedProfile.gender, '女性');
      expect(updatedProfile.residence, '大阪府');
    });
  });

  group('UserProfileRepository', () {
    late MockUserProfileRepository repository;

    setUp(() {
      repository = MockUserProfileRepository();
    });

    test('should return user profile', () async {
      final profile = await repository.getUserProfile();

      expect(profile, isA<UserProfile>());
      expect(profile.nickname, '做-ｻｸ-');
      expect(profile.userId, '91nw8l6r');
      expect(profile.email, 'qi652009@gmail.com');
      expect(profile.residence, '東京都');
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
        ProviderScope(
          overrides: [
            userProfileRepositoryProvider.overrideWithValue(MockUserProfileRepository()),
          ],
          child: const MaterialApp(
            home: AccountScreen(),
          ),
        ),
      );

      // 非同期データをロードするための待機
      await tester.pumpAndSettle();

      expect(find.text('プロフィール編集'), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('should display profile image placeholder', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userProfileRepositoryProvider.overrideWithValue(MockUserProfileRepository()),
          ],
          child: const MaterialApp(
            home: AccountScreen(),
          ),
        ),
      );

      // 非同期データをロードするための待機
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.person), findsOneWidget);
      expect(find.byIcon(Icons.camera_alt), findsOneWidget);
    });

    testWidgets('should display nickname field', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userProfileRepositoryProvider.overrideWithValue(MockUserProfileRepository()),
          ],
          child: const MaterialApp(
            home: AccountScreen(),
          ),
        ),
      );

      // 非同期データをロードするための待機
      await tester.pumpAndSettle();

      expect(find.text('ニックネーム'), findsOneWidget);
      expect(find.text('做-ｻｸ-'), findsOneWidget);
    });

    testWidgets('should display user ID field', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userProfileRepositoryProvider.overrideWithValue(MockUserProfileRepository()),
          ],
          child: const MaterialApp(
            home: AccountScreen(),
          ),
        ),
      );

      // 非同期データをロードするための待機
      await tester.pumpAndSettle();

      expect(find.text('ID'), findsOneWidget);
      expect(find.text('91nw8l6r'), findsOneWidget);
      expect(find.text('重複確認'), findsOneWidget);
    });

    testWidgets('should display residence field', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userProfileRepositoryProvider.overrideWithValue(MockUserProfileRepository()),
          ],
          child: const MaterialApp(
            home: AccountScreen(),
          ),
        ),
      );

      // 非同期データをロードするための待機
      await tester.pumpAndSettle();

      expect(find.text('居住地'), findsOneWidget);
      expect(find.text('東京都'), findsOneWidget);
    });

    // 他のウィジェットテストも同様に修正...
  });

  group('UserProfileNotifier Tests', () {
    late ProviderContainer container;
    
    setUp(() {
      container = ProviderContainer(
        overrides: [
          userProfileRepositoryProvider.overrideWithValue(MockUserProfileRepository()),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    // 非同期データをロードするための待機メソッド
    Future<void> waitForAsyncData() async {
      await Future.delayed(Duration.zero);
    }

    test('should update nickname', () async {
      await waitForAsyncData();
      
      final notifier = container.read(userProfileProvider.notifier);
      final initialNickname = container.read(userProfileProvider)?.nickname;

      notifier.updateNickname('NewNickname');

      final updatedProfile = container.read(userProfileProvider);
      expect(updatedProfile?.nickname, 'NewNickname');
      expect(updatedProfile?.nickname, isNot(initialNickname));
    });

    test('should not update nickname if too long', () async {
      await waitForAsyncData();
      
      final notifier = container.read(userProfileProvider.notifier);
      final initialNickname = container.read(userProfileProvider)?.nickname;

      // 21文字のニックネーム（制限は20文字）
      notifier.updateNickname('VeryLongNicknameOver20Chars');

      final updatedProfile = container.read(userProfileProvider);
      expect(updatedProfile?.nickname, initialNickname); // 変更されない
    });

    test('should update gender', () async {
      await waitForAsyncData();
      
      final notifier = container.read(userProfileProvider.notifier);

      notifier.updateGender('女性');

      final updatedProfile = container.read(userProfileProvider);
      expect(updatedProfile?.gender, '女性');
    });

    test('should update residence', () async {
      await waitForAsyncData();
      
      final notifier = container.read(userProfileProvider.notifier);

      notifier.updateResidence('大阪府');

      final updatedProfile = container.read(userProfileProvider);
      expect(updatedProfile?.residence, '大阪府');
    });

    test('should update birth date', () async {
      await waitForAsyncData();
      
      final notifier = container.read(userProfileProvider.notifier);
      final newBirthDate = DateTime(1995, 12, 25);

      notifier.updateBirthDate(newBirthDate);

      final updatedProfile = container.read(userProfileProvider);
      expect(updatedProfile?.birthDate, newBirthDate);
    });

    test('should update self introduction', () async {
      await waitForAsyncData();
      
      final notifier = container.read(userProfileProvider.notifier);

      notifier.updateSelfIntroduction('New introduction');

      final updatedProfile = container.read(userProfileProvider);
      expect(updatedProfile?.selfIntroduction, 'New introduction');
    });

    test('should not update self introduction if too long', () async {
      await waitForAsyncData();
      
      final notifier = container.read(userProfileProvider.notifier);
      final initialIntroduction = container.read(userProfileProvider)?.selfIntroduction;

      // 501文字の自己紹介（制限は500文字）
      final longIntroduction = 'a' * 501;
      notifier.updateSelfIntroduction(longIntroduction);

      final updatedProfile = container.read(userProfileProvider);
      expect(updatedProfile?.selfIntroduction, initialIntroduction); // 変更されない
    });
  });
}