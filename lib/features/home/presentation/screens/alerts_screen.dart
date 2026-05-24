import 'package:flutter/material.dart';
import 'package:reduccion_desperdicio_alimentos/core/theme/app_colors.dart';
import 'package:reduccion_desperdicio_alimentos/core/services/alerts_repository.dart';
import 'package:reduccion_desperdicio_alimentos/features/home/presentation/screens/product_detail_screen.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  final _alertsRepo = AlertsRepository();
  List<AlertModel> _alerts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAlerts();
    AlertsRepository.notifier.addListener(_onAlertsChanged);
  }

  @override
  void dispose() {
    AlertsRepository.notifier.removeListener(_onAlertsChanged);
    super.dispose();
  }

  void _onAlertsChanged() {
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    final alerts = await _alertsRepo.getAlerts();
    if (mounted) setState(() { _alerts = alerts; _isLoading = false; });
  }

  Future<void> _clearAll() async {
    await _alertsRepo.clearAll();
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
        actions: [
          if (_alerts.any((a) => !a.read))
            TextButton(
              onPressed: () async {
                await _alertsRepo.markAllAsRead();
              },
              child: const Text('Marcar leídas', style: TextStyle(color: AppColors.primary, fontSize: 12)),
            ),
          if (_alerts.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep, color: AppColors.primary, size: 20),
              onPressed: _clearAll,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _alerts.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  onRefresh: _loadAlerts,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _alerts.length,
                    itemBuilder: (_, i) => _AlertCard(
                      alert: _alerts[i],
                      onTap: () {
                        _alertsRepo.markAsRead(_alerts[i].id);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProductDetailScreen(productId: _alerts[i].productId),
                          ),
                        );
                      },
                    ),
                  ),
                ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            'Sin notificaciones',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'Aquí aparecerán las alertas de ofertas\npor expirar y precios reducidos.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final AlertModel alert;
  final VoidCallback onTap;

  const _AlertCard({required this.alert, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isUrgent = alert.type == 'ultima_oportunidad';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: alert.read ? AppColors.cardBg : (isUrgent ? AppColors.alertBg : Colors.blue.withValues(alpha: 0.05)),
          borderRadius: BorderRadius.circular(12),
          border: alert.read
              ? null
              : Border.all(
                  color: isUrgent ? AppColors.primary.withValues(alpha: 0.3) : Colors.blue.withValues(alpha: 0.2),
                ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isUrgent ? Colors.red.withValues(alpha: 0.1) : Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isUrgent ? Icons.timer : Icons.local_offer,
                size: 20,
                color: isUrgent ? Colors.red : Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alert.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: alert.read ? FontWeight.w500 : FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    alert.message,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatTimestamp(alert.timestamp),
                    style: const TextStyle(fontSize: 10, color: AppColors.textLight),
                  ),
                ],
              ),
            ),
            if (!alert.read)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Ahora';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours}h';
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
