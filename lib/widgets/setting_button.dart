import 'package:flutter/material.dart';

/// 設定ボタンの共通ウィジェット
/// 各画面の右上に表示する設定ボタンを提供します
class SettingsButton extends StatelessWidget {
  /// 設定ボタンの色をカスタマイズするためのパラメータ（オプション）
  final Color? color;
  
  /// 設定ボタンのカスタムアクション（オプション）
  /// 指定がない場合は標準の設定ダイアログが表示されます
  final VoidCallback? onPressed;

  const SettingsButton({
    super.key, 
    this.color,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.settings, color: color),
      onPressed: onPressed ?? () => _showSettingsDialog(context),
    );
  }

  /// 標準の設定ダイアログを表示
  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('設定'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(leading: Icon(Icons.account_circle), title: Text('アカウント')),
            ListTile(leading: Icon(Icons.notifications), title: Text('通知')),
            ListTile(leading: Icon(Icons.help), title: Text('ヘルプ')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }
}