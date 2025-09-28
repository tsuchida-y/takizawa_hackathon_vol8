import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:takizawa_hackathon_vol8/screens/gacha.dart';

/// チケットインベントリのアイテム
class TicketInventoryItem {
  final GachaItem gachaItem;
  final int count;
  final DateTime firstObtained;
  final DateTime lastObtained;

  const TicketInventoryItem({
    required this.gachaItem,
    required this.count,
    required this.firstObtained,
    required this.lastObtained,
  });

  TicketInventoryItem copyWith({
    GachaItem? gachaItem,
    int? count,
    DateTime? firstObtained,
    DateTime? lastObtained,
  }) {
    return TicketInventoryItem(
      gachaItem: gachaItem ?? this.gachaItem,
      count: count ?? this.count,
      firstObtained: firstObtained ?? this.firstObtained,
      lastObtained: lastObtained ?? this.lastObtained,
    );
  }
}

/// チケットインベントリの状態管理
class TicketInventoryNotifier extends StateNotifier<List<TicketInventoryItem>> {
  TicketInventoryNotifier() : super([]);

  /// チケットを追加
  void addTicket(GachaItem item) {
    final now = DateTime.now();
    final existingIndex = state.indexWhere((inventoryItem) => inventoryItem.gachaItem.id == item.id);
    
    if (existingIndex != -1) {
      // 既存のアイテムの場合、カウントを増やす
      final existingItem = state[existingIndex];
      final updatedItem = existingItem.copyWith(
        count: existingItem.count + 1,
        lastObtained: now,
      );
      
      state = [
        ...state.sublist(0, existingIndex),
        updatedItem,
        ...state.sublist(existingIndex + 1),
      ];
    } else {
      // 新しいアイテムの場合、リストに追加
      final newItem = TicketInventoryItem(
        gachaItem: item,
        count: 1,
        firstObtained: now,
        lastObtained: now,
      );
      
      state = [...state, newItem];
    }
  }

  /// 複数のチケットを一度に追加
  void addTickets(List<GachaItem> items) {
    for (final item in items) {
      addTicket(item);
    }
  }

  /// チケットを使用（カウントを1減らす）
  void useTicket(String itemId) {
    final existingIndex = state.indexWhere((inventoryItem) => inventoryItem.gachaItem.id == itemId);
    
    if (existingIndex != -1) {
      final existingItem = state[existingIndex];
      
      if (existingItem.count > 1) {
        // カウントを1減らす
        final updatedItem = existingItem.copyWith(
          count: existingItem.count - 1,
        );
        
        state = [
          ...state.sublist(0, existingIndex),
          updatedItem,
          ...state.sublist(existingIndex + 1),
        ];
      } else {
        // カウントが1の場合、アイテムを削除
        state = [
          ...state.sublist(0, existingIndex),
          ...state.sublist(existingIndex + 1),
        ];
      }
    }
  }

  /// インベントリをクリア
  void clearInventory() {
    state = [];
  }

  /// レアリティでソート
  void sortByRarity() {
    state = [...state]..sort((a, b) {
      final rarityOrder = {
        GachaRarity.ultraRare: 0,
        GachaRarity.superRare: 1,
        GachaRarity.rare: 2,
        GachaRarity.common: 3,
      };
      
      final aOrder = rarityOrder[a.gachaItem.rarity] ?? 999;
      final bOrder = rarityOrder[b.gachaItem.rarity] ?? 999;
      
      if (aOrder != bOrder) {
        return aOrder.compareTo(bOrder);
      }
      
      // 同じレアリティの場合は名前でソート
      return a.gachaItem.name.compareTo(b.gachaItem.name);
    });
  }

  /// 取得日時でソート（新しい順）
  void sortByDate() {
    state = [...state]..sort((a, b) => b.lastObtained.compareTo(a.lastObtained));
  }
}

/// チケットインベントリプロバイダー
final ticketInventoryProvider = StateNotifierProvider<TicketInventoryNotifier, List<TicketInventoryItem>>((ref) {
  return TicketInventoryNotifier();
});