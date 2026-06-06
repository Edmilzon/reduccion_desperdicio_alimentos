import 'package:flutter/material.dart';
import '../../data/map_api_service.dart';

class CommerceBottomSheet extends StatelessWidget {
  final MapCommerceModel commerce;
  final VoidCallback onViewOffers;

  const CommerceBottomSheet({
    super.key,
    required this.commerce,
    required this.onViewOffers,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      commerce.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    if (commerce.branchName != null && commerce.branchName!.isNotEmpty)
                      Text(
                        commerce.branchName!,
                        style: TextStyle(color: Colors.green[700], fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                  ],
                ),
              ),
              if (commerce.distance != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${commerce.distance!.toStringAsFixed(1)} km',
                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          if (commerce.description != null) ...[
            const SizedBox(height: 12),
            Text(
              commerce.description!,
              style: TextStyle(color: Colors.grey[600]),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onViewOffers,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text(
                'VER OFERTAS DISPONIBLES',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
