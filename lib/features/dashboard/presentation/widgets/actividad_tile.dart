import 'package:flutter/material.dart';
import 'package:reduccion_desperdicio_alimentos/core/theme/app_colors.dart';

enum TipoActividad { vendida, nueva, stock }

class ActividadTile extends StatelessWidget {
  final TipoActividad tipo;
  final String titulo;
  final String subtitulo;
  final double? monto;
  final String? badge;

  const ActividadTile({
    super.key,
    required this.tipo,
    required this.titulo,
    required this.subtitulo,
    this.monto,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(_icon, size: 18, color: _iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitulo,
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          if (monto != null)
            Text(
              '+${monto!.toStringAsFixed(2)} Bs.',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          if (badge != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.olive.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.olive.withValues(alpha: 0.4)),
              ),
              child: Text(
                badge!,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.olive,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color get _iconBg {
    switch (tipo) {
      case TipoActividad.vendida: return AppColors.primary.withValues(alpha: 0.1);
      case TipoActividad.nueva:   return AppColors.olive.withValues(alpha: 0.1);
      case TipoActividad.stock:   return AppColors.amber.withValues(alpha: 0.1);
    }
  }

  Color get _iconColor {
    switch (tipo) {
      case TipoActividad.vendida: return AppColors.primary;
      case TipoActividad.nueva:   return AppColors.olive;
      case TipoActividad.stock:   return AppColors.amber;
    }
  }

  IconData get _icon {
    switch (tipo) {
      case TipoActividad.vendida: return Icons.check_circle_outline;
      case TipoActividad.nueva:   return Icons.add_circle_outline;
      case TipoActividad.stock:   return Icons.sync_outlined;
    }
  }
}
