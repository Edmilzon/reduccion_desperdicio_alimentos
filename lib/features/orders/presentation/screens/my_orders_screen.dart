import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:reduccion_desperdicio_alimentos/core/theme/app_colors.dart';
import 'package:reduccion_desperdicio_alimentos/features/home/data/models/product_model.dart';
import 'package:reduccion_desperdicio_alimentos/features/home/data/repositories/product_repository.dart';
import 'package:reduccion_desperdicio_alimentos/features/orders/data/models/order_model.dart';
import 'package:reduccion_desperdicio_alimentos/features/orders/data/repositories/order_repository.dart';
import 'package:reduccion_desperdicio_alimentos/features/orders/presentation/widgets/payment_dialog.dart';
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

  Future<void> _payOrder(OrderModel order) async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => PaymentDialog(order: order),
    );
    if (result == null || !mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );

    try {
      final updated = await _repository.payOrder(
        orderId: order.id,
        paymentProvider: result['provider'] ?? 'stripe',
        transactionId: result['transactionId'],
      );
      if (mounted) {
        Navigator.pop(context);
        _showPaymentSuccess(updated);
      }
    } on OrderException catch (e) {
      if (mounted) {
        Navigator.pop(context);
        if (e.message.contains('ya fue pagado')) {
          _showPaymentSuccess(OrderModel(
            id: order.id,
            reservationCode: order.reservationCode,
            quantity: order.quantity,
            totalPrice: order.totalPrice,
            paymentMethod: order.paymentMethod,
            paymentStatus: 'paid',
            deliveryStatus: order.deliveryStatus,
            status: order.status,
            productTitle: order.productTitle,
            commerceName: order.commerceName,
            paidAt: DateTime.now(),
          ));
        } else {
          _showPaymentError(e.message);
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showPaymentError('Pago no realizado, verifica el estado del pedido');
      }
    }
  }

  void _showPaymentSuccess(OrderModel order) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 26),
            SizedBox(width: 10),
            Expanded(child: Text('Pago Confirmado', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow('Producto', order.productTitle ?? ''),
            const SizedBox(height: 4),
            _detailRow('Total', '\$${order.totalPrice.toStringAsFixed(2)}'),
            const SizedBox(height: 4),
            _detailRow('Código', order.reservationCode),
            if (order.paidAt != null) ...[
              const SizedBox(height: 4),
              _detailRow('Pagado el', _formatDate(order.paidAt)),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _loadOrders();
            },
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  void _showPaymentError(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 26),
            SizedBox(width: 10),
            Expanded(child: Text('Pago Fallido', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Si el pago ya se realizó, puedes verificar el estado actualizando la lista de pedidos.',
                style: TextStyle(fontSize: 12, color: AppColors.darkBrown),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _loadOrders();
            },
            child: const Text('Verificar estado'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      children: [
        Text('$label: ', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        Flexible(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
      ],
    );
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year;
    final hour = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$min';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
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

  Widget _buildList() {
    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _orders.length,
        itemBuilder: (_, i) => _OrderCard(
          order: _orders[i],
          commerce: _commerceMap[_orders[i].commerceId],
          onPay: !_orders[i].isCash && _orders[i].isPendingPayment
              ? () => _payOrder(_orders[i])
              : null,
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
  final VoidCallback? onPay;
  final VoidCallback? onCancel;

  const _OrderCard({required this.order, this.commerce, this.onPay, this.onCancel});

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

  void _showQrCode(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: const Text('Código de recogida', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            QrImageView(
              data: order.reservationCode,
              version: QrVersions.auto,
              size: 220,
              backgroundColor: Colors.white,
              eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square),
              dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square),
            ),
            const SizedBox(height: 16),
            Text(order.reservationCode, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary, letterSpacing: 2)),
            const SizedBox(height: 8),
            Text('Preséntalo al recoger tu pedido en ${order.commerceName ?? 'el restaurante'}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cerrar')),
        ],
      ),
    );
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
            onTap: () => _showQrCode(context),
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
          if (order.isCash && !order.isPaid) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
              decoration: BoxDecoration(
                color: AppColors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('Pagarás en efectivo al recoger', style: TextStyle(fontSize: 12, color: AppColors.darkBrown)),
            ),
          ],
          if (onPay != null) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: onPay,
                child: const Text('Pagar ahora', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
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
