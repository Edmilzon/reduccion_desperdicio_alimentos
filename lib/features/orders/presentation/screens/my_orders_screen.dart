import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:reduccion_desperdicio_alimentos/core/theme/app_colors.dart';
import 'package:reduccion_desperdicio_alimentos/features/home/data/models/product_model.dart';
import 'package:reduccion_desperdicio_alimentos/features/home/data/repositories/product_repository.dart';
import 'package:reduccion_desperdicio_alimentos/features/orders/data/models/order_model.dart';
import 'package:reduccion_desperdicio_alimentos/features/orders/data/repositories/order_repository.dart';
import 'package:reduccion_desperdicio_alimentos/shared/widgets/countdown_timer.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  final _repository = OrderRepository();
  final _productRepo = ProductRepository();
  List<OrderModel> _orders = [];
  Map<int, CommerceModel> _commerceMap = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    try {
      final orders = await _repository.getMyOrders();
      final commerces = await _productRepo.getCommerces();
      final map = <int, CommerceModel>{};
      for (final c in commerces) map[c.id] = c;
      if (mounted) {
        setState(() {
          _orders = orders;
          _commerceMap = map;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  void _showQrDialog(OrderModel order) {
    final qrData = order.reservationCode.isNotEmpty
        ? order.reservationCode
        : 'ECO-${order.id}';
    if (qrData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Código de reserva no disponible'), backgroundColor: Colors.red),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: const Text('Código de recogida', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: 180,
                  backgroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(qrData, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary, letterSpacing: 2)),
            const SizedBox(height: 8),
            Text('Preséntalo al recoger tu pedido en ${order.commerceName ?? 'el restaurante'}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar'),
          ),
          if (order.paymentMethod == 'online' && !order.isPaid)
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () async {
                Navigator.pop(ctx);
                if (!mounted) return;
                setState(() {});
                try {
                  final updated = await _repository.payOrder(orderId: order.id);
                  final i = _orders.indexWhere((o) => o.id == updated.id);
                  if (i >= 0 && mounted) {
                    setState(() => _orders[i] = updated);
                  }
                  if (mounted) _showSuccessDialog(context);
                } catch (_) {
                  if (!mounted) return;
                  try {
                    final freshOrders = await _repository.getMyOrders();
                    final paid = freshOrders.where((o) => o.id == order.id && o.isPaid).firstOrNull;
                    if (mounted) {
                      if (paid != null) {
                        final i = _orders.indexWhere((o) => o.id == paid.id);
                        if (i >= 0) setState(() => _orders[i] = paid);
                        _showSuccessDialog(context);
                      } else {
                        setState(() => _orders = freshOrders);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Error al procesar el pago'), backgroundColor: Colors.red),
                        );
                      }
                    }
                  } catch (_) {
                    if (mounted) _loadOrders();
                  }
                }
              },
              child: const Text('Confirmar pago', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
    );
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 26),
            SizedBox(width: 10),
            Expanded(child: Text('Pago registrado', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Solo falta recoger tu pedido.', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            SizedBox(height: 8),
            Text('Presenta tu código QR al llegar al restaurante.', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelOrder(OrderModel order) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar Pedido', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('¿Estás seguro de cancelar la reserva de "${order.productTitle ?? ''}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      await _repository.cancelOrder(order.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pedido cancelado'), backgroundColor: Colors.green),
        );
        _loadOrders();
      }
    } on OrderException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Mis Pedidos', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 22)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: _loadOrders, child: const Text('Reintentar')),
                    ],
                  ),
                )
              : _orders.isEmpty
                  ? _buildEmpty()
                  : _buildList(),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text('No tienes pedidos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Text('Realiza tu primera reserva', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildList() {
    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _orders.length,
        itemBuilder: (_, i) => _OrderCard(
          order: _orders[i],
          commerce: _commerceMap[_orders[i].commerceId],
          onShowQr: () => _showQrDialog(_orders[i]),
          onCancel: _orders[i].status != 'cancelled' &&
                  _orders[i].status != 'confirmed' &&
                  _orders[i].deliveryStatus == 'pending'
              ? () => _cancelOrder(_orders[i])
              : null,
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;
  final CommerceModel? commerce;
  final VoidCallback? onShowQr;
  final VoidCallback? onCancel;

  const _OrderCard({
    required this.order,
    this.commerce,
    this.onShowQr,
    this.onCancel,
  });

  void _openMaps(BuildContext context) {
    if (commerce?.latitude == null || commerce?.longitude == null) return;
    final url = 'https://www.google.com/maps/search/?api=1&query=${commerce!.latitude},${commerce!.longitude}';
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  void _openWaze(BuildContext context) {
    if (commerce?.latitude == null || commerce?.longitude == null) return;
    final url = 'https://waze.com/ul?ll=${commerce!.latitude},${commerce!.longitude}&navigate=yes';
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final isPending = order.deliveryStatus == 'pending';
    final hasCoords = commerce?.latitude != null && commerce?.longitude != null;
    final isExpired = order.pickupEnd != null && order.pickupEnd!.isBefore(DateTime.now());

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(_statusLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _statusColor)),
              ),
              const Spacer(),
              Text('\$${order.totalPrice.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 10),
          Text(order.productTitle ?? '', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.store_outlined, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(order.commerceName ?? '', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: order.reservationCode.isEmpty ? null : onShowQr,
            child: Row(
              children: [
                const Icon(Icons.qr_code, size: 14, color: AppColors.primary),
                const SizedBox(width: 4),
                Flexible(child: Text(order.reservationCode, style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600))),
                const SizedBox(width: 4),
                const Icon(Icons.zoom_in, size: 12, color: AppColors.primary),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(_formatCreatedAt(order.createdAt), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              if (order.isPaid && order.paidAt != null) ...[
                const SizedBox(width: 12),
                const Icon(Icons.check_circle, size: 14, color: Colors.green),
                const SizedBox(width: 4),
                const Text('Pagado', style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w600)),
              ],
            ],
          ),
          if (isPending && order.pickupEnd != null && !isExpired) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: order.pickupEnd!.difference(DateTime.now()).inMinutes <= 5
                    ? Colors.red.withValues(alpha: 0.08)
                    : order.pickupEnd!.difference(DateTime.now()).inMinutes <= 30
                        ? AppColors.alertBg
                        : AppColors.amber.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: order.pickupEnd!.difference(DateTime.now()).inMinutes <= 5
                      ? Colors.red.withValues(alpha: 0.3)
                      : order.pickupEnd!.difference(DateTime.now()).inMinutes <= 30
                          ? AppColors.primary.withValues(alpha: 0.3)
                          : AppColors.amber.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.timer,
                    size: 16,
                    color: order.pickupEnd!.difference(DateTime.now()).inMinutes <= 5
                        ? Colors.red
                        : AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tiempo para recoger',
                          style: TextStyle(
                            fontSize: 10,
                            color: order.pickupEnd!.difference(DateTime.now()).inMinutes <= 5 ? Colors.red : AppColors.textSecondary,
                          ),
                        ),
                        CountdownTimer(target: order.pickupEnd!, compact: true),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (isExpired && order.pickupEnd != null) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber, size: 16, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Tiempo de recogida vencido', style: TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
          if (isPending && hasCoords) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 36,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                      ),
                      icon: const Icon(Icons.map, size: 16),
                      label: const Text('Maps', style: TextStyle(fontSize: 11)),
                      onPressed: () => _openMaps(context),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 36,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue,
                        side: const BorderSide(color: Colors.blue),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                      ),
                      icon: const Icon(Icons.navigation, size: 16),
                      label: const Text('Waze', style: TextStyle(fontSize: 11)),
                      onPressed: () => _openWaze(context),
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (order.paymentMethod == 'online' && !order.isPaid) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.qr_code, color: Colors.white, size: 20),
                label: const Text('Pagar con QR', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                onPressed: onShowQr,
              ),
            ),
          ],
          if (order.paymentMethod == 'cash' && !order.isPaid) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.money, size: 18, color: AppColors.darkBrown),
                  SizedBox(width: 8),
                  Text(
                    'Pagarás en efectivo al recoger.',
                    style: TextStyle(fontSize: 13, color: AppColors.darkBrown, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
          if (onCancel != null) ...[
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onPressed: onCancel,
                child: const Text('Cancelar pedido', style: TextStyle(fontSize: 13)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatCreatedAt(DateTime? dt) {
    if (dt == null) return '';
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year;
    final hour = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$min';
  }

  Color get _statusColor {
    switch (order.status) {
      case 'confirmed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return AppColors.primary;
    }
  }

  String get _statusLabel {
    switch (order.status) {
      case 'confirmed':
        return 'Confirmado';
      case 'cancelled':
        return 'Cancelado';
      default:
        return order.status;
    }
  }
}
