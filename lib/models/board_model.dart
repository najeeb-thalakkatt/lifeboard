import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'board_model.freezed.dart';
part 'board_model.g.dart';

/// Firestore board document model.
@freezed
abstract class BoardModel with _$BoardModel {
  const factory BoardModel({
    required String id,
    required String name,
    @Default('') String theme,
    @Default(['todo', 'in_progress', 'done']) List<String> columns,
    required String createdBy,
    required DateTime createdAt,
  }) = _BoardModel;

  factory BoardModel.fromJson(Map<String, dynamic> json) =>
      _$BoardModelFromJson(json);

  /// Create from a Firestore document snapshot.
  factory BoardModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return BoardModel(
      id: doc.id,
      name: data['name'] as String? ?? '',
      theme: data['theme'] as String? ?? '',
      columns: List<String>.from(
          data['columns'] as List? ?? ['todo', 'in_progress', 'done']),
      createdBy: data['createdBy'] as String? ?? '',
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert to a Firestore-compatible map.
  static Map<String, dynamic> toFirestore(BoardModel model) {
    return {
      'name': model.name,
      'theme': model.theme,
      'columns': model.columns,
      'createdBy': model.createdBy,
      'createdAt': Timestamp.fromDate(model.createdAt),
    };
  }
}
