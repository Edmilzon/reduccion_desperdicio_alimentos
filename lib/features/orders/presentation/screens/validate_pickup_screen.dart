import 'package:flutter/material.dart';
import 'package:reduccion_desperdicio_alimentos/core/theme/app_colors.dart';
import 'package:reduccion_desperdicio_alimentos/features/orders/data/models/order_model.dart';
import 'package:reduccion_desperdicio_alimentos/features/orders/data/repositories/order_repository.dart';

class ValidatePickupScreen extends StatefulWidget {
  const ValidatePickupScreen({super.key});

  @override
  State<ValidatePickupScreen> createState() => _ValidatePickupScreenState();
}

class _ValidatePickupScreenState extends State<ValidatePickupScreen> {
  final OrderRepository _repository = OrderRepository();
  final TextEditingController _codeController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  OrderModel? _validatedOrder;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _validateCode() async {
    final code = _codeController.text.trim();

    if (code.isEmpty) {
      setState(() {
        _errorMessage = 'Ingresa el código de reserva';
        _successMessage = null;
        _validatedOrder = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
      _validatedOrder = null;
    });

    try {
      final result = await _repository.validatePickup(
        reservationCode: code,
      );

      if (!mounted) return;

      setState(() {
        _validatedOrder = result.order;
        _successMessage = result.message;
        _errorMessage = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _successMessage = null;
        _validatedOrder = null;
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _shortCode(String code) {
    if (code.isEmpty) return 'SIN-CODIGO';
    if (code.length <= 8) return code.toUpperCase();
    return code.substring(0, 8).toUpperCase();
  }

  String _formatDateTime(DateTime? date) {
    if (date == null) return 'No disponible';

    final local = date.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');

    return '$day/$month $hour:$minute';
  }

  String _formatPickup(DateTime? start, DateTime? end) {
    if (start == null || end == null) return 'No disponible';

    final s = start.toLocal();
    final e = end.toLocal();

    final day = s.day.toString().padLeft(2, '0');
    final month = s.month.toString().padLeft(2, '0');
    final startHour = s.hour.toString().padLeft(2, '0');
    final startMinute = s.minute.toString().padLeft(2, '0');
    final endHour = e.hour.toString().padLeft(2, '0');
    final endMinute = e.minute.toString().padLeft(2, '0');

    return '$day/$month $startHour:$startMinute - $endHour:$endMinute';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        centerTitle: true,
        title: const Text(
          'Validar entrega',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoBox(),
            const SizedBox(height: 28),
            const Text(
              'Código de reserva',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            _buildCodeField(),
            const SizedBox(height: 16),
            _buildValidateButton(),
            const SizedBox(height: 22),
            if (_successMessage != null) _buildSuccessCard(),
            if (_errorMessage != null) _buildErrorCard(),
            if (_validatedOrder != null) ...[
              const SizedBox(height: 18),
              _buildOrderDetail(_validatedOrder!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.info_outline,
            color: AppColors.textPrimary,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Ingresa el código de reserva presentado por el cliente para confirmar la recogida.',
              style: TextStyle(
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeField() {
    return TextField(
      controller: _codeController,
      textCapitalization: TextCapitalization.none,
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => _validateCode(),
      decoration: InputDecoration(
        hintText: 'Ej: 71b2358e-c335-46d2-95e5-9f029f2910e4',
        prefixIcon: const Icon(Icons.confirmation_number_outlined),
        filled: true,
        fillColor: AppColors.cardBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildValidateButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _validateCode,
        icon: _isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.verified_outlined),
        label: Text(_isLoading ? 'Validando...' : 'Validar código'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.green.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.check_circle_outline,
            color: Colors.green,
            size: 48,
          ),
          const SizedBox(height: 8),
          Text(
            _successMessage ?? 'Entrega confirmada',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          if (_validatedOrder?.deliveredAt != null) ...[
            const SizedBox(height: 6),
            Text(
              'Hora registrada: ${_formatDateTime(_validatedOrder!.deliveredAt)}',
              style: const TextStyle(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    final isUsed = _errorMessage == 'Código ya utilizado';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (isUsed ? Colors.orange : Colors.red).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: (isUsed ? Colors.orange : Colors.red).withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        children: [
          Icon(
            isUsed ? Icons.warning_amber_rounded : Icons.error_outline,
            color: isUsed ? Colors.orange : Colors.red,
            size: 48,
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? 'Error de validación',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isUsed ? Colors.orange : Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isUsed
                ? 'Este código ya fue validado anteriormente.'
                : 'Verifica el código e intenta nuevamente.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderDetail(OrderModel order) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Detalle de la reserva',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: Text(
              _shortCode(order.reservationCode),
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 24,
                letterSpacing: 3,
              ),
            ),
          ),
          const Divider(height: 26),
          _detailRow('Cliente', order.buyerName ?? order.buyerEmail ?? 'No disponible'),
          _detailRow('Producto', order.productTitle ?? 'Producto'),
          _detailRow('Cantidad', '${order.quantity} unidad(es)'),
          _detailRow('Total', 'Bs ${order.totalPrice.toStringAsFixed(2)}'),
          _detailRow('Método de pago', order.paymentMethodLabel),
          _detailRow('Estado pago', order.paymentStatusLabel),
          _detailRow('Estado entrega', order.deliveryStatusLabel),
          _detailRow(
            'Horario recogida',
            _formatPickup(order.pickupStart, order.pickupEnd),
          ),
          _detailRow(
            'Hora entrega',
            _formatDateTime(order.deliveredAt),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}