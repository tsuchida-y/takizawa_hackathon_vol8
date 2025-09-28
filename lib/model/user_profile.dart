import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';

/// ユーザープロフィールのモデル
class UserProfile {
  final String nickname;
  final String userId;
  final String email;
  final String? gender;
  final DateTime? birthDate;
  final String? residence;
  final String selfIntroduction;
  final DateTime registrationDate;
  final String? profileImagePath;
  final DateTime? updatedAt;
  final int totalPoints;
  final int currentStreak;
  final int maxStreak;

  const UserProfile({
    required this.nickname,
    required this.userId,
    required this.email,
    this.gender,
    this.birthDate,
    this.residence,
    required this.selfIntroduction,
    required this.registrationDate,
    this.profileImagePath,
    this.updatedAt,
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
    String? residence,
    String? selfIntroduction,
    DateTime? registrationDate,
    String? profileImagePath,
    DateTime? updatedAt,
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
      residence: residence ?? this.residence,
      selfIntroduction: selfIntroduction ?? this.selfIntroduction,
      registrationDate: registrationDate ?? this.registrationDate,
      profileImagePath: profileImagePath ?? this.profileImagePath,
      updatedAt: updatedAt ?? this.updatedAt,
      totalPoints: totalPoints ?? this.totalPoints,
      currentStreak: currentStreak ?? this.currentStreak,
      maxStreak: maxStreak ?? this.maxStreak,
    );
  }
  
  /// Firestoreドキュメントからユーザープロフィールを生成
  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserProfile(
      nickname: data['nickname'] ?? '',
      userId: doc.id,
      email: data['email'] ?? '',
      gender: data['gender'],
      birthDate: data['birthDate'] != null 
          ? (data['birthDate'] as Timestamp).toDate() 
          : null,
      residence: data['residence'],
      selfIntroduction: data['selfIntroduction'] ?? '',
      registrationDate: data['registrationDate'] != null
          ? (data['registrationDate'] as Timestamp).toDate()
          : DateTime.now(),
      profileImagePath: data['profileImagePath'],
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      totalPoints: data['totalPoints'] ?? 0,
      currentStreak: data['currentStreak'] ?? 0,
      maxStreak: data['maxStreak'] ?? 0,
    );
  }

  /// FirestoreのMap形式に変換
  Map<String, dynamic> toFirestore() {
    return {
      'nickname': nickname,
      'email': email,
      'gender': gender,
      'birthDate': birthDate != null ? Timestamp.fromDate(birthDate!) : null,
      'residence': residence,
      'selfIntroduction': selfIntroduction,
      'registrationDate': Timestamp.fromDate(registrationDate),
      'profileImagePath': profileImagePath,
      'updatedAt': FieldValue.serverTimestamp(),
      'totalPoints': totalPoints,
      'currentStreak': currentStreak,
      'maxStreak': maxStreak,
    };
  }

  /// アバターURLを取得（ファイルパスがある場合はそれを優先）
  String get avatarUrl {
    if (profileImagePath != null) {
      if (profileImagePath!.startsWith('http')) {
        return profileImagePath!;
      } else if (File(profileImagePath!).existsSync()) {
        return profileImagePath!;
      }
    }
    return 'https://api.dicebear.com/7.x/avataaars/svg?seed=$userId';
  }
}