import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'homepad_item_model.freezed.dart';
part 'homepad_item_model.g.dart';

/// A HomePad shopping list item.
///
/// Items can be prebuilt (from the catalog JSON) or custom (user-created).
/// Only items that transition away from 'available' are stored in Firestore.
@freezed
abstract class HomePadItem with _$HomePadItem {
  const factory HomePadItem({
    required String id,
    required String name,
    @Default('🛒') String emoji,
    required String category,
    @Default('') String subcategory,
    @Default('available') String status, // 'available' | 'to_buy' | 'purchased'
    @Default('as_needed') String frequency, // 'weekly' | 'biweekly' | 'monthly' | 'as_needed'
    @Default(false) bool isCustom,
    @Default(false) bool isHidden,
    String? addedBy,
    DateTime? addedAt,
    String? purchasedBy,
    DateTime? purchasedAt,
    @Default(1) int quantity,
    String? note,
    @Default(0) int purchaseCount,
    @Default(0) int order,
    required DateTime createdAt,
  }) = _HomePadItem;

  factory HomePadItem.fromJson(Map<String, dynamic> json) =>
      _$HomePadItemFromJson(json);

  /// Creates a [HomePadItem] from a Firestore document snapshot.
  factory HomePadItem.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return HomePadItem(
      id: doc.id,
      name: data['name'] as String? ?? '',
      emoji: data['emoji'] as String? ?? '🛒',
      category: data['category'] as String? ?? '',
      subcategory: data['subcategory'] as String? ?? '',
      status: data['status'] as String? ?? 'available',
      frequency: data['frequency'] as String? ?? 'as_needed',
      isCustom: data['isCustom'] as bool? ?? false,
      isHidden: data['isHidden'] as bool? ?? false,
      addedBy: data['addedBy'] as String?,
      addedAt: (data['addedAt'] as Timestamp?)?.toDate(),
      purchasedBy: data['purchasedBy'] as String?,
      purchasedAt: (data['purchasedAt'] as Timestamp?)?.toDate(),
      quantity: data['quantity'] as int? ?? 1,
      note: data['note'] as String?,
      purchaseCount: data['purchaseCount'] as int? ?? 0,
      order: data['order'] as int? ?? 0,
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Converts a [HomePadItem] to a Firestore-compatible map.
  static Map<String, dynamic> toFirestore(HomePadItem item) {
    return {
      'name': item.name,
      'emoji': item.emoji,
      'category': item.category,
      'subcategory': item.subcategory,
      'status': item.status,
      'frequency': item.frequency,
      'isCustom': item.isCustom,
      'isHidden': item.isHidden,
      'addedBy': item.addedBy,
      'addedAt':
          item.addedAt != null ? Timestamp.fromDate(item.addedAt!) : null,
      'purchasedBy': item.purchasedBy,
      'purchasedAt': item.purchasedAt != null
          ? Timestamp.fromDate(item.purchasedAt!)
          : null,
      'quantity': item.quantity,
      'note': item.note,
      'purchaseCount': item.purchaseCount,
      'order': item.order,
      'createdAt': Timestamp.fromDate(item.createdAt),
    };
  }

  /// Creates a [HomePadItem] from a catalog JSON entry (static asset).
  factory HomePadItem.fromCatalog(Map<String, dynamic> json) {
    return HomePadItem(
      id: 'catalog_${json['order']}',
      name: json['name'] as String,
      emoji: json['emoji'] as String? ?? '🛒',
      category: json['category'] as String,
      subcategory: json['subcategory'] as String? ?? '',
      frequency: json['frequency'] as String? ?? 'as_needed',
      order: json['order'] as int? ?? 0,
      createdAt: DateTime.utc(2026, 1, 1),
    );
  }
}
