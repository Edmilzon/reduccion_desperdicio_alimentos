import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:reduccion_desperdicio_alimentos/core/theme/app_colors.dart';
import 'package:reduccion_desperdicio_alimentos/core/services/alerts_repository.dart';
import 'package:reduccion_desperdicio_alimentos/core/services/cart_repository.dart';
import 'package:reduccion_desperdicio_alimentos/core/services/notification_service.dart';
import 'package:reduccion_desperdicio_alimentos/core/services/pickup_reminder_service.dart';
import 'package:reduccion_desperdicio_alimentos/features/home/presentation/screens/alerts_screen.dart';
import 'package:reduccion_desperdicio_alimentos/features/home/presentation/screens/menu_screen.dart';
import 'package:reduccion_desperdicio_alimentos/features/home/presentation/screens/shop_screen.dart';
import 'package:reduccion_desperdicio_alimentos/features/home/presentation/screens/real_cart_screen.dart';
import 'package:reduccion_desperdicio_alimentos/features/home/presentation/screens/profile_screen.dart';
import 'package:reduccion_desperdicio_alimentos/features/home/presentation/screens/nearby_restaurants_screen.dart';
import 'package:reduccion_desperdicio_alimentos/shared/widgets/custom_navbar.dart';

class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  int _currentIndex = 0;
  int _cartCount = 0;
  int _menuRefreshKey = 0;
  int _alertsUnread = 0;
  Timer? _alertsTimer;
  final PickupReminderService _pickupReminder = PickupReminderService();

  @override
  void initState() {
    super.initState();
    _updateCartCount();
    CartRepository.notifier.addListener(_onCartChanged);
    CartRepository.navigateToCartNotifier.addListener(_onNavigateToCart);
    NotificationService.init();
    _pickupReminder.start();
    _loadAlertsUnread();
    _alertsTimer = Timer.periodic(const Duration(seconds: 30), (_) => _loadAlertsUnread());
    AlertsRepository.notifier.addListener(_onAlertsChanged);
  }

  @override
  void dispose() {
    CartRepository.notifier.removeListener(_onCartChanged);
    CartRepository.navigateToCartNotifier.removeListener(_onNavigateToCart);
    AlertsRepository.notifier.removeListener(_onAlertsChanged);
    _alertsTimer?.cancel();
    _pickupReminder.stop();
    super.dispose();
  }

  void _onAlertsChanged() {
    _loadAlertsUnread();
  }

  void _onCartChanged() {
    _updateCartCount();
  }

  void _onNavigateToCart() {
    if (CartRepository.navigateToCartNotifier.value) {
      CartRepository.navigateToCartNotifier.value = false;
      setState(() => _currentIndex = 2);
    }
  }

  Future<void> _loadAlertsUnread() async {
    final repo = AlertsRepository();
    try {
      final count = await repo.getUnreadCount();
      if (mounted) setState(() => _alertsUnread = count);
    } catch (_) {}
  }

  Future<void> _updateCartCount() async {
    final count = await CartRepository().getItemCount();
    if (mounted) {
      setState(() => _cartCount = count);
    }
  }

  void _onTabChanged(int index) {
    setState(() {
      _currentIndex = index;
      if (index == 0) _menuRefreshKey++;
    });
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
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          title: const Text(
            'Eco Bocado',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              fontSize: 22,
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
        body: IndexedStack(
          index: _currentIndex,
          children: [
            MenuScreen(key: ValueKey('menu_$_menuRefreshKey')),
            const ShopScreen(),
            const RealCartScreen(),
            NearbyRestaurantsScreen(
              key: const ValueKey('map-tab-nearby'),
              isTabActive: _currentIndex == 3,
            ),
            const ProfileScreen(),
          ],
        ),
        bottomNavigationBar: CustomNavbar(
          currentIndex: _currentIndex,
          onTap: _onTabChanged,
          cartCount: _cartCount,
        ),
      ),
    );
  }
}
