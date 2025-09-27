import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:takizawa_hackathon_vol8/widgets/navigationbar.dart';

/// ガチャ画面
class GachaScreen extends ConsumerWidget {
  const GachaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'ガチャ',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: const Center(
        child: Text('ガチャ画面の内容がここに表示されます'),
      ),
      // 共通のナビゲーションバーを使用
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: NavIndex.menu.index,
        onTap: (index) {
          _handleBottomNavigationTap(context, index);
        },
      ),
    );
  }

  /// ボトムナビゲーションのタップを処理
  void _handleBottomNavigationTap(BuildContext context, int index) {
    // このメソッドは不要になる予定（MainNavigationScreenで処理するため）
    // 現状では他の画面との一貫性のために残しておく
  }
}
