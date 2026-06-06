import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:reduccion_desperdicio_alimentos/core/theme/app_colors.dart';
import 'package:reduccion_desperdicio_alimentos/core/services/alerts_repository.dart';
import 'package:reduccion_desperdicio_alimentos/core/services/notification_scheduler.dart';
import 'package:reduccion_desperdicio_alimentos/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:reduccion_desperdicio_alimentos/features/dashboard/presentation/screens/my_offers_screen.dart';
import 'package:reduccion_desperdicio_alimentos/features/dashboard/presentation/screens/create_product_screen.dart';
import 'package:reduccion_desperdicio_alimentos/features/home/presentation/screens/alerts_screen.dart';
import 'package:reduccion_desperdicio_alimentos/features/home/presentation/screens/profile_screen.dart';
import 'package:reduccion_desperdicio_alimentos/features/orders/data/repositories/order_repository.dart';
import 'package:reduccion_desperdicio_alimentos/features/orders/presentation/screens/merchant_pending_orders_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  int _pendingCount = 0;
  int _alertsUnread = 0;
  VoidCallback? _refreshCallback;
  Timer? _badgeTimer;

  @override
  void initState() {
    super.initState();
    NotificationScheduler.checkNow();
    _loadCounts();
    _badgeTimer = Timer.periodic(const Duration(seconds: 30), (_) => _loadCounts());
    AlertsRepository.notifier.addListener(_onAlertsChanged);
  }

  @override
  void dispose() {
    _badgeTimer?.cancel();
    AlertsRepository.notifier.removeListener(_onAlertsChanged);
    super.dispose();
  }

  void _onAlertsChanged() {
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    final repo = OrderRepository();
    try {
      final orders = await repo.getMerchantOrders();
      final now = DateTime.now();
      final pending = orders.where((o) {
        if (o.deliveryStatus == 'delivered' || o.deliveryStatus == 'not_picked_up') return false;
        if (o.paymentStatus == 'pending' && o.pickupEnd != null && o.pickupEnd!.isBefore(now)) return false;
        return true;
      }).length;
      if (mounted) setState(() => _pendingCount = pending);
    } catch (_) {}

    final alertsRepo = AlertsRepository();
    try {
      final count = await alertsRepo.getUnreadCount();
      if (mounted) setState(() => _alertsUnread = count);
    } catch (_) {}
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _onProductPublished() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Producto publicado')),
    );
    setState(() {
      _currentIndex = 0;
    });
    _refreshCallback?.call();
  }

  Future<bool> _onBack() async {
    if (_currentIndex > 0) {
      setState(() => _currentIndex = 0);
      return false;
    }
    final exit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Salir'),
        content: const Text('¿Deseas salir de Ecobocado?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Salir'),
          ),
        ],
      ),
    );
    return exit ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldExit = await _onBack();
        if (shouldExit && context.mounted) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Ecobocado',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: AppColors.textPrimary),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AlertsScreen()),
                ),
              ),
              if (_alertsUnread > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                    child: Text(
                      '$_alertsUnread',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: _currentIndex == 0
          ? MyOffersScreen(
              onRefreshRegistered: (callback) {
                _refreshCallback = callback;
              },
            )
          : _currentIndex == 1
              ? const MerchantPendingOrdersScreen()
              : _currentIndex == 2
                  ? const DashboardScreen()
                  : const ProfileScreen(isMerchant: true),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CreateProductScreen(
                      onSuccess: _onProductPublished,
                    ),
                  ),
                );
              },
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        backgroundColor: AppColors.background,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            activeIcon: Icon(Icons.inventory_2),
            label: 'Gestionar',
          ),
          BottomNavigationBarItem(
            icon: _pendingCount > 0
                ? Badge(
                    label: Text('$_pendingCount'),
                    backgroundColor: AppColors.primary,
                    child: const Icon(Icons.assignment_outlined),
                  )
                : const Icon(Icons.assignment_outlined),
            activeIcon: _pendingCount > 0
                ? Badge(
                    label: Text('$_pendingCount'),
                    backgroundColor: AppColors.primary,
                    child: const Icon(Icons.assignment),
                  )
                : const Icon(Icons.assignment),
            label: 'Pedidos',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart),
            label: 'Estadística',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    ),
    );
  }
}
