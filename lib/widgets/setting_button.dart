import 'package:flutter/material.dart';
import 'package:takizawa_hackathon_vol8/screens/setting.dart';

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
      onPressed: onPressed ?? () => _navigateToSettings(context),
    );
  }

  /// 設定画面に遷移する
  void _navigateToSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingScreen()),
    );
  }
}