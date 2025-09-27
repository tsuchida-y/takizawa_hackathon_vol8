import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

// ===== Domain Layer =====

/// FAQ項目のモデル
class FAQItem {
  final String id;
  final String question;
  final String answer;
  final String category;

  const FAQItem({
    required this.id,
    required this.question,
    required this.answer,
    required this.category,
  });
}

/// お問い合わせの種類
enum ContactType {
  bug('不具合報告'),
  feature('機能要望'),
  account('アカウント'),
  payment('決済'),
  other('その他');

  const ContactType(this.displayName);
  final String displayName;
}

/// お問い合わせフォームのモデル
class ContactForm {
  final ContactType type;
  final String email;
  final String subject;
  final String message;

  const ContactForm({
    required this.type,
    required this.email,
    required this.subject,
    required this.message,
  });
}

// ===== Data Layer =====

/// ヘルプデータのリポジトリ
class HelpRepository {
  /// FAQ項目を取得
  List<FAQItem> getFAQItems() {
    return [
      const FAQItem(
        id: 'account_01',
        question: 'アカウントの作成方法を教えてください',
        answer: 'アプリを初回起動時に、必要な情報を入力してアカウントを作成できます。ニックネームとユーザーIDは必須項目です。',
        category: 'アカウント',
      ),
      const FAQItem(
        id: 'account_02',
        question: 'パスワードを忘れてしまいました',
        answer: 'ログイン画面の「パスワードを忘れた方」から、登録済みのメールアドレスを入力してパスワードリセットを行ってください。',
        category: 'アカウント',
      ),
      const FAQItem(
        id: 'notification_01',
        question: '通知が来ないのですが',
        answer: '設定→通知から、プッシュ通知がオンになっているか確認してください。また、端末の設定でもアプリの通知許可が必要です。',
        category: '通知',
      ),
      const FAQItem(
        id: 'notification_02',
        question: '通知音を変更できますか？',
        answer: '現在は端末の標準通知音を使用しています。今後のアップデートで通知音のカスタマイズ機能を追加予定です。',
        category: '通知',
      ),
      const FAQItem(
        id: 'sns_01',
        question: 'SNS連携するとどうなりますか？',
        answer: 'SNSアカウントと連携すると、ログインが簡単になり、SNSの友達を見つけやすくなります。個人情報は適切に保護されます。',
        category: 'SNS連携',
      ),
      const FAQItem(
        id: 'sns_02',
        question: 'SNS連携を解除したいです',
        answer: '設定→SNS連携から、連携を解除したいSNSの「連携解除」ボタンをタップしてください。',
        category: 'SNS連携',
      ),
      const FAQItem(
        id: 'app_01',
        question: 'アプリが重いです',
        answer: 'アプリを完全に終了して再起動してください。それでも改善しない場合は、端末の再起動をお試しください。',
        category: 'アプリ',
      ),
      const FAQItem(
        id: 'app_02',
        question: 'データが消えてしまいました',
        answer: 'アカウントにログインしていれば、データはクラウドに保存されています。ログインし直してデータを復元してください。',
        category: 'アプリ',
      ),
    ];
  }

  /// アプリ情報を取得
  Map<String, String> getAppInfo() {
    return {
      'バージョン': '1.0.0',
      'ビルド番号': '1',
      '最終更新': '2025年9月28日',
      '開発者': 'Takizawa Hackathon Team',
      '利用規約': 'https://example.com/terms',
      'プライバシーポリシー': 'https://example.com/privacy',
    };
  }

  /// お問い合わせを送信
  Future<bool> sendContact(ContactForm form) async {
    debugPrint('お問い合わせを送信中...');
    debugPrint('種類: ${form.type.displayName}');
    debugPrint('メール: ${form.email}');
    debugPrint('件名: ${form.subject}');
    debugPrint('内容: ${form.message}');

    // 送信処理をシミュレート
    await Future.delayed(const Duration(seconds: 2));

    debugPrint('お問い合わせを送信しました');
    return true;
  }
}

// ===== Application Layer =====

/// ヘルプリポジトリのプロバイダー
final helpRepositoryProvider = Provider<HelpRepository>(
  (ref) => HelpRepository(),
);

/// FAQ項目リストのプロバイダー
final faqItemsProvider = Provider<List<FAQItem>>(
  (ref) => ref.watch(helpRepositoryProvider).getFAQItems(),
);

/// アプリ情報のプロバイダー
final appInfoProvider = Provider<Map<String, String>>(
  (ref) => ref.watch(helpRepositoryProvider).getAppInfo(),
);

// ===== Presentation Layer =====

/// ヘルプ画面
class HelpScreen extends ConsumerWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'ヘルプ',
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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // よくある質問セクション
          _buildSectionHeader('よくある質問', Icons.help_outline),
          const SizedBox(height: 12),
          _buildFAQSection(ref),

          const SizedBox(height: 32),

          // お問い合わせセクション
          _buildSectionHeader('お問い合わせ', Icons.mail_outline),
          const SizedBox(height: 12),
          _buildContactCard(context),

          const SizedBox(height: 32),

          // アプリ情報セクション
          _buildSectionHeader('アプリ情報', Icons.info_outline),
          const SizedBox(height: 12),
          _buildAppInfoSection(ref),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue.shade600, size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.blue.shade800,
          ),
        ),
      ],
    );
  }

  Widget _buildFAQSection(WidgetRef ref) {
    final faqItems = ref.watch(faqItemsProvider);
    final categories = faqItems.map((item) => item.category).toSet().toList();

    return Column(
      children: categories.map((category) {
        final categoryItems = faqItems.where((item) => item.category == category).toList();
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                category,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
            ),
            ...categoryItems.map((item) => _buildFAQItem(item)),
            const SizedBox(height: 16),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildFAQItem(FAQItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        title: Text(
          item.question,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              item.answer,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.mail_outline,
            color: Colors.green.shade600,
            size: 24,
          ),
        ),
        title: const Text(
          'お問い合わせフォーム',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: const Text(
          'ご質問やご要望をお聞かせください',
          style: TextStyle(fontSize: 14),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => _showContactForm(context),
      ),
    );
  }

  Widget _buildAppInfoSection(WidgetRef ref) {
    final appInfo = ref.watch(appInfoProvider);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: appInfo.entries.map((entry) {
          final isLast = entry == appInfo.entries.last;
          
          return Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                title: Text(
                  entry.key,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                trailing: Text(
                  entry.value,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                onTap: entry.key.contains('利用規約') || entry.key.contains('プライバシー')
                    ? () => _showWebView(entry.key, entry.value)
                    : null,
              ),
              if (!isLast) Divider(height: 1, color: Colors.grey.shade200),
            ],
          );
        }).toList(),
      ),
    );
  }

  void _showContactForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ContactFormSheet(),
    );
  }

  void _showWebView(String title, String url) {
    debugPrint('$title を開く: $url');
    // TODO: WebViewまたはブラウザでURLを開く
  }
}

/// お問い合わせフォームのボトムシート
class ContactFormSheet extends ConsumerStatefulWidget {
  const ContactFormSheet({super.key});

  @override
  ConsumerState<ContactFormSheet> createState() => _ContactFormSheetState();
}

class _ContactFormSheetState extends ConsumerState<ContactFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  
  ContactType _selectedType = ContactType.other;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // ハンドル
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // タイトル
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Text(
                  'お問い合わせ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          const Divider(),

          // フォーム
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // お問い合わせ種類
                  const Text(
                    'お問い合わせの種類',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<ContactType>(
                    value: _selectedType,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    items: ContactType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type.displayName),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedType = value;
                        });
                      }
                    },
                  ),

                  const SizedBox(height: 24),

                  // メールアドレス
                  const Text(
                    'メールアドレス',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      hintText: 'example@email.com',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'メールアドレスを入力してください';
                      }
                      if (!value.contains('@')) {
                        return '正しいメールアドレスを入力してください';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 24),

                  // 件名
                  const Text(
                    '件名',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _subjectController,
                    decoration: InputDecoration(
                      hintText: '件名を入力してください',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '件名を入力してください';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 24),

                  // メッセージ
                  const Text(
                    'お問い合わせ内容',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'お問い合わせ内容を詳しく入力してください',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.all(16),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 8,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'お問い合わせ内容を入力してください';
                      }
                      if (value.length < 10) {
                        return '10文字以上で入力してください';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 32),

                  // 送信ボタン
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              '送信',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final form = ContactForm(
        type: _selectedType,
        email: _emailController.text,
        subject: _subjectController.text,
        message: _messageController.text,
      );

      final repository = ref.read(helpRepositoryProvider);
      final success = await repository.sendContact(form);

      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('お問い合わせを送信しました'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('送信に失敗しました: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}