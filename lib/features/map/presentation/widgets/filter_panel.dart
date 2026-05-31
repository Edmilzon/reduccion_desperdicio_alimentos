import 'package:flutter/material.dart';
import 'package:reduccion_desperdicio_alimentos/core/theme/app_colors.dart';
import 'package:reduccion_desperdicio_alimentos/features/home/data/models/product_model.dart';
import 'package:reduccion_desperdicio_alimentos/features/map/data/filter_store.dart';

/// Panel de filtros (bottom sheet) con slider de distancia y chips de categoría.
class FilterPanel extends StatefulWidget {
  const FilterPanel({super.key});

  @override
  State<FilterPanel> createState() => _FilterPanelState();
}

class _FilterPanelState extends State<FilterPanel> {
  final FilterStore _store = FilterStore.instance;

  late double _tempRadius;
  late CategoryModel? _tempCategory;

  @override
  void initState() {
    super.initState();
    _tempRadius = _store.radius;
    _tempCategory = _store.selectedCategory;

    if (_store.activeCategories.isEmpty && !_store.loadingCategories) {
      _store.fetchActiveCategories().then((_) {
        if (mounted) setState(() {});
      });
    }
  }

  String _radiusLabel(double v) {
    if (v <= 0) return 'Cualquier distancia';
    return 'Hasta ${v.toStringAsFixed(0)} km';
  }

  void _apply() {
    _store.setRadius(_tempRadius);
    _store.setSelectedCategory(_tempCategory);
    if (mounted) Navigator.of(context).pop(true);
  }

  void _clear() {
    setState(() {
      _tempRadius = 0.0;
      _tempCategory = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 8,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Handle ───────────────────────────────────────────
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // ── Header ───────────────────────────────────────────
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Filtros de búsqueda',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (_tempRadius > 0 || _tempCategory != null)
                TextButton(
                  onPressed: _clear,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(60, 32),
                  ),
                  child: const Text('Limpiar'),
                ),
            ],
          ),

          const SizedBox(height: 20),

          // ── Sección Radio ─────────────────────────────────────
          Row(
            children: [
              const Icon(Icons.social_distance_outlined,
                  size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text(
                'Radio de distancia',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _tempRadius > 0
                      ? AppColors.primary.withValues(alpha: 0.12)
                      : AppColors.cardBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _radiusLabel(_tempRadius),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _tempRadius > 0
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),

          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primary,
              thumbColor: AppColors.primary,
              inactiveTrackColor: AppColors.primary.withValues(alpha: 0.2),
              overlayColor: AppColors.primary.withValues(alpha: 0.1),
              valueIndicatorColor: AppColors.primary,
               showValueIndicator: ShowValueIndicator.onDrag,
            ),
            child: Slider(
              value: _tempRadius,
              min: 0,
              max: 15,
              divisions: 15,
              label: _radiusLabel(_tempRadius),
              onChanged: (v) => setState(() => _tempRadius = v),
            ),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('Sin límite',
                  style: TextStyle(fontSize: 10, color: AppColors.textLight)),
              Text('15 km',
                  style: TextStyle(fontSize: 10, color: AppColors.textLight)),
            ],
          ),

          const SizedBox(height: 24),

          // ── Sección Categoría ──────────────────────────────────
          Row(
            children: const [
              Icon(Icons.restaurant_menu, size: 20, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                'Tipo de comida',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          _buildCategoryChips(),

          const SizedBox(height: 28),

          // ── Botón Aplicar ──────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _apply,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text(
                _tempRadius > 0 || _tempCategory != null
                    ? 'Aplicar filtros'
                    : 'Ver todos los locales',
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    if (_store.loadingCategories) {
      return const SizedBox(
        height: 36,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child:
                CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
          ),
        ),
      );
    }

    if (_store.activeCategories.isEmpty) {
      return const Text(
        'No hay categorías disponibles',
        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
      );
    }

    final categories = _store.activeCategories;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // "Todas" chip
        _CategoryChip(
          label: 'Todas',
          icon: Icons.apps,
          isSelected: _tempCategory == null,
          onTap: () => setState(() => _tempCategory = null),
        ),
        ...categories.map((cat) => _CategoryChip(
              label: cat.name,
              isSelected: _tempCategory?.id == cat.id,
              onTap: () => setState(() => _tempCategory = cat),
            )),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon,
                  size: 14,
                  color: isSelected ? Colors.white : AppColors.textSecondary),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight:
                    isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Helper para mostrar el panel de filtros como modal bottom sheet.
Future<bool?> showFilterPanel(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const FilterPanel(),
  );
}
