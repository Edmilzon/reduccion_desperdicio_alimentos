import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:reduccion_desperdicio_alimentos/core/services/favorites_repository.dart';
import 'package:reduccion_desperdicio_alimentos/core/services/notification_service.dart';
import 'package:reduccion_desperdicio_alimentos/features/dashboard/data/repositories/dashboard_repository.dart';
import 'package:reduccion_desperdicio_alimentos/features/orders/data/models/order_model.dart';
import 'package:reduccion_desperdicio_alimentos/features/orders/data/repositories/order_repository.dart';

class NotificationScheduler {
  static Timer? _timer;
  static List<OrderModel> _previousMerchantOrders = [];
  static final Set<String> _sentNotifications = {};

  static void start() {
    _timer?.cancel();
    _check();
    _timer = Timer.periodic(const Duration(seconds: 60), (_) => _check());
  }

  static void stop() {
    _timer?.cancel();
    _timer = null;
  }

  static void checkNow() {
    _check(); // fire-and-forget, same pattern as start()
  }

  static Future<void> _check() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null || token.isEmpty) return;

      final role = prefs.getString('auth_user') != null
          ? _extractRole(prefs.getString('auth_user')!)
          : null;

      if (role?.toUpperCase() == 'MERCHANT') {
        await _checkMerchantNotifications();
      } else {
        await _checkClientNotifications();
      }
    } catch (_) {}
  }

  static String? _extractRole(String userJson) {
    try {
      final map = _parseJson(userJson);
      return map['role'] as String?;
    } catch (_) {
      return null;
    }
  }

  static Map<String, dynamic> _parseJson(String json) {
    // Using dart:convert is avoidable — we only need the role field
    final buffer = StringBuffer();
    bool inString = false;
    String key = '';
    for (int i = 0; i < json.length; i++) {
      final c = json[i];
      if (c == '"') { inString = !inString; continue; }
      if (inString) { buffer.write(c); continue; }
      if (c == ':') {
        key = buffer.toString().trim();
        buffer.clear();
        continue;
      }
      if (c == ',' || c == '}' || c == '{') {
        if (key == 'role') return {'role': buffer.toString().trim()};
        buffer.clear();
        key = '';
        continue;
      }
    }
    return {};
  }

  static Future<void> _checkClientNotifications() async {
    final favRepo = FavoritesRepository();
    try {
      final favorites = await favRepo.getFavoriteProducts();
      for (final fav in favorites) {
        if (fav.isExpiringSoon) {
          final key = 'fav:${fav.id}';
          if (!_sentNotifications.contains(key)) {
            _sentNotifications.add(key);
            NotificationService.showWithChannel(
              id: fav.id + 3000,
              title: ' Oferta favorita por terminar',
              body: '"${fav.title}" termina pronto en ${fav.commerceName ?? 'el restaurante'}',
              channelId: 'favorites_expiring',
              payload: 'product:${fav.id}',
            );
          }
        }
      }
    } catch (_) {}

    try {
      final orderRepo = OrderRepository();
      final orders = await orderRepo.getMyOrders();
      final now = DateTime.now();
      for (final order in orders) {
        if (order.deliveryStatus != 'pending' || order.pickupEnd == null) continue;
        final diff = order.pickupEnd!.difference(now);
        final key = 'late:${order.id}';
        if (diff.inMinutes <= 10 && diff.inMinutes >= 0 && !_sentNotifications.contains(key)) {
          _sentNotifications.add(key);
          NotificationService.showWithChannel(
            id: order.id + 4000,
            title: ' Recoge tu pedido',
            body: 'Tu pedido "${order.productTitle ?? ''}" te espera. Recógelo pronto en ${order.commerceName ?? 'el restaurante'}',
            channelId: 'order_reminder',
            payload: 'order:${order.id}',
          );
        }
      }
    } catch (_) {}
  }

  static Future<void> _checkMerchantNotifications() async {
    final orderRepo = OrderRepository();

    try {
      final orders = await orderRepo.getMerchantOrders();
      if (_previousMerchantOrders.isNotEmpty) {
        final newOrders = orders.where((o) =>
            !_previousMerchantOrders.any((p) => p.id == o.id) &&
            o.deliveryStatus == 'pending');
        final count = newOrders.length;
        if (count > 0) {
          final key = 'new_order_batch_${DateTime.now().millisecondsSinceEpoch ~/ 60000}';
          if (!_sentNotifications.contains(key)) {
            _sentNotifications.add(key);
            NotificationService.showWithChannel(
              id: DateTime.now().millisecondsSinceEpoch % 100000,
              title: 'Nuevo${count > 1 ? 's' : ''} pedido${count > 1 ? 's' : ''}',
              body: count == 1
                  ? '${newOrders.first.buyerName ?? "Un cliente"} ha realizado un pedido'
                  : '$count nuevos pedidos recibidos',
              channelId: 'merchant_new_order',
              payload: 'merchant_orders',
            );
          }
        }
      }
      _previousMerchantOrders = orders;
    } catch (_) {}

    try {
      final repo = DashboardRepository();
      final ofertas = await repo.getMisOfertas();
      final now = DateTime.now();
      for (final o in ofertas) {
        if (!o.isActive) continue;
        final diff = o.pickupEnd.difference(now);
        final expiringKey = 'expiring:${o.id}';
        if (diff.inMinutes <= 30 && diff.inMinutes >= 0 && !_sentNotifications.contains(expiringKey)) {
          _sentNotifications.add(expiringKey);
          NotificationService.showWithChannel(
            id: o.id + 5000,
            title: ' Producto por vencer',
            body: '"${o.title}" vence en ${diff.inMinutes} min — ${o.unidadesRestantes} unid. disponibles',
            channelId: 'merchant_expiring',
          );
        }
      }
    } catch (_) {}

    try {
      final orders = await orderRepo.getMerchantOrders();
      final now = DateTime.now();
      for (final order in orders) {
        if (order.deliveryStatus != 'pending' || order.pickupEnd == null) continue;
        if (order.pickupEnd!.isBefore(now)) {
          final expiredKey = 'expired_order:${order.id}';
          if (!_sentNotifications.contains(expiredKey)) {
            _sentNotifications.add(expiredKey);
            NotificationService.showWithChannel(
              id: order.id + 6000,
              title: ' Pedido no recogido',
              body: '${order.buyerName ?? "Un cliente"} no recogió "${order.productTitle ?? 'su pedido'}" a tiempo',
              channelId: 'merchant_new_order',
            );
          }
        }
      }
    } catch (_) {}
  }
}
