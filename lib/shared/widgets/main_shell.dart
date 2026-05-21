import 'package:flutter/material.dart';
import 'package:reduccion_desperdicio_alimentos/core/theme/app_colors.dart';
import 'package:reduccion_desperdicio_alimentos/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:reduccion_desperdicio_alimentos/features/dashboard/presentation/screens/my_offers_screen.dart';
import 'package:reduccion_desperdicio_alimentos/features/dashboard/presentation/screens/create_product_screen.dart';
import 'package:reduccion_desperdicio_alimentos/features/home/presentation/screens/profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  VoidCallback? _refreshCallback;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _currentIndex == 0
          ? MyOffersScreen(
              onRefreshRegistered: (callback) {
                _refreshCallback = callback;
              },
            )
          : _currentIndex == 1
              ? CreateProductScreen(
                  onSuccess: _onProductPublished,
                )
              : _currentIndex == 2
                  ? const DashboardScreen()
                  : const ProfileScreen(isMerchant: true),
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
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            activeIcon: Icon(Icons.inventory_2),
            label: 'Gestionar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            activeIcon: Icon(Icons.add_circle),
            label: 'Añadir',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart),
            label: 'Estadística',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}