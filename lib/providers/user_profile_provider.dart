import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';

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
    this.totalPoints = 0,
    this.currentStreak = 0,
    this.maxStreak = 0,
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
  
  /// Firestoreドキュメントからユーザープロフィールを生成
  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserProfile(
      nickname: data['nickname'] ?? '',
      userId: doc.id,
      email: data['email'] ?? '',
      gender: data['gender'],
      birthDate: data['birthDate'] != null 
          ? (data['birthDate'] as Timestamp).toDate() 
          : null,
      selfIntroduction: data['selfIntroduction'] ?? '',
      registrationDate: data['registrationDate'] != null
          ? (data['registrationDate'] as Timestamp).toDate()
          : DateTime.now(),
      profileImagePath: data['profileImagePath'],
      totalPoints: data['totalPoints'] ?? 0,
      currentStreak: data['currentStreak'] ?? 0,
      maxStreak: data['maxStreak'] ?? 0,
    );
  }
  
  /// Firestoreに保存するデータを生成
  Map<String, dynamic> toFirestore() {
    return {
      'nickname': nickname,
      'email': email,
      'gender': gender,
      'birthDate': birthDate != null ? Timestamp.fromDate(birthDate!) : null,
      'selfIntroduction': selfIntroduction,
      'registrationDate': Timestamp.fromDate(registrationDate),
      'profileImagePath': profileImagePath,
      'totalPoints': totalPoints,
      'currentStreak': currentStreak,
      'maxStreak': maxStreak,
      'updatedAt': Timestamp.now(),
    };
  }
}

/// ユーザープロフィールのリポジトリ
class UserProfileRepository {
  late final FirebaseFirestore _firestore;
  
  UserProfileRepository() {
    try {
      _firestore = FirebaseFirestore.instance;
    } catch (e) {
      debugPrint('Firebase初期化エラー: $e');
      // エラー時はフィールドは未初期化のままになりますが、
      // 各メソッドでnullチェックを行うので問題ありません
    }
  }  /// ユーザープロフィールを取得（Firestoreからのみ、固定ID「1」を使用）
  Future<UserProfile> getUserProfile() async {
    try {
      // 固定のドキュメントID「1」を使用
      const fixedUserId = '1';
      
      // Firestoreからプロフィールを取得
      final doc = await _firestore.collection('users').doc(fixedUserId).get();
      
      // ドキュメントが存在する場合
      if (doc.exists) {
        debugPrint('Firestoreからユーザープロフィールを取得: ${doc.id}');
        return UserProfile.fromFirestore(doc);
      } else {
        // ドキュメントが存在しない場合は新しいプロフィールを作成して保存
        debugPrint('ユーザープロフィールが存在しないため、新規作成します');
        final newProfile = _createInitialProfile(fixedUserId);
        await _saveUserProfileToFirestore(newProfile);
        return newProfile;
      }
    } catch (e) {
      debugPrint('ユーザープロフィール取得エラー: $e');
      // エラーが発生した場合は、初期プロフィールを返す
      return _createInitialProfile('1');
    }
  }
  
  /// 初期プロフィールを作成（固定ID「1」用）
  UserProfile _createInitialProfile(String userId) {
    return UserProfile(
      nickname: 'TSU987148',
      userId: userId,
      email: '',
      gender: '男性',
      birthDate: DateTime(2005, 5, 22),
      selfIntroduction: 'Name TSU******\njob 大学生',
      registrationDate: DateTime.now(),
      profileImagePath: null,
      totalPoints: 2548,
      currentStreak: 12,
      maxStreak: 45,
    );
  }
  
  /// ユーザープロフィールをFirestoreに保存
  Future<bool> saveUserProfile(UserProfile profile) async {
    try {
      await _saveUserProfileToFirestore(profile);
      debugPrint('プロフィールを保存しました: ${profile.nickname}');
      return true;
    } catch (e) {
      debugPrint('プロフィール保存エラー: $e');
      return false;
    }
  }
  
  /// Firestoreにプロフィールを保存する内部メソッド（固定ID「1」を使用）
  Future<void> _saveUserProfileToFirestore(UserProfile profile) async {
    // 常に固定のID「1」を使用
    const fixedUserId = '1';
    await _firestore.collection('users').doc(fixedUserId).set(
      profile.toFirestore(),
      SetOptions(merge: true),
    );
  }

  Future<bool> checkUserIdAvailability(String userId) async {
    try {
      final query = await _firestore
          .collection('users')
          .where('customId', isEqualTo: userId)
          .limit(1)
          .get();
      
      return query.docs.isEmpty;
    } catch (e) {
      debugPrint('ユーザーID重複チェックエラー: $e');
      return false;
    }
  }

  // メソッドは下方に移動しました
}

/// ユーザープロフィールの状態管理
class UserProfileNotifier extends StateNotifier<UserProfile> {
  final UserProfileRepository _repository;
  bool _isLoading = false;

  UserProfileNotifier(this._repository) : super(UserProfile(
    nickname: '',
    userId: '',
    email: '',
    selfIntroduction: '',
    registrationDate: DateTime.now(),
  )) {
    _loadProfile();
  }

  /// プロフィールを読み込む
  Future<void> _loadProfile() async {
    if (_isLoading) return;
    
    _isLoading = true;
    try {
      final profile = await _repository.getUserProfile();
      state = profile;
      debugPrint('プロフィールを正常に読み込みました: ${profile.nickname}');
    } catch (e) {
      debugPrint('プロフィール読み込みエラー: $e');
      // エラー発生時は状態を変更しない（初期状態のまま）
      // ここではUIに表示するエラーメッセージなどを設定することもできます
    } finally {
      _isLoading = false;
    }
  }

  /// プロフィールを再読み込み
  Future<void> refreshProfile() async {
    await _loadProfile();
  }

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
    final result = await _repository.saveUserProfile(state);
    if (result) {
      await refreshProfile();
    }
    return result;
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