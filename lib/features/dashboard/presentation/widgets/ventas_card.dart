import 'package:flutter/material.dart';
import 'package:reduccion_desperdicio_alimentos/core/theme/app_colors.dart';

class VentasCard extends StatelessWidget {
  final double ventas;
  final double porcentajeCambio;

  const VentasCard({
    super.key,
    required this.ventas,
    required this.porcentajeCambio,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = porcentajeCambio >= 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 3, height: 14, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                'VENTAS DEL DÍA',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${_formatVentas(ventas)}Bs.',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                isPositive ? Icons.trending_up : Icons.trending_down,
                size: 14,
                color: isPositive ? Colors.green : AppColors.primary,
              ),
              const SizedBox(width: 4),
              Text(
                '${isPositive ? '+' : ''}${porcentajeCambio.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isPositive ? Colors.green : AppColors.primary,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'vs. ayer',
                style: TextStyle(fontSize: 11, color: AppColors.textLight),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatVentas(double v) {
    final n = v.toStringAsFixed(0);
    final result = StringBuffer();
    for (int i = 0; i < n.length; i++) {
      if (i > 0 && (n.length - i) % 3 == 0) result.write(',');
      result.write(n[i]);
    }
    return result.toString();
  }
}
