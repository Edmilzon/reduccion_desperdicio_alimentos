import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    await _createChannel(
      'pickup_reminder',
      'Recordatorio de recogida',
      'Alertas cuando se acerca la hora límite de recogida',
    );
    await _createChannel(
      'geofence_code',
      'Cercanía al local',
      'Notificaciones cuando estás cerca del restaurante',
    );
    await _createChannel(
      'merchant_new_order',
      'Nuevos pedidos',
      'Notificaciones cuando llega un nuevo pedido',
    );
    await _createChannel(
      'merchant_expiring',
      'Productos por vencer',
      'Notificaciones cuando un producto activo está por vencer',
    );
    await _createChannel(
      'favorites_expiring',
      'Favoritos por vencer',
      'Notificaciones cuando un favorito está por expirar',
    );
    await _createChannel(
      'order_reminder',
      'Recordatorio de pedido',
      'Notificaciones de estado del pedido',
    );

    _initialized = true;
  }

  static Future<void> _createChannel(String id, String name, String desc) async {
    final channel = AndroidNotificationChannel(id, name,
        description: desc, importance: Importance.high);
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  static void _onNotificationTap(NotificationResponse response) {
    // Navigation handler — reserved for future use
  }

  static Future<void> showWithChannel({
    required int id,
    required String title,
    required String body,
    required String channelId,
    String? payload,
  }) async {
    final channelLabel = _channelLabels[channelId] ?? channelId;
    final channelDesc = 'Notificaciones del canal $channelId';

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelLabel,
      channelDescription: channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _plugin.show(id, title, body, details, payload: payload);
  }

  static const Map<String, String> _channelLabels = {
    'pickup_reminder': 'Recordatorio de recogida',
    'geofence_code': 'Cercanía al local',
    'merchant_new_order': 'Nuevos pedidos',
    'merchant_expiring': 'Productos por vencer',
    'favorites_expiring': 'Favoritos por vencer',
    'order_reminder': 'Recordatorio de pedido',
  };

  static Future<void> show({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'pickup_reminder',
      'Recordatorio de recogida',
      channelDescription: 'Alertas cuando se acerca la hora límite de recogida',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _plugin.show(id, title, body, details, payload: payload);
  }

  static Future<void> showGeofenceCode({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'geofence_code',
      'Cercanía al local',
      channelDescription:
          'Notificaciones cuando estás cerca del restaurante',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _plugin.show(id, title, body, details, payload: payload);
  }

}
