import 'package:flutter/material.dart';
import 'package:reduccion_desperdicio_alimentos/core/theme/app_colors.dart';
import 'package:reduccion_desperdicio_alimentos/core/services/cart_repository.dart';
import 'package:reduccion_desperdicio_alimentos/core/services/notification_service.dart';
import 'package:reduccion_desperdicio_alimentos/features/orders/data/repositories/order_repository.dart';
import 'package:reduccion_desperdicio_alimentos/features/orders/presentation/screens/my_orders_screen.dart';
import 'package:reduccion_desperdicio_alimentos/shared/widgets/quantity_button.dart';

class RealCartScreen extends StatefulWidget {
  const RealCartScreen({super.key});

  @override
  State<RealCartScreen> createState() => _RealCartScreenState();
}

class _RealCartScreenState extends State<RealCartScreen> {
  final CartRepository _cartRepo = CartRepository();
  final OrderRepository _orderRepo = OrderRepository();
  List<CartItem> _items = [];
  bool _isLoading = true;
  bool _isCheckingOut = false;
  double _total = 0;

  @override
  void initState() {
    super.initState();
    _loadCart();
    CartRepository.notifier.addListener(_onCartChanged);
  }

  @override
  void dispose() {
    CartRepository.notifier.removeListener(_onCartChanged);
    super.dispose();
  }

  void _onCartChanged() {
    _loadCart();
  }

  Future<void> _loadCart() async {
    setState(() => _isLoading = true);
    try {
      final items = await _cartRepo.getCartItems();
      final total = await _cartRepo.getTotalPrice();
      setState(() {
        _items = items;
        _total = total;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _items = [];
        _total = 0;
        _isLoading = false;
      });
    }
  }

  Future<void> _updateQuantity(int productId, int delta, int stock) async {
    final item = _items.firstWhere((i) => i.productId == productId);
    final newQty = item.quantity + delta;
    await _cartRepo.updateQuantity(productId, newQty, stock);
    _loadCart();
  }

  Future<void> _removeItem(int productId) async {
    await _cartRepo.removeItem(productId);
    _loadCart();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Carrito',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_items.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep, color: AppColors.primary),
              onPressed: () => _showClearCartDialog(),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _items.isEmpty
              ? _buildEmptyCart()
              : _buildCartList(),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            'Tu carrito está vacío',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Añade productos para comenzar',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildCartList() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _items.length,
            itemBuilder: (context, index) => _CartItemCard(
              item: _items[index],
              onIncrement: () => _updateQuantity(_items[index].productId, 1, _items[index].stock),
              onDecrement: () => _updateQuantity(_items[index].productId, -1, _items[index].stock),
              onRemove: () => _removeItem(_items[index].productId),
            ),
          ),
        ),
        _buildCheckoutSection(),
      ],
    );
  }

  Widget _buildCheckoutSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.background,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '\$${_total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isCheckingOut ? null : () => _showPaymentMethodDialog(),
                child: _isCheckingOut
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Reservar',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showClearCartDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Vaciar Carrito'),
        content: const Text('¿Estás seguro de que quieres eliminar todos los productos?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              await _cartRepo.clearCart();
              if (mounted) {
                Navigator.pop(context);
                _loadCart();
              }
            },
            child: const Text('Vaciar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showPaymentMethodDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Método de pago', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Elige cómo quieres pagar tu reserva:'),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.qr_code, color: Colors.white),
              label: const Text('Pagar con QR', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.pop(ctx);
                _processCheckout('online');
              },
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              icon: const Icon(Icons.money, color: AppColors.darkBrown),
              label: const Text('Efectivo', style: TextStyle(color: AppColors.darkBrown, fontSize: 15, fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.pop(ctx);
                _processCheckout('cash');
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _processCheckout(String paymentMethod) async {
    setState(() => _isCheckingOut = true);

    final List<_OrderResult> results = [];
    for (final item in _items) {
      if (!mounted) return;
      try {
        final order = await _orderRepo.createOrder(
          productId: item.productId,
          quantity: item.quantity,
          paymentMethod: paymentMethod,
        );
        results.add(_OrderResult(
          item: item,
          success: true,
          reservationCode: order.reservationCode,
          commerceName: (order.commerceName ?? '').isNotEmpty ? order.commerceName : item.commerceName,
          totalPrice: order.totalPrice > 0 ? order.totalPrice : item.price * item.quantity,
          pickupEnd: _formatPickup(item.pickupEnd),
        ));
      } on OrderNotAvailableException {
        results.add(_OrderResult(item: item, success: false, error: 'Oferta agotada'));
      } on OrderInsufficientStockException catch (e) {
        results.add(_OrderResult(item: item, success: false, error: e.message));
      } on OrderException catch (e) {
        results.add(_OrderResult(item: item, success: false, error: e.message));
      } catch (e) {
        results.add(_OrderResult(item: item, success: false, error: 'Error de conexión'));
      }
    }

    if (!mounted) return;
    setState(() => _isCheckingOut = false);

    final succeeded = results.where((r) => r.success).toList();
    final failed = results.where((r) => !r.success).toList();

    for (final r in succeeded) {
      await _cartRepo.removeItem(r.item.productId);
    }

    if (!mounted) return;
    _loadCart();
    if (succeeded.isNotEmpty) {
      NotificationService.showWithChannel(
        id: DateTime.now().millisecondsSinceEpoch % 100000,
        title: ' Pedido confirmado',
        body: '${succeeded.length} producto${succeeded.length > 1 ? 's' : ''} reservado${succeeded.length > 1 ? 's' : ''} correctamente',
        channelId: 'order_reminder',
      );
    }
    _showCheckoutResultDialog(succeeded, failed, paymentMethod);
  }

  void _showCheckoutResultDialog(List<_OrderResult> succeeded, List<_OrderResult> failed, String paymentMethod) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(
              failed.isEmpty ? Icons.check_circle : Icons.warning_amber_rounded,
              color: failed.isEmpty ? Colors.green : AppColors.primary,
              size: 26,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                failed.isEmpty ? 'Reserva Confirmada' : 'Reserva Parcial',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (succeeded.isNotEmpty) ...[
                ...succeeded.map((r) => _OrderSummaryCard(result: r)),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: paymentMethod == 'cash'
                        ? AppColors.amber.withValues(alpha: 0.1)
                        : AppColors.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        paymentMethod == 'cash' ? Icons.money : Icons.qr_code,
                        size: 18,
                        color: paymentMethod == 'cash' ? AppColors.darkBrown : AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          paymentMethod == 'cash'
                              ? 'Paga en efectivo al recoger.'
                              : 'Paga con QR desde Mis Pedidos.',
                          style: TextStyle(
                            fontSize: 12,
                            color: paymentMethod == 'cash' ? AppColors.darkBrown : AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (failed.isNotEmpty) ...[
                if (succeeded.isNotEmpty) const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                const Text('Reservas fallidas:',
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                const SizedBox(height: 8),
                ...failed.map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.cancel, size: 18, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r.item.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text(r.error ?? '', style: const TextStyle(fontSize: 12, color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              final nav = Navigator.of(context);
              Navigator.pop(ctx);
              nav.push(MaterialPageRoute(builder: (_) => const MyOrdersScreen()));
            },
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  String _formatPickup(DateTime? dt) {
    if (dt == null) return '—';
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final hour = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$day/$month ${hour}h$min';
  }
}

class _OrderResult {
  final CartItem item;
  final bool success;
  final String? reservationCode;
  final String? commerceName;
  final double? totalPrice;
  final String? pickupEnd;
  final String? error;

  _OrderResult({
    required this.item,
    required this.success,
    this.reservationCode,
    this.commerceName,
    this.totalPrice,
    this.pickupEnd,
    this.error,
  });
}

class _CartItemCard extends StatelessWidget {
  final CartItem item;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;

  const _CartItemCard({
    required this.item,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: item.imageUrl.isNotEmpty
                ? Image.network(
                    item.imageUrl,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildPlaceholder(),
                  )
                : _buildPlaceholder(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                if (item.commerceName != null)
                  Text(
                    item.commerceName!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  '\$${item.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Row(
                children: [
                  QuantityButton(
                    icon: Icons.remove,
                    onPressed: onDecrement,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      '${item.quantity}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  QuantityButton(
                    icon: Icons.add,
                    onPressed: onIncrement,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                onPressed: onRemove,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 80,
      height: 80,
      color: Colors.grey[200],
      child: const Icon(Icons.fastfood, color: Colors.grey),
    );
  }
}

class _OrderSummaryCard extends StatelessWidget {
  final _OrderResult result;

  const _OrderSummaryCard({required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, size: 18, color: Colors.green),
              const SizedBox(width: 6),
              Text(
                result.item.title,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _summaryRow(Icons.store_outlined, 'Restaurante', result.commerceName ?? result.item.commerceName ?? '—'),
          const SizedBox(height: 4),
          _summaryRow(Icons.shopping_bag_outlined, 'Producto', result.item.title),
          const SizedBox(height: 4),
          _summaryRow(Icons.numbers_outlined, 'Cantidad', '${result.item.quantity}'),
          const SizedBox(height: 4),
          _summaryRow(Icons.attach_money_outlined, 'Total', '\$${(result.totalPrice ?? result.item.price * result.item.quantity).toStringAsFixed(2)}'),
          const SizedBox(height: 4),
          _summaryRow(Icons.access_time_outlined, 'Recoger antes de', result.pickupEnd ?? '—'),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.qr_code, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Código de reserva',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                      Text(
                        result.reservationCode ?? '—',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

