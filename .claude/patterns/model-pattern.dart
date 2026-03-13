// Pattern: Freezed model with Firestore conversion
// Source: lib/models/task_model.dart
// Usage: All data models follow this pattern

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'example_model.freezed.dart';
part 'example_model.g.dart';

@freezed
abstract class ExampleModel with _$ExampleModel {
  const factory ExampleModel({
    required String id,
    required String title,
    String? description,
    @Default(false) bool isActive,
    @Default([]) List<String> tags,
    DateTime? dueDate,
    required String createdBy,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _ExampleModel;

  factory ExampleModel.fromJson(Map<String, dynamic> json) =>
      _$ExampleModelFromJson(json);

  /// Create from Firestore document — handles Timestamp → DateTime.
  factory ExampleModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return ExampleModel(
      id: doc.id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String?,
      isActive: data['isActive'] as bool? ?? false,
      tags: List<String>.from(data['tags'] as List? ?? []),
      dueDate: (data['dueDate'] as Timestamp?)?.toDate(),
      createdBy: data['createdBy'] as String? ?? '',
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt:
          (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

// Key points:
// 1. Always use @Default for optional fields with defaults
// 2. Firestore Timestamps must be cast: (data['field'] as Timestamp?)?.toDate()
// 3. Lists need: List<T>.from(data['field'] as List? ?? [])
// 4. Nested freezed objects: map with .fromJson(Map<String, dynamic>.from(s as Map))
// 5. Never edit .freezed.dart or .g.dart — run build_runner to regenerate
