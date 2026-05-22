import 'package:flutter/material.dart';
import 'package:reduccion_desperdicio_alimentos/core/theme/app_colors.dart';
import 'package:reduccion_desperdicio_alimentos/core/services/cart_repository.dart';
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

  final _screens = [
    const MenuScreen(),
    const ShopScreen(),
    RealCartScreen(key: const ValueKey('cart')),
    const NearbyRestaurantsScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _updateCartCount();
    CartRepository.notifier.addListener(_onCartChanged);
  }

  @override
  void dispose() {
    CartRepository.notifier.removeListener(_onCartChanged);
    super.dispose();
  }

  void _onCartChanged() {
    _updateCartCount();
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
        children: _screens,
      ),
      bottomNavigationBar: CustomNavbar(
        currentIndex: _currentIndex,
        onTap: _onTabChanged,
        cartCount: _cartCount,
      ),
    );
  }
}
