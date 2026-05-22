import 'dart:math';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:reduccion_desperdicio_alimentos/core/theme/app_colors.dart';
import 'package:reduccion_desperdicio_alimentos/features/orders/data/models/order_model.dart';

class PaymentDialog extends StatefulWidget {
  final OrderModel order;

  const PaymentDialog({super.key, required this.order});

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  _PaymentMode _mode = _PaymentMode.select;
  late final String _transactionId;

  @override
  void initState() {
    super.initState();
    _transactionId = 'tx_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(99999)}';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Método de Pago', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(
        child: _buildContent(),
      ),
      actions: _mode == _PaymentMode.select
          ? []
          : [
              TextButton(
                onPressed: () => setState(() => _mode = _PaymentMode.select),
                child: const Text('Volver'),
              ),
            ],
    );
  }

  Widget _buildContent() {
    switch (_mode) {
      case _PaymentMode.select:
        return _buildSelection();
      case _PaymentMode.qr:
        return _buildQrPayment();
      case _PaymentMode.cash:
        return _buildCashMessage();
    }
  }

  Widget _buildSelection() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(
                '\$${widget.order.totalPrice.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
              const SizedBox(height: 4),
              Text(
                widget.order.productTitle ?? '',
                style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 4),
              Text(
                widget.order.commerceName ?? '',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text('Selecciona tu método de pago', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.qr_code, color: Colors.white),
            label: const Text('Pagar con QR', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            onPressed: () => setState(() => _mode = _PaymentMode.qr),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            icon: const Icon(Icons.money, color: AppColors.textSecondary),
            label: const Text('Efectivo', style: TextStyle(color: AppColors.textSecondary, fontSize: 16, fontWeight: FontWeight.bold)),
            onPressed: () => setState(() => _mode = _PaymentMode.cash),
          ),
        ),
      ],
    );
  }

  Widget _buildCashMessage() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.money_off, size: 64, color: Colors.green),
        const SizedBox(height: 16),
        const Text(
          'Pago en Efectivo',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 12),
        const Text(
          'Pagarás en efectivo cuando recojas el pedido. No es necesario realizar ningún pago en línea.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildQrPayment() {
    final paymentRef = 'ECO-${widget.order.id}-${_transactionId.substring(0, 8)}';
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Escanea el código QR para pagar',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 8),
        Text(
          '\$${widget.order.totalPrice.toStringAsFixed(2)}',
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primary),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: QrImageView(
            data: paymentRef,
            version: QrVersions.auto,
            size: 200,
            backgroundColor: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            paymentRef,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 1.2, color: AppColors.textSecondary),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(context, {'provider': 'stripe', 'transactionId': _transactionId}),
            child: const Text('Confirmar pago', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}

enum _PaymentMode { select, qr, cash }
