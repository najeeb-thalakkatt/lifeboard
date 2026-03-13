import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:lifeboard/models/task_model.dart';

/// Indexes tasks for iOS Spotlight search.
///
/// Uses a MethodChannel to communicate with native CoreSpotlight APIs.
/// Falls back gracefully on platforms that don't support it.
class SpotlightService {
  static const _channel = MethodChannel('com.codehive.lifeboard/spotlight');

  /// Index a list of tasks for Spotlight search.
  static Future<void> indexTasks(List<TaskModel> tasks) async {
    if (kIsWeb || !Platform.isIOS) return;

    try {
      final items = tasks
          .where((t) => t.archivedAt == null)
          .map((t) => {
                'uniqueIdentifier': t.id,
                'title': t.title,
                'contentDescription': t.description ?? '',
                'domainIdentifier': 'com.codehive.lifeboard.tasks',
              })
          .toList();

      await _channel.invokeMethod('indexItems', {'items': items});
    } on MissingPluginException {
      // Native plugin not available — expected on non-iOS
    } catch (_) {
      // Indexing is best-effort.
    }
  }

  /// Remove a task from Spotlight index.
  static Future<void> deindexTask(String taskId) async {
    if (kIsWeb || !Platform.isIOS) return;

    try {
      await _channel.invokeMethod('deindexItem', {'identifier': taskId});
    } on MissingPluginException {
      // Native plugin not available
    } catch (_) {}
  }

  /// Remove all indexed items.
  static Future<void> deindexAll() async {
    if (kIsWeb || !Platform.isIOS) return;

    try {
      await _channel.invokeMethod('deindexAll');
    } on MissingPluginException {
      // Native plugin not available
    } catch (_) {}
  }
}
