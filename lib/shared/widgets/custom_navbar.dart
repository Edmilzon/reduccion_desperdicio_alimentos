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
	  type: BottomNavigationBarType.fixed,
	  backgroundColor: Colors.white,
	  selectedItemColor: Colors.deepOrange,
	  unselectedItemColor: Colors.grey,
	  selectedFontSize: 12,
	  unselectedFontSize: 12,
	  items: const [
		BottomNavigationBarItem(
		  icon: Icon(Icons.restaurant_menu),
		  label: 'Menú',
		),
		BottomNavigationBarItem(
		  icon: Icon(Icons.search), 
		  label: 'Buscar',
		),
		BottomNavigationBarItem(
		  icon: Icon(Icons.shopping_cart),
		  label: 'Tienda',
		),
		BottomNavigationBarItem(
		  icon: Icon(Icons.person), 
		  label: 'Perfil',
		),
	  ],
	);
  }
}