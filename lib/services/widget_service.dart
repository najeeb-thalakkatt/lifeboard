import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Service for updating iOS home screen widgets with task data.
///
/// Writes a comprehensive JSON payload to the shared App Group UserDefaults
/// so the native WidgetKit extension can read it. Supports 2 widgets:
/// Our Week and Home Pad.
class WidgetService {
  static const _channel =
      MethodChannel('com.codehive.lifeboard/widget');
  static const _appGroupId = 'group.com.codehive.lifeboard';
  static const _widgetDataKey = 'widget_data';

  // Cached payload sections — updated independently, merged on write.
  static Map<String, dynamic> _weeklyPayload = {};
  static Map<String, dynamic> _choresPayload = {};
  static Map<String, dynamic> _buyListPayload = {};
  static String _userName = '';
  static String _spaceName = '';

  /// Updates the weekly tasks section and pushes to widget.
  static Future<void> updateWeeklyData({
    required int total,
    required int completed,
    required int inProgress,
    required List<Map<String, dynamic>> tasks,
  }) async {
    _weeklyPayload = {
      'total': total,
      'completed': completed,
      'inProgress': inProgress,
      'tasks': tasks.take(8).toList(),
    };
    await _flush();
  }

  /// Updates the chores section and pushes to widget.
  static Future<void> updateChoresData({
    required int todayDue,
    required int overdue,
    required List<Map<String, dynamic>> items,
  }) async {
    _choresPayload = {
      'todayDue': todayDue,
      'overdue': overdue,
      'items': items.take(6).toList(),
    };
    await _flush();
  }

  /// Updates the buy list section and pushes to widget.
  static Future<void> updateBuyListData({
    required int totalItems,
    required List<Map<String, dynamic>> items,
  }) async {
    _buyListPayload = {
      'totalItems': totalItems,
      'items': items.take(8).toList(),
    };
    await _flush();
  }

  /// Updates user/space context shown in widgets.
  static Future<void> updateUserContext({
    required String userName,
    required String spaceName,
  }) async {
    _userName = userName;
    _spaceName = spaceName;
    await _flush();
  }

  /// Clears widget data (call on sign out).
  static Future<void> clearWidgetData() async {
    _weeklyPayload = {};
    _choresPayload = {};
    _buyListPayload = {};
    _userName = '';
    _spaceName = '';

    if (kIsWeb || !Platform.isIOS) return;

    try {
      await _channel.invokeMethod('updateWidgetData', {
        'appGroupId': _appGroupId,
        'key': _widgetDataKey,
        'data': jsonEncode({
          'weeklyTasks': {'total': 0, 'completed': 0, 'inProgress': 0, 'tasks': []},
          'chores': {'todayDue': 0, 'overdue': 0, 'items': []},
          'buyList': {'totalItems': 0, 'items': []},
          'userName': '',
          'spaceName': '',
          'lastUpdated': DateTime.now().toUtc().toIso8601String(),
        }),
      });
    } catch (_) {}
  }

  // ── Helpers ──────────────────────────────────────────────────────

  /// Builds a task entry for the weekly widget payload.
  static Map<String, dynamic> buildTaskEntry({
    required String title,
    required String status,
    String? emoji,
    DateTime? dueDate,
  }) {
    return {
      'title': title,
      'status': status,
      if (emoji != null && emoji.isNotEmpty) 'emoji': emoji,
      if (dueDate != null) 'dueDate': DateFormat('yyyy-MM-dd').format(dueDate),
    };
  }

  /// Builds a chore entry for the chores widget payload.
  static Map<String, dynamic> buildChoreEntry({
    required String title,
    required String emoji,
    String? assignee,
    required bool isOverdue,
  }) {
    return {
      'title': title,
      'emoji': emoji,
      if (assignee != null) 'assignee': assignee,
      'isOverdue': isOverdue,
    };
  }

  /// Builds a buy list item entry for the buy list widget payload.
  static Map<String, dynamic> buildBuyListEntry({
    required String title,
    required String category,
    String? emoji,
  }) {
    return {
      'title': title,
      'category': category,
      if (emoji != null) 'emoji': emoji,
    };
  }

  /// Flushes all cached payloads to the shared App Group UserDefaults.
  static Future<void> _flush() async {
    if (kIsWeb || !Platform.isIOS) return;

    final payload = {
      'weeklyTasks': _weeklyPayload.isNotEmpty
          ? _weeklyPayload
          : {'total': 0, 'completed': 0, 'inProgress': 0, 'tasks': []},
      'chores': _choresPayload.isNotEmpty
          ? _choresPayload
          : {'todayDue': 0, 'overdue': 0, 'items': []},
      'buyList': _buyListPayload.isNotEmpty
          ? _buyListPayload
          : {'totalItems': 0, 'items': []},
      'userName': _userName,
      'spaceName': _spaceName,
      'lastUpdated': DateTime.now().toUtc().toIso8601String(),
    };

    try {
      await _channel.invokeMethod('updateWidgetData', {
        'appGroupId': _appGroupId,
        'key': _widgetDataKey,
        'data': jsonEncode(payload),
      });
    } on MissingPluginException {
      // Widget channel not available (Android, tests, etc.)
    } catch (_) {
      // Widget update is best-effort.
    }
  }
}
