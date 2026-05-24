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

    const pickupChannel = AndroidNotificationChannel(
      'pickup_reminder',
      'Recordatorio de recogida',
      description: 'Alertas cuando se acerca la hora límite de recogida',
      importance: Importance.high,
    );

    const geofenceChannel = AndroidNotificationChannel(
      'geofence_code',
      'Cercanía al local',
      description: 'Notificaciones cuando estás cerca del restaurante',
      importance: Importance.high,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(pickupChannel);
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(geofenceChannel);

    const merchantOrderChannel = AndroidNotificationChannel(
      'merchant_new_order',
      'Nuevos pedidos',
      description: 'Notificaciones cuando llega un nuevo pedido',
      importance: Importance.high,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(merchantOrderChannel);

    _initialized = true;
  }

  static void _onNotificationTap(NotificationResponse response) {}

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
