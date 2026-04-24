import 'package:flutter/material.dart';
import 'package:reduccion_desperdicio_alimentos/core/theme/app_colors.dart';
import 'package:reduccion_desperdicio_alimentos/features/dashboard/data/models/oferta_model.dart';

class OfferCard extends StatelessWidget {
  final OfertaModel oferta;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const OfferCard({
    super.key,
    required this.oferta,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      oferta.categoria.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      oferta.nombre,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              _EstadoBadge(estado: oferta.estado),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.inventory_2_outlined, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                '${oferta.unidadesRestantes} unidades restantes',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                '${oferta.precio.toStringAsFixed(2)}Bs.',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              if (oferta.precioOriginal != null) ...[
                const SizedBox(width: 6),
                Text(
                  '${oferta.precioOriginal!.toStringAsFixed(2)}Bs.',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textLight,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ],
              const Spacer(),
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textSecondary),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
              const SizedBox(width: 4),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.primary),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EstadoBadge extends StatelessWidget {
  final String estado;
  const _EstadoBadge({required this.estado});

  @override
  Widget build(BuildContext context) {
    final isActive = estado == 'active';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isActive ? AppColors.olive : AppColors.textLight,
        ),
      ),
      child: Text(
        isActive ? 'ACTIVO' : 'VENDIDO',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: isActive ? AppColors.olive : AppColors.textLight,
        ),
      ),
    );
  }
}
