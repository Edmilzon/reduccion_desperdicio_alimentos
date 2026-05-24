import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:reduccion_desperdicio_alimentos/core/services/alerts_repository.dart';
import 'package:reduccion_desperdicio_alimentos/core/services/notification_service.dart';
import 'package:reduccion_desperdicio_alimentos/features/home/data/models/product_model.dart';
import 'package:reduccion_desperdicio_alimentos/features/home/data/repositories/product_repository.dart';
import 'package:reduccion_desperdicio_alimentos/features/orders/data/models/order_model.dart';
import 'package:reduccion_desperdicio_alimentos/features/orders/data/repositories/order_repository.dart';

class PickupReminderService extends ChangeNotifier {
  Timer? _timer;
  final OrderRepository _orderRepo = OrderRepository();
  final ProductRepository _productRepo = ProductRepository();
  final AlertsRepository _alertsRepo = AlertsRepository();

  Map<int, CommerceModel> _commerceCache = {};
  final Set<String> _sentAlerts = {};

  void start() {
    _timer = Timer.periodic(const Duration(seconds: 60), (_) => _check());
    _check();
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _check() async {
    try {
      final orders = await _orderRepo.getMyOrders();
      final active = orders
          .where((o) => o.deliveryStatus == 'pending' && o.pickupEnd != null)
          .toList();

      if (active.isEmpty) return;

      await _refreshCommerceCache();

      Position? pos;
      try {
        pos = await Geolocator.getCurrentPosition(
          locationSettings:
              const LocationSettings(accuracy: LocationAccuracy.low),
        );
      } catch (_) {}

      for (final order in active) {
        await _checkReminder(order);
        if (pos != null) await _checkGeofence(order, pos);
      }
    } catch (_) {}
  }

  Future<void> _refreshCommerceCache() async {
    final commerces = await _productRepo.getCommerces();
    for (final c in commerces) {
      _commerceCache[c.id] = c;
    }
  }

  Future<void> _checkReminder(OrderModel order) async {
    final diff = order.pickupEnd!.difference(DateTime.now());
    final key = '${order.id}:reminder';

    if (diff.inMinutes <= 15 && diff.inMinutes >= 0 && !_sentAlerts.contains(key)) {
      _sentAlerts.add(key);

      await NotificationService.show(
        id: order.id,
        title: '¡Tu pedido te espera!',
        body:
            'Tu pedido "${order.productTitle ?? ''}" te espera en ${order.commerceName ?? 'el restaurante'}. Recógelo antes de las ${_formatTime(order.pickupEnd!)}.',
        payload: 'order:${order.id}',
      );

      _alertsRepo.addAlert(
        type: 'recordatorio_recogida',
        productId: order.productId ?? 0,
        title: '⏰ Recordatorio de recogida',
        message:
            'Tu pedido te espera en ${order.commerceName ?? 'el restaurante'} — vence a las ${_formatTime(order.pickupEnd!)}',
      );
    }
  }

  Future<void> _checkGeofence(OrderModel order, Position pos) async {
    if (order.commerceId == null) return;
    final commerce = _commerceCache[order.commerceId];
    if (commerce?.latitude == null || commerce?.longitude == null) return;

    final lat = double.tryParse(commerce!.latitude!);
    final lng = double.tryParse(commerce.longitude!);
    if (lat == null || lng == null) return;

    final distance =
        Geolocator.distanceBetween(pos.latitude, pos.longitude, lat, lng);
    final key = '${order.id}:geofence';

    if (distance < 200 && !_sentAlerts.contains(key)) {
      _sentAlerts.add(key);

      await NotificationService.showGeofenceCode(
        id: order.id + 1000,
        title:
            '📌 Estás cerca de ${order.commerceName ?? 'tu restaurante'}',
        body: 'Código de recogida: ${order.reservationCode}',
        payload: 'order:${order.id}',
      );

      _alertsRepo.addAlert(
        type: 'geocerca',
        productId: order.productId ?? 0,
        title: '📍 Estás cerca del local',
        message:
            'Código de recogida: ${order.reservationCode}. Preséntalo al recoger.',
      );
    }
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
