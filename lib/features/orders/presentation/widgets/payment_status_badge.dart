import 'package:flutter/material.dart';

class PaymentStatusBadge extends StatelessWidget {
  final String status;

  const PaymentStatusBadge({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final data = _getStatusData(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: data.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        data.label,
        style: TextStyle(
          color: data.color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  _StatusData _getStatusData(String status) {
    switch (status) {
      case 'pending':
        return _StatusData('Pendiente de pago', Colors.orange);
      case 'paid':
        return _StatusData('Pagado', Colors.green);
      case 'rejected':
        return _StatusData('Rechazado', Colors.red);
      case 'delivered':
        return _StatusData('Entregado', Colors.green);
      case 'not_picked_up':
        return _StatusData('No recogido', Colors.red);
      case 'confirmed':
        return _StatusData('Confirmado', Colors.blue);
      default:
        return _StatusData(status, Colors.grey);
    }
  }
}

class _StatusData {
  final String label;
  final Color color;

  _StatusData(this.label, this.color);
}