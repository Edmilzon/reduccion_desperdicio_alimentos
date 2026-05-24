class OrderModel {
  final int id;
  final String reservationCode;
  final int quantity;
  final double totalPrice;

  final String paymentMethod;
  final String paymentStatus;
  final String deliveryStatus;
  final String status;

  final DateTime? createdAt;
  final DateTime? paidAt;

  final int? productId;
  final String? productTitle;
  final String? productDescription;
  final String? productImageUrl;
  final DateTime? pickupStart;
  final DateTime? pickupEnd;

  final int? commerceId;
  final String? commerceName;

  final String? buyerEmail;
  final String? buyerName;

  OrderModel({
    required this.id,
    required this.reservationCode,
    required this.quantity,
    required this.totalPrice,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.deliveryStatus,
    required this.status,
    this.createdAt,
    this.paidAt,
    this.productId,
    this.productTitle,
    this.productDescription,
    this.productImageUrl,
    this.pickupStart,
    this.pickupEnd,
    this.commerceId,
    this.commerceName,
    this.buyerEmail,
    this.buyerName,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final product = json['product'] as Map<String, dynamic>?;
    final commerce = product?['commerce'] as Map<String, dynamic>?;
    final buyer = json['buyer'] as Map<String, dynamic>?;

    return OrderModel(
      id: _toInt(json['id']),
      reservationCode: json['reservationCode']?.toString() ?? '',
      quantity: _toInt(json['quantity']),
      totalPrice: _toDouble(json['totalPrice']),

      paymentMethod: json['paymentMethod']?.toString() ?? 'cash',
      paymentStatus: json['paymentStatus']?.toString() ?? 'pending',
      deliveryStatus: json['deliveryStatus']?.toString() ?? 'pending',
      status: json['status']?.toString() ?? '',

      createdAt: _toDate(json['createdAt']),
      paidAt: _toDate(json['paidAt']),

      productId: _toNullableInt(product?['id']),
      productTitle: product?['title']?.toString(),
      productDescription: product?['description']?.toString(),
      productImageUrl: product?['imageUrl']?.toString(),
      pickupStart: _toDate(product?['pickupStart']),
      pickupEnd: _toDate(product?['pickupEnd']),

      commerceId: _toNullableInt(commerce?['id']),
      commerceName: commerce?['name']?.toString(),

      buyerEmail: buyer?['email']?.toString(),
      buyerName: buyer?['name']?.toString(),
    );
  }

  bool get isCash => paymentMethod == 'cash';

  bool get isPendingPayment => paymentStatus == 'pending';

  bool get isPendingCashPayment =>
      paymentMethod == 'cash' && paymentStatus == 'pending';

  bool get isPaid => paymentStatus == 'paid';

  bool get isDelivered => deliveryStatus == 'delivered';

  bool get isNotPickedUp => deliveryStatus == 'not_picked_up';

  bool get canBeMarkedAsPaidAndDelivered =>
      isCash && isPendingPayment && deliveryStatus == 'pending';

  bool get canBeDelivered =>
      isPaid && deliveryStatus == 'pending';

  String get paymentMethodLabel {
    switch (paymentMethod) {
      case 'cash':
        return 'Pago en sucursal';
      case 'online':
        return 'Pago dentro de la app';
      default:
        return paymentMethod;
    }
  }

  String get paymentStatusLabel {
    switch (paymentStatus) {
      case 'pending':
        return 'Pendiente de pago';
      case 'paid':
        return 'Pagado';
      case 'rejected':
        return 'Rechazado';
      default:
        return paymentStatus;
    }
  }

  String get deliveryStatusLabel {
    switch (deliveryStatus) {
      case 'pending':
        return 'Confirmada';
      case 'delivered':
        return 'Entregada';
      case 'not_picked_up':
        return 'No recogido';
      default:
        return deliveryStatus;
    }
  }

  static int _toInt(dynamic value) {
    return int.tryParse(value?.toString() ?? '0') ?? 0;
  }

  static int? _toNullableInt(dynamic value) {
    if (value == null) return null;
    return int.tryParse(value.toString());
  }

  static double _toDouble(dynamic value) {
    return double.tryParse(value?.toString() ?? '0') ?? 0;
  }

  static DateTime? _toDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}

typedef OrderResponse = OrderModel;
