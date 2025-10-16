import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationManager {
  static final NotificationManager _instance = NotificationManager._internal();
  factory NotificationManager() => _instance;
  NotificationManager._internal() {
    _loadFromPrefs();
  }

  ValueNotifier<List<Map<String, String>>> notifications = ValueNotifier([]);

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> saved = prefs.getStringList('notifications') ?? [];
    notifications.value = saved.map((e) {
      final parts = e.split('|');
      final dt = DateTime.parse(parts[1]).toLocal();
      final timeString =
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} น.';
      return {'title': parts[0], 'time': timeString};
    }).toList().reversed.toList();
  }

  Future<void> addNotification(String title) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> saved = prefs.getStringList('notifications') ?? [];
    saved.add('$title|${DateTime.now().toIso8601String()}');
    await prefs.setStringList('notifications', saved);
    notifications.value = saved.map((e) {
      final parts = e.split('|');
      final dt = DateTime.parse(parts[1]).toLocal();
      final timeString =
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} น.';
      return {'title': parts[0], 'time': timeString};
    }).toList().reversed.toList();
  }
}
