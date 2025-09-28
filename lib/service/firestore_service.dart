import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Firebase Firestoreとの通信を担当するサービスクラス
class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// コレクションからすべてのドキュメントを取得
  Future<List<Map<String, dynamic>>> getCollection(String collectionPath) async {
    try {
      final querySnapshot = await _firestore.collection(collectionPath).get();
      return querySnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
    } catch (e) {
      debugPrint('Firestore取得エラー: $e');
      rethrow;
    }
  }

  /// 特定のドキュメントを取得
  Future<Map<String, dynamic>?> getDocument(
      String collectionPath, String documentId) async {
    try {
      final documentSnapshot =
          await _firestore.collection(collectionPath).doc(documentId).get();

      if (documentSnapshot.exists) {
        return {'id': documentSnapshot.id, ...documentSnapshot.data()!};
      }
      return null;
    } catch (e) {
      debugPrint('Firestore取得エラー: $e');
      rethrow;
    }
  }

  /// ドキュメントを作成/更新
  Future<void> setDocument(
      String collectionPath, String documentId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(collectionPath).doc(documentId).set(
            data,
            SetOptions(merge: true),
          );
    } catch (e) {
      debugPrint('Firestore保存エラー: $e');
      rethrow;
    }
  }

  /// ドキュメントを更新
  Future<void> updateDocument(
      String collectionPath, String documentId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(collectionPath).doc(documentId).update(data);
    } catch (e) {
      debugPrint('Firestore更新エラー: $e');
      rethrow;
    }
  }

  /// ドキュメントを削除
  Future<void> deleteDocument(String collectionPath, String documentId) async {
    try {
      await _firestore.collection(collectionPath).doc(documentId).delete();
    } catch (e) {
      debugPrint('Firestore削除エラー: $e');
      rethrow;
    }
  }

  /// クエリ条件に基づいてドキュメントを取得
  Future<List<Map<String, dynamic>>> queryCollection(
    String collectionPath, {
    required String field,
    required dynamic isEqualTo,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection(collectionPath)
          .where(field, isEqualTo: isEqualTo)
          .get();

      return querySnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
    } catch (e) {
      debugPrint('Firestore検索エラー: $e');
      rethrow;
    }
  }
}

/// Firebase Serviceのプロバイダ
final firebaseServiceProvider = Provider<FirebaseService>((ref) {
  return FirebaseService();
});