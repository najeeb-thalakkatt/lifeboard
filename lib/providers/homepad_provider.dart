import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lifeboard/models/homepad_item_model.dart';
import 'package:lifeboard/providers/space_provider.dart';

// ── Catalog Provider (static JSON asset) ──────────────────────────

/// Loads the 365-item prebuilt catalog from the app bundle.
/// This is loaded once and cached by Riverpod.
final homePadCatalogProvider = FutureProvider<List<HomePadItem>>((ref) async {
  final jsonStr = await rootBundle.loadString('assets/data/homepad_catalog.json');
  final List<dynamic> jsonList = json.decode(jsonStr) as List<dynamic>;
  return jsonList
      .map((e) => HomePadItem.fromCatalog(e as Map<String, dynamic>))
      .toList();
});

// ── Firestore Stream (modified items only) ────────────────────────

/// Streams HomePad items from Firestore for a specific space.
/// Only items that have been modified (to_buy, purchased, custom) are stored.
final homePadFirestoreItemsProvider =
    StreamProvider.family<List<HomePadItem>, String>((ref, spaceId) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getHomePadItems(spaceId);
});

// ── Merged Items Provider ────────────────────────────────────────

/// Merges the static catalog with Firestore modifications.
/// Firestore items override catalog items by matching on id.
final homePadMergedItemsProvider =
    Provider.family<AsyncValue<List<HomePadItem>>, String>((ref, spaceId) {
  final catalogAsync = ref.watch(homePadCatalogProvider);
  final firestoreAsync = ref.watch(homePadFirestoreItemsProvider(spaceId));

  return catalogAsync.when(
    loading: () => const AsyncLoading(),
    error: (e, st) => AsyncError(e, st),
    data: (catalog) {
      return firestoreAsync.when(
        loading: () => AsyncData(catalog),
        error: (e, st) => AsyncError(e, st),
        data: (firestoreItems) {
          // Build a map of Firestore items by ID for quick lookup
          final firestoreMap = {
            for (final item in firestoreItems) item.id: item,
          };

          // Merge: catalog items get overridden by Firestore state
          final merged = catalog.map((catalogItem) {
            final firestoreItem = firestoreMap[catalogItem.id];
            if (firestoreItem != null) {
              return firestoreItem;
            }
            return catalogItem;
          }).toList();

          // Add custom items (not in catalog)
          for (final item in firestoreItems) {
            if (item.isCustom) {
              merged.add(item);
            }
          }

          return AsyncData(merged);
        },
      );
    },
  );
});

// ── Derived Providers ────────────────────────────────────────────

/// Items currently marked as "to_buy".
final toBuyItemsProvider =
    Provider.family<List<HomePadItem>, String>((ref, spaceId) {
  final mergedAsync = ref.watch(homePadMergedItemsProvider(spaceId));
  return mergedAsync.valueOrNull
          ?.where((i) => i.status == 'to_buy')
          .toList() ??
      [];
});

/// Items recently purchased.
final purchasedItemsProvider =
    Provider.family<List<HomePadItem>, String>((ref, spaceId) {
  final mergedAsync = ref.watch(homePadMergedItemsProvider(spaceId));
  final items = mergedAsync.valueOrNull
          ?.where((i) => i.status == 'purchased')
          .toList() ??
      [];
  // Sort by purchasedAt descending
  items.sort((a, b) {
    final aTime = a.purchasedAt ?? DateTime(2000);
    final bTime = b.purchasedAt ?? DateTime(2000);
    return bTime.compareTo(aTime);
  });
  return items;
});

/// All catalog items (available state) for browsing.
final catalogBrowseItemsProvider =
    Provider.family<List<HomePadItem>, String>((ref, spaceId) {
  final mergedAsync = ref.watch(homePadMergedItemsProvider(spaceId));
  return mergedAsync.valueOrNull ?? [];
});

// ── UI State Providers ───────────────────────────────────────────

/// Search query for filtering items.
final homePadSearchProvider = StateProvider<String>((ref) => '');

/// Selected category filter (null = show all).
final homePadCategoryFilterProvider = StateProvider<String?>((ref) => null);

// ── Category Definitions ─────────────────────────────────────────

/// Top-level categories with their emoji icons.
const homePadCategories = <String, String>{
  'Groceries': '🥦',
  'Cleaning': '🧹',
  'Stationery': '📝',
  'Home Essentials': '🏠',
  'Personal Care': '🧴',
  'Pet Supplies': '🐾',
  'Baby & Kids': '👶',
};

// ── Action Notifier ──────────────────────────────────────────────

/// Handles HomePad mutations (mark to_buy, purchased, mark all done, etc.)
class HomePadActionNotifier extends StateNotifier<AsyncValue<void>> {
  HomePadActionNotifier(this._ref) : super(const AsyncData(null));

  final Ref _ref;

  String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  /// Marks a catalog item as "to_buy" — creates a Firestore doc.
  Future<void> markToBuy({
    required String spaceId,
    required HomePadItem item,
  }) async {
    final userId = _userId;
    if (userId == null) return;

    final firestoreService = _ref.read(firestoreServiceProvider);
    final now = DateTime.now();
    final updatedItem = item.copyWith(
      status: 'to_buy',
      addedBy: userId,
      addedAt: now,
      purchasedBy: null,
      purchasedAt: null,
    );
    await firestoreService.addHomePadItem(
      spaceId: spaceId,
      item: updatedItem,
    );
  }

  /// Marks an item as purchased.
  Future<void> markPurchased({
    required String spaceId,
    required String itemId,
  }) async {
    final userId = _userId;
    if (userId == null) return;

    final firestoreService = _ref.read(firestoreServiceProvider);
    await firestoreService.updateHomePadItemStatus(
      spaceId: spaceId,
      itemId: itemId,
      status: 'purchased',
      userId: userId,
    );
  }

  /// Marks an item back to available (removes from to_buy/purchased).
  Future<void> markAvailable({
    required String spaceId,
    required String itemId,
    required bool isCustom,
  }) async {
    final userId = _userId;
    if (userId == null) return;

    final firestoreService = _ref.read(firestoreServiceProvider);
    if (isCustom) {
      await firestoreService.updateHomePadItemStatus(
        spaceId: spaceId,
        itemId: itemId,
        status: 'available',
        userId: userId,
      );
    } else {
      // For prebuilt items, delete Firestore doc to return to catalog state
      await firestoreService.deleteHomePadItem(
        spaceId: spaceId,
        itemId: itemId,
      );
    }
  }

  /// Re-adds a purchased item back to "to_buy".
  Future<void> reAddToBuy({
    required String spaceId,
    required String itemId,
  }) async {
    final userId = _userId;
    if (userId == null) return;

    final firestoreService = _ref.read(firestoreServiceProvider);
    await firestoreService.updateHomePadItemStatus(
      spaceId: spaceId,
      itemId: itemId,
      status: 'to_buy',
      userId: userId,
    );
  }

  /// Marks all "to_buy" items as purchased.
  Future<int> markAllDone({required String spaceId}) async {
    final userId = _userId;
    if (userId == null) return 0;

    final firestoreService = _ref.read(firestoreServiceProvider);
    return firestoreService.batchMarkAllDone(
      spaceId: spaceId,
      userId: userId,
    );
  }

  /// Adds a custom item to the shopping list.
  Future<void> addCustomItem({
    required String spaceId,
    required String name,
    required String emoji,
    required String category,
    required bool addToList,
  }) async {
    final userId = _userId;
    if (userId == null) return;

    final firestoreService = _ref.read(firestoreServiceProvider);
    final now = DateTime.now();
    final item = HomePadItem(
      id: '',
      name: name,
      emoji: emoji,
      category: category.isEmpty ? 'Groceries' : category,
      isCustom: true,
      status: addToList ? 'to_buy' : 'available',
      addedBy: addToList ? userId : null,
      addedAt: addToList ? now : null,
      createdAt: now,
    );
    await firestoreService.addHomePadItem(spaceId: spaceId, item: item);
  }

  /// Clears all purchased items.
  Future<int> clearPurchased({required String spaceId}) async {
    final firestoreService = _ref.read(firestoreServiceProvider);
    return firestoreService.clearPurchasedHomePadItems(spaceId: spaceId);
  }
}

final homePadActionProvider =
    StateNotifierProvider<HomePadActionNotifier, AsyncValue<void>>((ref) {
  return HomePadActionNotifier(ref);
});
