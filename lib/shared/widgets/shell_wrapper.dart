import 'package:flutter/material.dart';
import 'package:reduccion_desperdicio_alimentos/core/theme/app_colors.dart';
import 'package:reduccion_desperdicio_alimentos/shared/widgets/custom_navbar.dart';

class ShellWrapper extends StatelessWidget {
  final Widget child;
  final String title;

  const ShellWrapper({
    super.key,
    required this.child,
    this.title = 'Eco Bocado',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
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
        currentIndex: 0,
        onTap: (index) {
          Navigator.popUntil(context, (route) => route.isFirst);
        },
      ),
    );
  }
}
