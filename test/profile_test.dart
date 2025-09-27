import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:takizawa_hackathon_vol8/profile.dart';

/// プロフィール画面のテスト
void main() {
  group('ProfileScreen Models', () {
    test('EventInfo generates sample data correctly', () {
      final events = EventInfo.generateSampleEvents();
      
      expect(events.length, 4);
      expect(events[0].title, 'ハッカソン Vol.8');
      expect(events[0].description, 'モバイルアプリ開発ハッカソン');
      expect(events[0].date, '2025/01/15');
      expect(events[0].location, 'Tokyo Tech Hub');
    });

    test('HeatmapData generates correct amount of data', () {
      final heatmapData = HeatmapData.generateSampleHeatmapData();
      
      expect(heatmapData.length, 365 * 6); // 6年分のデータ
      
      // 各データにポイントとレベルが設定されていることを確認
      for (final data in heatmapData.take(10)) {
        expect(data.points, greaterThanOrEqualTo(0));
        expect(data.level, inInclusiveRange(0, 4));
      }
    });

    test('UserProfile has correct sample data', () {
      const profile = UserProfile.sampleProfile;
      
      expect(profile.name, 'あなた');
      expect(profile.totalPoints, 2548);
      expect(profile.currentStreak, 12);
      expect(profile.maxStreak, 45);
      expect(profile.joinDate, '2024/03/15');
      expect(profile.avatarUrl.isNotEmpty, true);
    });

    test('HeatmapData level is within valid range', () {
      final heatmapData = HeatmapData.generateSampleHeatmapData();
      
      for (final data in heatmapData.take(100)) {
        expect(data.level, inInclusiveRange(0, 4));
        
        // レベルとポイントの関係をテスト
        if (data.points == 0) {
          expect(data.level, 0);
        } else {
          expect(data.level, greaterThan(0));
        }
      }
    });
  });

  group('ProfileScreen Providers', () {
    test('userProfileProvider returns sample profile', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final profile = container.read(userProfileProvider);
      expect(profile.name, 'あなた');
      expect(profile.totalPoints, 2548);
    });

    test('eventInfoProvider returns sample events', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final events = container.read(eventInfoProvider);
      expect(events.length, 4);
      expect(events[0].title, 'ハッカソン Vol.8');
    });

    test('heatmapDataProvider returns 6 years of data', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final heatmapData = container.read(heatmapDataProvider);
      expect(heatmapData.length, 365 * 6); // 6年分のデータ
    });

    test('selectedHeatmapPeriodProvider has default value', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final period = container.read(selectedHeatmapPeriodProvider);
      expect(period, 365);
    });

    test('selectedHeatmapPeriodProvider can be changed', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // 初期値を確認
      expect(container.read(selectedHeatmapPeriodProvider), 365);

      // 値を変更
      container.read(selectedHeatmapPeriodProvider.notifier).state = 30;
      expect(container.read(selectedHeatmapPeriodProvider), 30);
    });
  });

  group('Data Validation', () {
    test('HeatmapData dates are sequential', () {
      final heatmapData = HeatmapData.generateSampleHeatmapData();
      
      // 最初の数日の日付が連続していることを確認
      for (int i = 1; i < 10; i++) {
        final previousDate = heatmapData[i - 1].date;
        final currentDate = heatmapData[i].date;
        final expectedDate = previousDate.add(const Duration(days: 1));
        
        expect(currentDate.year, expectedDate.year);
        expect(currentDate.month, expectedDate.month);
        expect(currentDate.day, expectedDate.day);
      }
    });

    test('EventInfo has valid colors', () {
      final events = EventInfo.generateSampleEvents();
      
      for (final event in events) {
        expect(event.color.r, greaterThanOrEqualTo(0));
        expect(event.title.isNotEmpty, true);
        expect(event.description.isNotEmpty, true);
        expect(event.date.isNotEmpty, true);
        expect(event.location.isNotEmpty, true);
      }
    });
  });
}
