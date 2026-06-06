import 'order_model.dart';

class PickupValidationResult {
  final String message;
  final OrderModel order;

  PickupValidationResult({
    required this.message,
    required this.order,
  });

  factory PickupValidationResult.fromJson(Map<String, dynamic> json) {
    return PickupValidationResult(
      message: json['message']?.toString() ?? 'Entrega confirmada',
      order: OrderModel.fromJson(json['order'] as Map<String, dynamic>),
    );
  }
}