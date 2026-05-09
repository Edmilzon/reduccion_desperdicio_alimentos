import 'package:flutter/material.dart';
import 'package:reduccion_desperdicio_alimentos/core/theme/app_colors.dart';
import 'package:reduccion_desperdicio_alimentos/shared/widgets/custom_navbar.dart';

class PersistentShell extends StatelessWidget {
  final Widget child;
  final int currentIndex;
  final Function(int) onNavTap;
  final List<Widget> screens;
  final String title;

  const PersistentShell({
    super.key,
    required this.child,
    required this.currentIndex,
    required this.onNavTap,
    required this.screens,
    this.title = 'Eco Bocado',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          title,
          style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
      ),
      body: child,
      bottomNavigationBar: CustomNavbar(
        currentIndex: currentIndex,
        onTap: onNavTap,
      ),
    );
  }
}
