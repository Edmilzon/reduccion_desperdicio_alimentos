import 'package:flutter/material.dart';
import 'package:reduccion_desperdicio_alimentos/core/theme/app_colors.dart';
import 'package:reduccion_desperdicio_alimentos/core/services/cart_repository.dart';
import 'package:reduccion_desperdicio_alimentos/core/services/notification_service.dart';
import 'package:reduccion_desperdicio_alimentos/core/services/pickup_reminder_service.dart';
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
  final PickupReminderService _pickupReminder = PickupReminderService();

  @override
  void initState() {
    super.initState();
    _updateCartCount();
    CartRepository.notifier.addListener(_onCartChanged);
    CartRepository.navigateToCartNotifier.addListener(_onNavigateToCart);
    NotificationService.init();
    _pickupReminder.start();
  }

  @override
  void dispose() {
    CartRepository.notifier.removeListener(_onCartChanged);
    CartRepository.navigateToCartNotifier.removeListener(_onNavigateToCart);
    _pickupReminder.stop();
    super.dispose();
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

  Future<void> _updateCartCount() async {
    final count = await CartRepository().getItemCount();
    if (mounted) {
      setState(() => _cartCount = count);
    }
  }

  void _onTabChanged(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const MenuScreen(),
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
    );
  }
}
