import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

// ===== Domain Layer =====

/// ユーザープロフィールのモデル
class UserProfile {
  final String nickname;
  final String userId;
  final String email;
  final String? gender;
  final DateTime? birthDate;
  final String selfIntroduction;
  final DateTime registrationDate;
  final String? profileImagePath;

  const UserProfile({
    required this.nickname,
    required this.userId,
    required this.email,
    this.gender,
    this.birthDate,
    required this.selfIntroduction,
    required this.registrationDate,
    this.profileImagePath,
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
    );
  }
}

// ===== Data Layer =====

/// ユーザープロフィールのリポジトリ
class UserProfileRepository {
  /// ダミーデータを取得
  UserProfile getUserProfile() {
    return UserProfile(
      nickname: '做-ｻｸ-',
      userId: '91nw8l6r',
      gender: '男性',
      birthDate: DateTime(2005, 5, 22),
      selfIntroduction: 'Name 做-ｻｸ-\njob 大学生',
      registrationDate: DateTime(2024, 10, 14),
      profileImagePath: null, email: '', // ダミーではnull
    );
  }

  /// プロフィールを保存
  Future<bool> saveUserProfile(UserProfile profile) async {
    // 実際の実装では、APIを呼び出すかローカルストレージに保存
    await Future.delayed(const Duration(milliseconds: 500));
    debugPrint('プロフィールを保存しました: ${profile.nickname}');
    return true;
  }

  /// ユーザーIDの重複チェック
  Future<bool> checkUserIdAvailability(String userId) async {
    // 実際の実装では、APIを呼び出してチェック
    await Future.delayed(const Duration(milliseconds: 300));
    // ダミーでは特定のIDを重複として扱う
    final unavailableIds = ['admin', 'user', 'test', '91nw8l6r'];
    return !unavailableIds.contains(userId.toLowerCase());
  }
}

// ===== Application Layer =====

/// ユーザープロフィールリポジトリのプロバイダー
final userProfileRepositoryProvider = Provider<UserProfileRepository>(
  (ref) => UserProfileRepository(),
);

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

  /// プロフィールを保存
  Future<bool> saveProfile() async {
    return await _repository.saveUserProfile(state);
  }

  /// ユーザーIDの重複チェック
  Future<bool> checkUserIdAvailability(String userId) async {
    return await _repository.checkUserIdAvailability(userId);
  }
}

/// ユーザープロフィールのプロバイダー
final userProfileProvider = StateNotifierProvider<UserProfileNotifier, UserProfile>(
  (ref) => UserProfileNotifier(ref.watch(userProfileRepositoryProvider)),
);

// ===== Presentation Layer =====

/// アカウント設定画面
class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  late TextEditingController _nicknameController;
  late TextEditingController _userIdController;
  late TextEditingController _selfIntroductionController;
  bool _isUserIdChecking = false;
  bool _isUserIdAvailable = true;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(userProfileProvider);
    _nicknameController = TextEditingController(text: profile.nickname);
    _userIdController = TextEditingController(text: profile.userId);
    _selfIntroductionController = TextEditingController(text: profile.selfIntroduction);
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _userIdController.dispose();
    _selfIntroductionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider);
    final notifier = ref.read(userProfileProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'プロフィール編集',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // プロフィール画像セクション
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade300, width: 2),
                      image: profile.profileImagePath != null
                          ? DecorationImage(
                              image: FileImage(File(profile.profileImagePath!)),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: profile.profileImagePath == null
                        ? Icon(
                            Icons.person,
                            size: 50,
                            color: Colors.grey.shade400,
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () => _showImagePicker(context),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ニックネーム
            _buildSectionTitle('ニックネーム', isRequired: true),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _nicknameController,
              hintText: 'ニックネームを入力',
              maxLength: 20,
              onChanged: (value) => notifier.updateNickname(value),
            ),

            const SizedBox(height: 24),

            // 自己紹介
            _buildSectionTitle('自己紹介'),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: TextField(
                controller: _selfIntroductionController,
                maxLines: 8,
                maxLength: 500,
                onChanged: (value) => notifier.updateSelfIntroduction(value),
                decoration: const InputDecoration(
                  hintText: '自己紹介を入力してください',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                  counterText: '',
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${profile.selfIntroduction.length}/500',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ),

            const SizedBox(height: 24),

            // ユーザーID
            _buildSectionTitle('ID', isRequired: true),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _userIdController,
                    hintText: 'ユーザーIDを入力',
                    onChanged: (value) => notifier.updateUserId(value),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 80,
                  child: ElevatedButton(
                    onPressed: _isUserIdChecking ? null : _checkUserId,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade200,
                      foregroundColor: Colors.black87,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: _isUserIdChecking
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(
                            '重複確認',
                            style: TextStyle(fontSize: 12),
                          ),
                  ),
                ),
              ],
            ),
            if (!_isUserIdAvailable)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  'このIDは既に使用されています',
                  style: TextStyle(fontSize: 12, color: Colors.red),
                ),
              ),
            const Text(
              '英語、数字、「_」、「-」だけが使えて、一度登録したら変更できません。',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),

            const SizedBox(height: 24),

            // 性別
            _buildSectionTitle('性別'),
            const SizedBox(height: 8),
            const Text(
              'パーソナライズされた紹介や特典の情報としてのみ使用され、他の人には公開されません。',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildGenderButton('選択しない', profile.gender == null),
                const SizedBox(width: 12),
                _buildGenderButton('男性', profile.gender == '男性'),
                const SizedBox(width: 12),
                _buildGenderButton('女性', profile.gender == '女性'),
              ],
            ),

            const SizedBox(height: 24),

            // 生年月日
            _buildSectionTitle('生年月日'),
            const SizedBox(height: 8),
            const Text(
              'パーソナライズされた紹介や特典の情報としてのみ使用され、他の人には公開されません。',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => _selectBirthDate(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        profile.birthDate != null
                            ? '${profile.birthDate!.year}.${profile.birthDate!.month.toString().padLeft(2, '0')}.${profile.birthDate!.day.toString().padLeft(2, '0')}'
                            : '生年月日を選択',
                        style: TextStyle(
                          fontSize: 16,
                          color: profile.birthDate != null
                              ? Colors.black87
                              : Colors.grey.shade500,
                        ),
                      ),
                    ),
                    Icon(Icons.calendar_today, color: Colors.grey.shade400),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 登録日
            _buildSectionTitle('登録日'),
            const SizedBox(height: 8),
            Text(
              '${profile.registrationDate.year}.${profile.registrationDate.month.toString().padLeft(2, '0')}.${profile.registrationDate.day.toString().padLeft(2, '0')}',
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),

            const SizedBox(height: 32),

            // 保存ボタン
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  '保存',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, {bool isRequired = false}) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        if (isRequired)
          const Text(
            ' *必須',
            style: TextStyle(
              fontSize: 12,
              color: Colors.red,
            ),
          ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    int? maxLength,
    Function(String)? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextField(
        controller: controller,
        maxLength: maxLength,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hintText,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          counterText: maxLength != null ? '${controller.text.length}/$maxLength' : null,
        ),
      ),
    );
  }

  Widget _buildGenderButton(String gender, bool isSelected) {
    return GestureDetector(
      onTap: () {
        final notifier = ref.read(userProfileProvider.notifier);
        notifier.updateGender(gender == '選択しない' ? null : gender);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black87 : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.black87 : Colors.grey.shade300,
          ),
        ),
        child: Text(
          gender,
          style: TextStyle(
            fontSize: 14,
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  void _showImagePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('カメラで撮影'),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromCamera();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('ギャラリーから選択'),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromGallery();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImageFromCamera() async {
    try {
      // カメラ権限をチェック
      final cameraStatus = await Permission.camera.request();
      if (!cameraStatus.isGranted) {
        _showPermissionDeniedDialog('カメラ');
        return;
      }

      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );

      if (image != null) {
        ref.read(userProfileProvider.notifier).updateProfileImage(image.path);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('プロフィール画像を更新しました'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('カメラエラー: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('カメラの起動に失敗しました'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      // ストレージ権限をチェック
      PermissionStatus storageStatus;
      if (Platform.isAndroid) {
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;
        if (androidInfo.version.sdkInt >= 33) {
          storageStatus = await Permission.photos.request();
        } else {
          storageStatus = await Permission.storage.request();
        }
      } else {
        storageStatus = await Permission.photos.request();
      }

      if (!storageStatus.isGranted) {
        _showPermissionDeniedDialog('ストレージ');
        return;
      }

      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );

      if (image != null) {
        ref.read(userProfileProvider.notifier).updateProfileImage(image.path);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('プロフィール画像を更新しました'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('ギャラリーエラー: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ギャラリーの起動に失敗しました'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _checkUserId() async {
    setState(() => _isUserIdChecking = true);
    
    final notifier = ref.read(userProfileProvider.notifier);
    final isAvailable = await notifier.checkUserIdAvailability(_userIdController.text);
    
    setState(() {
      _isUserIdChecking = false;
      _isUserIdAvailable = isAvailable;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isAvailable ? 'このIDは使用できます' : 'このIDは既に使用されています',
          ),
          backgroundColor: isAvailable ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _selectBirthDate(BuildContext context) async {
    final profile = ref.read(userProfileProvider);
    final initialDate = profile.birthDate ?? DateTime(2000);
    
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );

    if (selectedDate != null) {
      ref.read(userProfileProvider.notifier).updateBirthDate(selectedDate);
    }
  }

  void _showPermissionDeniedDialog(String permissionType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('権限が必要です'),
        content: Text('${permissionType}を使用するには権限の許可が必要です。設定から権限を有効にしてください。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('設定を開く'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveProfile() async {
    final notifier = ref.read(userProfileProvider.notifier);
    
    try {
      final success = await notifier.saveProfile();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? 'プロフィールを保存しました' : '保存に失敗しました',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
        
        if (success) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('エラーが発生しました'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}