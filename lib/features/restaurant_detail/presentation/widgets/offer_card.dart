import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/restaurant_detail_model.dart';

class OfferCard extends StatelessWidget {
  final RestaurantOfferModel offer;

  const OfferCard({super.key, required this.offer});

  @override
  Widget build(BuildContext context) {
    final discount = offer.discountPercentage;
    final timeLeft = offer.pickupEnd.difference(DateTime.now());

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              bottomLeft: Radius.circular(12),
            ),
            child: _buildImage(),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          offer.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (discount > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '-${discount.toStringAsFixed(0)}%',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'Bs. ${offer.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      if (offer.originalPrice > offer.price) ...[
                        const SizedBox(width: 6),
                        Text(
                          'Bs. ${offer.originalPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: AppColors.textLight,
                            fontSize: 12,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 13,
                        color: _timeColor(timeLeft),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Límite: ${_formatTimeLeft(timeLeft)}',
                        style: TextStyle(
                          color: _timeColor(timeLeft),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    if (offer.imageUrl != null && offer.imageUrl!.isNotEmpty) {
      return Image.network(
        offer.imageUrl!,
        width: 90,
        height: 90,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _placeholder(),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      width: 90,
      height: 90,
      color: AppColors.cardBg,
      child: const Icon(Icons.fastfood, color: AppColors.textLight, size: 32),
    );
  }

  Color _timeColor(Duration timeLeft) {
    if (timeLeft.isNegative) return Colors.red;
    if (timeLeft.inMinutes <= 30) return AppColors.secondary;
    return AppColors.textSecondary;
  }

  String _formatTimeLeft(Duration duration) {
    if (duration.isNegative) return 'Expirado';
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    }
    return '${duration.inMinutes}m';
  }
}
