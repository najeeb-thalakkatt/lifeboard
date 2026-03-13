// Pattern: FirestoreService CRUD with error handling
// Source: lib/services/firestore_service.dart
// Usage: All Firestore operations go through this service

import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  // ── Collection references (private) ──────────────────────
  CollectionReference<Map<String, dynamic>> _itemsRef(String spaceId) =>
      _firestore.collection('spaces').doc(spaceId).collection('items');

  // ── Stream (real-time reads) ─────────────────────────────
  Stream<List<ItemModel>> getItems(String spaceId) {
    return _itemsRef(spaceId)
        .orderBy('order')
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => ItemModel.fromFirestore(doc))
            .toList());
  }

  // ── Create ───────────────────────────────────────────────
  Future<ItemModel> createItem({
    required String spaceId,
    required ItemModel item,
  }) async {
    final docRef = await _itemsRef(spaceId).add({
      'title': item.title,
      'status': item.status,
      'order': item.order,
      'createdBy': item.createdBy,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return item.copyWith(id: docRef.id);
  }

  // ── Update ───────────────────────────────────────────────
  Future<void> updateItem(String spaceId, String itemId,
      Map<String, dynamic> updates) async {
    updates['updatedAt'] = FieldValue.serverTimestamp();
    await _itemsRef(spaceId).doc(itemId).update(updates);
  }

  // ── Delete ───────────────────────────────────────────────
  Future<void> deleteItem(String spaceId, String itemId) async {
    await _itemsRef(spaceId).doc(itemId).delete();
  }
}

// Key points:
// 1. Injectable Firestore instance for testing (pass FakeFirebaseFirestore)
// 2. Collection refs are private methods, not public
// 3. Use FieldValue.serverTimestamp() for createdAt/updatedAt
// 4. Streams use .snapshots().map() for real-time
// 5. fromFirestore() handles Timestamp conversion (see model-pattern.dart)
// 6. All paths: spaces/{spaceId}/{collection}/{docId}
