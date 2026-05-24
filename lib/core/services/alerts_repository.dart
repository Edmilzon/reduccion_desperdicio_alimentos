import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AlertModel {
  final String id;
  final String type;
  final int productId;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool read;

  AlertModel({
    required this.id,
    required this.type,
    required this.productId,
    required this.title,
    required this.message,
    required this.timestamp,
    this.read = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'productId': productId,
        'title': title,
        'message': message,
        'timestamp': timestamp.toIso8601String(),
        'read': read,
      };

  factory AlertModel.fromJson(Map<String, dynamic> json) => AlertModel(
        id: json['id'] ?? '',
        type: json['type'] ?? '',
        productId: json['productId'] ?? 0,
        title: json['title'] ?? '',
        message: json['message'] ?? '',
        timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
        read: json['read'] ?? false,
      );

  AlertModel copyWith({bool? read}) => AlertModel(
        id: id,
        type: type,
        productId: productId,
        title: title,
        message: message,
        timestamp: timestamp,
        read: read ?? this.read,
      );
}

class AlertsRepository {
  static const String _key = 'alerts';

  static final _AlertsNotifier _notifier = _AlertsNotifier();
  static _AlertsNotifier get notifier => _notifier;

  Future<List<AlertModel>> getAlerts() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_key);
    if (data == null) return [];
    final list = jsonDecode(data) as List<dynamic>;
    return list
        .map((e) => AlertModel.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  Future<int> getUnreadCount() async {
    final alerts = await getAlerts();
    return alerts.where((a) => !a.read).length;
  }

  Future<void> addAlert({
    required String type,
    required int productId,
    required String title,
    required String message,
  }) async {
    final alerts = await getAlerts();
    final alert = AlertModel(
      id: 'alert_${DateTime.now().millisecondsSinceEpoch}',
      type: type,
      productId: productId,
      title: title,
      message: message,
      timestamp: DateTime.now(),
    );
    alerts.insert(0, alert);
    await _save(alerts);
    _notifier.refresh();
  }

  Future<void> markAsRead(String alertId) async {
    final alerts = await getAlerts();
    final index = alerts.indexWhere((a) => a.id == alertId);
    if (index >= 0) {
      alerts[index] = alerts[index].copyWith(read: true);
      await _save(alerts);
      _notifier.refresh();
    }
  }

  Future<void> markAllAsRead() async {
    final alerts = await getAlerts();
    for (int i = 0; i < alerts.length; i++) {
      alerts[i] = alerts[i].copyWith(read: true);
    }
    await _save(alerts);
    _notifier.refresh();
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    _notifier.refresh();
  }

  Future<void> _save(List<AlertModel> alerts) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(alerts.map((a) => a.toJson()).toList()));
  }
}

class _AlertsNotifier extends ChangeNotifier {
  void refresh() => notifyListeners();
}
