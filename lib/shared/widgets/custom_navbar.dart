import 'package:flutter/material.dart';

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
	  type: BottomNavigationBarType.fixed, // Para que se vea bien en más de 3 items
	  backgroundColor: Colors.white,
	  selectedItemColor: Colors.deepOrange, // Color de comida (apetitoso)
	  unselectedItemColor: Colors.grey,
	  selectedFontSize: 12,
	  unselectedFontSize: 12,
	  items: const [
		BottomNavigationBarItem(
		  icon: Icon(Icons.restaurant_menu), // Home
		  label: 'Menú',
		),
		BottomNavigationBarItem(
		  icon: Icon(Icons.search), // Búsqueda
		  label: 'Buscar',
		),
		BottomNavigationBarItem(
		  icon: Icon(Icons.shopping_cart), // Carrito
		  label: 'Carrito',
		),
		BottomNavigationBarItem(
		  icon: Icon(Icons.person), // Perfil
		  label: 'Mi Perfil',
		),
	  ],
	);
  }
}