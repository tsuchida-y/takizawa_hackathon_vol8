import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'dart:math';

/// 共通のユーザープロフィールモデル
class UserProfile {
  final String nickname;
  final String userId;
  final String email;
  final String? gender;
  final DateTime? birthDate;
  final String selfIntroduction;
  final DateTime registrationDate;
  final String? profileImagePath;
  final int totalPoints;
  final int currentStreak;
  final int maxStreak;

  const UserProfile({
    required this.nickname,
    required this.userId,
    required this.email,
    this.gender,
    this.birthDate,
    required this.selfIntroduction,
    required this.registrationDate,
    this.profileImagePath,
    this.totalPoints = 2548,
    this.currentStreak = 12,
    this.maxStreak = 45,
  });

  UserProfile copyWith({
    String? nickname,
    String? userId,
    String? email,
    String? gender,
    DateTime? birthDate,
    String? selfIntroduction,
    DateTime? registrationDate,
    String? profileImagePath,
    int? totalPoints,
    int? currentStreak,
    int? maxStreak,
  }) {
    return UserProfile(
      nickname: nickname ?? this.nickname,
      userId: userId ?? this.userId,
      email: email ?? this.email,
      gender: gender ?? this.gender,
      birthDate: birthDate ?? this.birthDate,
      selfIntroduction: selfIntroduction ?? this.selfIntroduction,
      registrationDate: registrationDate ?? this.registrationDate,
      profileImagePath: profileImagePath ?? this.profileImagePath,
      totalPoints: totalPoints ?? this.totalPoints,
      currentStreak: currentStreak ?? this.currentStreak,
      maxStreak: maxStreak ?? this.maxStreak,
    );
  }

  /// アバターURLを取得（ファイルパスがある場合はそれを優先）
  String get avatarUrl {
    if (profileImagePath != null && File(profileImagePath!).existsSync()) {
      return profileImagePath!;
    }
    return 'https://api.dicebear.com/7.x/avataaars/svg?seed=$userId';
  }

  /// 表示名を取得（ニックネームまたは「あなた」）
  String get displayName {
    return nickname.isNotEmpty ? nickname : 'あなた';
  }
}

/// ユーザープロフィールのリポジトリ
class UserProfileRepository {
  /// 初期ニックネームを生成（TSU + 6桁の乱数）
  String _generateInitialNickname() {
    final random = Random();
    final randomNumber = random.nextInt(999999).toString().padLeft(6, '0');
    return 'TSU$randomNumber';
  }

  UserProfile getUserProfile() {
    return UserProfile(
      nickname: _generateInitialNickname(),
      userId: '91nw8l6r',
      email: '',
      gender: '男性',
      birthDate: DateTime(2005, 5, 22),
      selfIntroduction: 'Name TSU******\njob 大学生',
      registrationDate: DateTime(2024, 10, 14),
      profileImagePath: null,
      totalPoints: 2548,
      currentStreak: 12,
      maxStreak: 45,
    );
  }

  Future<bool> saveUserProfile(UserProfile profile) async {
    await Future.delayed(const Duration(milliseconds: 500));
    debugPrint('プロフィールを保存しました: ${profile.nickname}');
    return true;
  }

  Future<bool> checkUserIdAvailability(String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final unavailableIds = ['admin', 'user', 'test', '91nw8l6r'];
    return !unavailableIds.contains(userId.toLowerCase());
  }
}

/// ユーザープロフィールの状態管理
class UserProfileNotifier extends StateNotifier<UserProfile> {
  final UserProfileRepository _repository;

  UserProfileNotifier(this._repository) : super(_repository.getUserProfile());

  /// ニックネームを更新
  void updateNickname(String nickname) {
    if (nickname.length <= 20) {
      state = state.copyWith(nickname: nickname);
    }
  }

  /// ユーザーIDを更新
  void updateUserId(String userId) {
    state = state.copyWith(userId: userId);
  }

  /// 性別を更新
  void updateGender(String? gender) {
    state = state.copyWith(gender: gender);
  }

  /// 生年月日を更新
  void updateBirthDate(DateTime? birthDate) {
    state = state.copyWith(birthDate: birthDate);
  }

  /// 自己紹介を更新
  void updateSelfIntroduction(String selfIntroduction) {
    if (selfIntroduction.length <= 500) {
      state = state.copyWith(selfIntroduction: selfIntroduction);
    }
  }

  /// プロフィール画像を更新
  void updateProfileImage(String? imagePath) {
    state = state.copyWith(profileImagePath: imagePath);
  }

  /// ポイントを更新（ポイント獲得システムから呼び出される）
  void updatePoints(int totalPoints, int currentStreak, int maxStreak) {
    state = state.copyWith(
      totalPoints: totalPoints,
      currentStreak: currentStreak,
      maxStreak: maxStreak,
    );
  }

  /// プロフィールを保存
  Future<bool> saveProfile() async {
    return await _repository.saveUserProfile(state);
  }

  /// ユーザーIDの重複チェック
  Future<bool> checkUserIdAvailability(String userId) async {
    return await _repository.checkUserIdAvailability(userId);
  }
}

/// 共通のユーザープロフィールリポジトリプロバイダー
final userProfileRepositoryProvider = Provider<UserProfileRepository>(
  (ref) => UserProfileRepository(),
);

/// 共通のユーザープロフィールプロバイダー
final sharedUserProfileProvider = StateNotifierProvider<UserProfileNotifier, UserProfile>(
  (ref) => UserProfileNotifier(ref.watch(userProfileRepositoryProvider)),
);