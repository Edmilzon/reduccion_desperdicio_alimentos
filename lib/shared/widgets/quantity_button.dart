import 'package:flutter/material.dart';
import 'package:reduccion_desperdicio_alimentos/core/theme/app_colors.dart';

class QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final double size;

  const QuantityButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.size = 28,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null;
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isEnabled ? AppColors.primary.withValues(alpha: 0.1) : Colors.grey[200],
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: size * 0.6, color: isEnabled ? AppColors.primary : Colors.grey),
      ),
    );
  }
}
