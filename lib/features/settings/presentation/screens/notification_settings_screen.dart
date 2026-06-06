import 'package:flutter/material.dart';
import 'package:reduccion_desperdicio_alimentos/core/theme/app_colors.dart';
import 'package:reduccion_desperdicio_alimentos/core/services/notification_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  Map<String, bool> _states = {};
  bool _isLoading = true;

  static const _channelInfo = {
    'merchant_new_order': 'Nuevos pedidos recibidos',
    'merchant_expiring': 'Productos activos por vencer',
    'pickup_reminder': 'Recordatorio para recoger tu pedido',
    'geofence_code': 'Alerta al estar cerca del local',
    'favorites_expiring': 'Tus favoritos están por terminar',
    'order_reminder': 'Estado de tus pedidos',
  };

  static const _channelIcons = {
    'merchant_new_order': Icons.shopping_bag,
    'merchant_expiring': Icons.timer,
    'pickup_reminder': Icons.notifications_active,
    'geofence_code': Icons.near_me,
    'favorites_expiring': Icons.favorite,
    'order_reminder': Icons.receipt_long,
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final states = await NotificationService.getAllChannelStates();
    if (mounted) {
      setState(() {
        _states = states;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Notificaciones',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Administra qué notificaciones quieres recibir',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                ..._buildChannelTiles(),
              ],
            ),
    );
  }

  List<Widget> _buildChannelTiles() {
    final labels = NotificationService.allChannelIds;
    return labels.map((id) {
      final enabled = _states[id] ?? true;
      final label = _channelInfo[id] ?? id;
      final icon = _channelIcons[id] ?? Icons.notifications;

      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: SwitchListTile(
          value: enabled,
          onChanged: (v) async {
            await NotificationService.setChannelEnabled(id, v);
            if (mounted) {
              setState(() => _states[id] = v);
            }
          },
          secondary: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          title: Text(
            _channelLabels[id] ?? id,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              fontSize: 14,
            ),
          ),
          subtitle: Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          activeTrackColor: AppColors.primary.withValues(alpha: 0.4),
          activeThumbColor: AppColors.primary,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }).toList();
  }

  static const Map<String, String> _channelLabels = {
    'merchant_new_order': 'Nuevos pedidos',
    'merchant_expiring': 'Productos por vencer',
    'pickup_reminder': 'Recordatorio de recogida',
    'geofence_code': 'Cercanía al local',
    'favorites_expiring': 'Favoritos por vencer',
    'order_reminder': 'Estado del pedido',
  };
}
