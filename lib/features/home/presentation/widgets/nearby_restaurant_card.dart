import 'package:flutter/material.dart';
import 'package:reduccion_desperdicio_alimentos/core/theme/app_colors.dart';
import 'package:reduccion_desperdicio_alimentos/features/map/data/map_api_service.dart';

class NearbyRestaurantCard extends StatelessWidget {
  final MapCommerceModel commerce;
  final VoidCallback? onTap;

  const NearbyRestaurantCard({
    super.key,
    required this.commerce,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final distance = commerce.distance != null
        ? '${commerce.distance!.toStringAsFixed(1)} km'
        : '-- km';

    final bool isInactive = !commerce.hasActiveOffers;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(color: Color(0xFFEAEAEA)),
          ),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 90,
                height: 90,
                color: AppColors.cardBg,
                child: Opacity(
                  opacity: isInactive ? 0.6 : 1.0,
                  child: commerce.imageUrl != null && commerce.imageUrl!.isNotEmpty
                      ? Image.network(
                          commerce.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.store, color: AppColors.primary),
                        )
                      : const Icon(Icons.store, color: AppColors.primary),
                ),
              ),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    commerce.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isInactive ? Colors.grey : AppColors.textPrimary,
                    ),
                  ),
                  if (commerce.branchName != null && commerce.branchName!.isNotEmpty)
                    Text(
                      commerce.branchName!,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isInactive ? Colors.grey : Colors.green[700],
                      ),
                    ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Icon(Icons.circle, size: 10, color: isInactive ? Colors.grey : Colors.green),
                      const SizedBox(width: 6),
                      Text(
                        isInactive ? 'Sin ofertas' : 'Disponible',
                        style: TextStyle(color: isInactive ? Colors.grey : Colors.green, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(Icons.shopping_bag_outlined, size: 15),
                      const SizedBox(width: 6),
                      Text('${commerce.availableOffers} ofertas disponibles'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 15),
                      const SizedBox(width: 6),
                      Text(
                        commerce.pickupLimit != null
                            ? 'Recoger hasta ${commerce.pickupLimit}'
                            : 'Horario no disponible',
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Column(
              children: [
                Text(
                  distance,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 30),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }
}