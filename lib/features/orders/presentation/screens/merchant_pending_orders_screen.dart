import 'dart:async';
import 'package:flutter/material.dart';
import 'package:reduccion_desperdicio_alimentos/core/theme/app_colors.dart';
import 'package:reduccion_desperdicio_alimentos/core/services/notification_service.dart';
import 'package:reduccion_desperdicio_alimentos/features/orders/data/models/order_model.dart';
import 'package:reduccion_desperdicio_alimentos/features/orders/data/repositories/order_repository.dart';
import 'package:reduccion_desperdicio_alimentos/features/orders/presentation/widgets/payment_status_badge.dart';

class MerchantPendingOrdersScreen extends StatefulWidget {
  const MerchantPendingOrdersScreen({super.key});

  @override
  State<MerchantPendingOrdersScreen> createState() =>
      _MerchantPendingOrdersScreenState();
}

class _MerchantPendingOrdersScreenState
    extends State<MerchantPendingOrdersScreen> {
  final OrderRepository _repository = OrderRepository();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  bool _isUpdating = false;
  String? _error;
  List<OrderModel> _orders = [];
  int _selectedTab = 0;
  String _searchQuery = '';
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    _loadOrders();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      _loadOrders();
      _autoExpireOrders();
    });
  }

  void _reloadAndExpire() {
    _loadOrders();
    _autoExpireOrders();
  }

  Future<void> _loadOrders() async {
    try {
      final orders = await _repository.getMerchantOrders();

      if (!mounted) return;

      final previousOrders = _orders;
      setState(() {
        _orders = orders;
        _isLoading = false;
        _error = null;
      });

      _notifyNewOrders(orders, previousOrders);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _notifyNewOrders(List<OrderModel> current, List<OrderModel> previous) {
    if (previous.isEmpty) return;

    final newOrders = current.where((o) =>
        !previous.any((p) => p.id == o.id) &&
        o.deliveryStatus == 'pending');

    if (newOrders.isEmpty) return;

    final count = newOrders.length;
    NotificationService.showWithChannel(
      id: DateTime.now().millisecondsSinceEpoch % 100000,
      title: 'Nuevo${count > 1 ? 's' : ''} pedido${count > 1 ? 's' : ''}',
      body: count == 1
          ? '${newOrders.first.buyerName ?? "Un cliente"} ha realizado un pedido'
          : '$count nuevos pedidos recibidos',
      channelId: 'merchant_new_order',
    );
  }

  Future<void> _autoExpireOrders() async {
    final now = DateTime.now();
    final pending = _orders.where((o) =>
        o.deliveryStatus == 'pending' &&
        o.pickupEnd != null &&
        o.pickupEnd!.isBefore(now));

    if (pending.isEmpty) return;

    bool changed = false;
    for (final order in pending) {
      try {
        await _repository.markAsNotPickedUp(order.id);
        changed = true;
      } catch (_) {}
    }

    if (changed && mounted) {
      await _loadOrders();
    }
  }

  List<OrderModel> get _filteredOrders {
    List<OrderModel> result;

    if (_selectedTab == 0) {
      result = _orders
          .where((order) =>
              order.paymentStatus == 'pending' &&
              order.deliveryStatus == 'pending')
          .toList();
      result.sort((a, b) {
        final aTime = a.pickupStart ?? DateTime(2100);
        final bTime = b.pickupStart ?? DateTime(2100);
        return aTime.compareTo(bTime);
      });
    } else if (_selectedTab == 1) {
      result = _orders
          .where((order) =>
              order.paymentStatus == 'paid' ||
              order.deliveryStatus == 'delivered')
          .toList();
      result.sort((a, b) {
        final aTime = a.pickupStart ?? DateTime(2000);
        final bTime = b.pickupStart ?? DateTime(2000);
        return bTime.compareTo(aTime);
      });
    } else {
      result = _orders
          .where((order) => order.deliveryStatus == 'not_picked_up')
          .toList();
      result.sort((a, b) {
        final aTime = a.pickupStart ?? DateTime(2000);
        final bTime = b.pickupStart ?? DateTime(2000);
        return bTime.compareTo(aTime);
      });
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase().trim();
      result = result
          .where((o) =>
              o.buyerName?.toLowerCase().contains(query) == true ||
              o.buyerEmail?.toLowerCase().contains(query) == true ||
              o.reservationCode.toLowerCase().contains(query))
          .toList();
    }

    return result;
  }

  Future<void> _markAsPaidAndDelivered(OrderModel order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar entrega'),
        content: Text(
          '¿Deseas marcar la reserva ${_shortCode(order.reservationCode)} como pagada y entregada?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isUpdating = true);

    try {
      await _repository.markPaidAndDelivered(order.id);
      await _loadOrders();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pedido marcado como pagado y entregado'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  Future<void> _deliverOrder(OrderModel order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar entrega'),
        content: Text(
          '¿Deseas marcar la reserva ${_shortCode(order.reservationCode)} como entregada?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isUpdating = true);

    try {
      await _repository.deliverOrder(order.id);
      await _loadOrders();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pedido marcado como entregado'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  String _shortCode(String code) {
    if (code.isEmpty) return 'SIN-CODIGO';
    if (code.length <= 8) return code.toUpperCase();
    return code.substring(0, 8).toUpperCase();
  }

  String _formatPickup(DateTime? start, DateTime? end) {
    if (start == null || end == null) {
      return 'Horario no disponible';
    }

    final s = start.toLocal();
    final e = end.toLocal();

    final day = s.day.toString().padLeft(2, '0');
    final month = s.month.toString().padLeft(2, '0');
    final startHour = s.hour.toString().padLeft(2, '0');
    final startMinute = s.minute.toString().padLeft(2, '0');
    final endHour = e.hour.toString().padLeft(2, '0');
    final endMinute = e.minute.toString().padLeft(2, '0');

    return '$day/$month $startHour:$startMinute - $endHour:$endMinute';
  }

  @override
  Widget build(BuildContext context) {
    final orders = _filteredOrders;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        centerTitle: true,
        title: const Text(
          'Pedidos pendientes',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _reloadAndExpire,
            icon: const Icon(
              Icons.refresh,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              if (_selectedTab == 0) _buildSearchBar(),
              _buildTabs(),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      )
                    : _error != null
                        ? _buildError()
                        : orders.isEmpty
                            ? _buildEmpty()
                            : RefreshIndicator(
                                onRefresh: () async {
                                  await _loadOrders();
                                  await _autoExpireOrders();
                                },
                                child: ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: orders.length,
                                  itemBuilder: (context, index) {
                                    final order = orders[index];

                                    return _MerchantOrderCard(
                                      order: order,
                                      code: _shortCode(order.reservationCode),
                                      pickupText: _formatPickup(
                                        order.pickupStart,
                                        order.pickupEnd,
                                      ),
                                      onMarkPaidDelivered:
                                          order.canBeMarkedAsPaidAndDelivered
                                              ? () => _markAsPaidAndDelivered(
                                                    order,
                                                  )
                                              : null,
                                      onDeliver: order.canBeDelivered
                                          ? () => _deliverOrder(order)
                                          : null,
                                    );
                                  },
                                ),
                              ),
              ),
            ],
          ),
          if (_isUpdating)
            Container(
              color: Colors.black.withValues(alpha: 0.25),
              child: const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: 'Buscar por nombre o código...',
          prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.grey[200],
          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: Row(
        children: [
          _tabButton('Pendientes', 0),
          const SizedBox(width: 8),
          _tabButton('Entregados', 1),
          const SizedBox(width: 8),
          _tabButton('No recogidos', 2),
        ],
      ),
    );
  }

  Widget _tabButton(String label, int index) {
    final selected = _selectedTab == index;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.cardBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? Colors.white : AppColors.textSecondary,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 52,
            ),
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: _reloadAndExpire,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    String message = 'No hay pedidos pendientes';

    if (_selectedTab == 1) {
      message = 'No hay pedidos entregados';
    } else if (_selectedTab == 2) {
      message = 'No hay pedidos no recogidos';
    }

    return Center(
      child: Text(
        message,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _MerchantOrderCard extends StatelessWidget {
  final OrderModel order;
  final String code;
  final String pickupText;
  final VoidCallback? onMarkPaidDelivered;
  final VoidCallback? onDeliver;

  const _MerchantOrderCard({
    required this.order,
    required this.code,
    required this.pickupText,
    required this.onMarkPaidDelivered,
    required this.onDeliver,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
              Expanded(
                child: Text(
                  '#$code',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              PaymentStatusBadge(
                status: order.isNotPickedUp ? order.deliveryStatus : order.paymentStatus,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.person_outline,
                size: 18,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  order.buyerName ??
                      order.buyerEmail ??
                      'Cliente no disponible',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: order.productImageUrl != null &&
                        order.productImageUrl!.isNotEmpty
                    ? Image.network(
                        order.productImageUrl!,
                        width: 62,
                        height: 62,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _placeholder(),
                      )
                    : _placeholder(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.productTitle ?? 'Producto',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${order.quantity} unidad(es)',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Recogida: $pickupText',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '\$${order.totalPrice.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (onMarkPaidDelivered != null || onDeliver != null) ...[
            const SizedBox(height: 14),
            if (onMarkPaidDelivered != null)
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: onMarkPaidDelivered,
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Marcar pagado y entregado'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            if (onDeliver != null) ...[
              if (onMarkPaidDelivered != null) const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: onDeliver,
                  icon: const Icon(Icons.local_shipping_outlined),
                  label: const Text('Marcar entregado'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 62,
      height: 62,
      color: Colors.grey[200],
      child: const Icon(
        Icons.fastfood,
        color: Colors.grey,
      ),
    );
  }
}
