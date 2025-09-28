import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';

// ===== Domain Layer =====

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
    };
  }
}

// ===== Data Layer =====

/// ユーザープロフィールのリポジトリ
class UserProfileRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'users';

  /// 固定のユーザーID（1）を返す
  String get currentUserId {
    // 固定のID「1」を使用
    return '1';
  }

  /// ユーザープロフィールを取得
  Future<UserProfile> getUserProfile() async {
    try {
      final doc = await _firestore.collection(_collection).doc(currentUserId).get();
      
      if (doc.exists) {
        return UserProfile.fromFirestore(doc);
      }
      
      // ドキュメントが存在しない場合はデフォルト値を設定してユーザーを作成
      final defaultProfile = _getDefaultUserProfile();
      await _firestore.collection(_collection).doc(currentUserId).set(
        defaultProfile.toFirestore(),
      );
      
      return defaultProfile;
    } catch (e) {
      debugPrint('Firestoreからのプロフィール取得エラー: $e');
      // エラー時はデフォルト値を返す
      return _getDefaultUserProfile();
    }
  }

  /// デフォルトのプロフィール情報を生成
  UserProfile _getDefaultUserProfile() {
    return UserProfile(
      nickname: 'ユーザー',
      userId: currentUserId,
      email: '',
      gender: null,
      birthDate: null,
      residence: null,
      selfIntroduction: '自己紹介はまだ設定されていません',
      registrationDate: DateTime.now(),
      profileImagePath: null,
    );
  }

  /// プロフィールを保存
  Future<bool> saveUserProfile(UserProfile profile) async {
    try {
      await _firestore.collection(_collection).doc(profile.userId).set(
        profile.toFirestore(),
        SetOptions(merge: true),
      );
      
      debugPrint('Firestoreにプロフィールを保存しました: ${profile.nickname}');
      return true;
    } catch (e) {
      debugPrint('Firestoreへのプロフィール保存エラー: $e');
      return false;
    }
  }

  /// ユーザーIDの重複チェック
  Future<bool> checkUserIdAvailability(String userId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(userId).get();
      return !doc.exists; // ドキュメントが存在しなければ利用可能
    } catch (e) {
      debugPrint('Firestoreでのユーザーチェックエラー: $e');
      return false;
    }
  }
}

// ===== Application Layer =====

/// ユーザープロフィールリポジトリのプロバイダー
final userProfileRepositoryProvider = Provider<UserProfileRepository>(
  (ref) => UserProfileRepository(),
);

/// ユーザープロフィールの状態管理
class UserProfileNotifier extends StateNotifier<UserProfile?> {
  final UserProfileRepository _repository;
  
  // 初期状態はnull（ロード中）
  UserProfileNotifier(this._repository) : super(null) {
    // コンストラクターでFirebaseからデータを取得
    _loadProfile();
  }
  
  Future<void> _loadProfile() async {
    try {
      final profile = await _repository.getUserProfile();
      state = profile;
    } catch (e) {
      debugPrint('プロフィールロードエラー: $e');
      // エラー時はデフォルト値を設定
      state = UserProfile(
        nickname: 'ゲスト',
        userId: _repository.currentUserId,
        email: '',
        selfIntroduction: '読み込み中にエラーが発生しました',
        registrationDate: DateTime.now(),
      );
    }
  }

  /// プロフィールを強制的に再読み込み
  Future<void> refreshProfile() async {
    await _loadProfile();
  }
}

/// ユーザープロフィールのプロバイダー
final userProfileProvider = StateNotifierProvider<UserProfileNotifier, UserProfile?>(
  (ref) => UserProfileNotifier(ref.watch(userProfileRepositoryProvider)),
);

// ===== Presentation Layer =====

/// プロフィール表示画面
class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Firebaseからプロフィール情報を取得
    final profile = ref.watch(userProfileProvider);
    
    // プロフィールがロード中の場合はローディング表示
    if (profile == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('プロフィール'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
          centerTitle: true,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'プロフィール',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        foregroundColor: Colors.black87,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(userProfileProvider.notifier).refreshProfile();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // プロフィール画像セクション
              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade300, width: 2),
                    image: profile.profileImagePath != null
                        ? DecorationImage(
                            // URLの場合はNetworkImage、ファイルパスの場合はFileImage
                            image: profile.profileImagePath!.startsWith('http')
                                ? NetworkImage(profile.profileImagePath!) as ImageProvider
                                : FileImage(File(profile.profileImagePath!)),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: profile.profileImagePath == null
                      ? Icon(
                          Icons.person,
                          size: 60,
                          color: Colors.grey.shade400,
                        )
                      : null,
                ),
              ),

              const SizedBox(height: 32),

              // ニックネーム
              _buildSectionTitle('ニックネーム'),
              const SizedBox(height: 8),
              _buildInfoText(profile.nickname),

              const SizedBox(height: 24),

              // 自己紹介
              _buildSectionTitle('自己紹介'),
              const SizedBox(height: 8),
              _buildInfoText(profile.selfIntroduction),

              const SizedBox(height: 24),

              // ユーザーID
              _buildSectionTitle('ID'),
              const SizedBox(height: 8),
              _buildInfoText(profile.userId),
              const SizedBox(height: 4),
              Text(
                '英語、数字、「_」、「-」のみ使用可能',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),

              const SizedBox(height: 24),

              // 性別
              _buildSectionTitle('性別'),
              const SizedBox(height: 8),
              _buildInfoText(profile.gender ?? '未設定'),
              const SizedBox(height: 4),
              Text(
                'パーソナライズされた紹介や特典の情報としてのみ使用されます',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),

              const SizedBox(height: 24),

              // 生年月日
              _buildSectionTitle('生年月日'),
              const SizedBox(height: 8),
              _buildInfoText(
                profile.birthDate != null
                    ? '${profile.birthDate!.year}.${profile.birthDate!.month.toString().padLeft(2, '0')}.${profile.birthDate!.day.toString().padLeft(2, '0')}'
                    : '未設定',
              ),
              const SizedBox(height: 4),
              Text(
                'パーソナライズされた紹介や特典の情報としてのみ使用されます',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),

              const SizedBox(height: 24),
              
              // 居住地
              _buildSectionTitle('居住地'),
              const SizedBox(height: 8),
              _buildInfoText(profile.residence ?? '未設定'),
              const SizedBox(height: 4),
              Text(
                'イベントの紹介に使用されます',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),

              const SizedBox(height: 24),

              // 登録日
              _buildSectionTitle('登録日'),
              const SizedBox(height: 8),
              _buildInfoText(
                '${profile.registrationDate.year}.${profile.registrationDate.month.toString().padLeft(2, '0')}.${profile.registrationDate.day.toString().padLeft(2, '0')}',
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // セクションタイトルを構築
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }

  // 情報テキストを構築
  Widget _buildInfoText(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 16),
      ),
    );
  }
}
