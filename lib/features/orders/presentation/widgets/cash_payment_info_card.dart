import 'package:flutter/material.dart';
import 'package:reduccion_desperdicio_alimentos/core/theme/app_colors.dart';

class CashPaymentInfoCard extends StatelessWidget {
  const CashPaymentInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.info_outline,
            color: AppColors.textSecondary,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Recuerda pagar al momento de recoger tu pedido en el local.',
              style: TextStyle(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}