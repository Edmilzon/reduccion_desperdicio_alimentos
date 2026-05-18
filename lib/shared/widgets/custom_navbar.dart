import 'package:flutter/material.dart';
import 'package:reduccion_desperdicio_alimentos/core/theme/app_colors.dart';

class CustomNavbar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomNavbar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      backgroundColor: AppColors.background,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textSecondary,
      selectedFontSize: 12,
      unselectedFontSize: 12,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.restaurant_menu),
          label: 'Menú',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.storefront),
          label: 'Tienda',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.shopping_cart),
          label: 'Carrito',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.map),
          label: 'Mapa',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Perfil',
        ),
      ],
    );
  }
}