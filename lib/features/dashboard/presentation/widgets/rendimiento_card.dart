import 'package:flutter/material.dart';
import 'package:reduccion_desperdicio_alimentos/core/theme/app_colors.dart';

class RendimientoCard extends StatelessWidget {
  final int ofertasActivas;
  final int ofertasVendidas;
  final double tasaExito;
  final int tiempoPromedioMin;

  const RendimientoCard({
    super.key,
    required this.ofertasActivas,
    required this.ofertasVendidas,
    required this.tasaExito,
    required this.tiempoPromedioMin,
  });

  @override
  Widget build(BuildContext context) {
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
              const Icon(Icons.rocket_launch_outlined, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              const Text(
                'Rendimiento de Ofertas',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _stat('$ofertasActivas', 'Ofertas\nActivas', AppColors.textPrimary)),
              Container(width: 1, height: 40, color: Colors.grey.shade200),
              Expanded(child: _stat('$ofertasVendidas', 'Ya\nVendidas', AppColors.secondary)),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TASA DE ÉXITO',
                      style: TextStyle(fontSize: 10, color: AppColors.textLight, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${tasaExito.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TIEMPO PROM.',
                      style: TextStyle(fontSize: 10, color: AppColors.textLight, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${tiempoPromedioMin}m',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(String value, String label, Color valueColor) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: valueColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.3),
        ),
      ],
    );
  }
}
