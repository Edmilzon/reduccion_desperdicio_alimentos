class OrderResponse {
  final int id;
  final int productId;
  final String productTitle;
  final String commerceName;
  final int quantity;
  final double totalPrice;
  final String status;
  final String paymentMethod;
  final String paymentStatus;
  final String reservationCode;
  final String createdAt;
  final String? paidAt;
  final String? receiptUrl;

  OrderResponse({
    required this.id,
    required this.productId,
    required this.productTitle,
    required this.commerceName,
    required this.quantity,
    required this.totalPrice,
    required this.status,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.reservationCode,
    required this.createdAt,
    this.paidAt,
    this.receiptUrl,
  });

  bool get isPaid => paymentStatus == 'paid';
  bool get isCash => paymentMethod == 'cash';
  bool get isPendingPayment => paymentStatus == 'pending' && !isCash;

  factory OrderResponse.fromJson(Map<String, dynamic> json) {
    final product = json['product'] as Map<String, dynamic>?;
    final commerce = product?['commerce'] as Map<String, dynamic>?;
    return OrderResponse(
      id: json['id'] ?? 0,
      productId: product?['id'] ?? 0,
      productTitle: product?['title']?.toString() ?? '',
      commerceName: commerce?['name']?.toString() ?? '',
      quantity: json['quantity'] ?? 0,
      totalPrice: (json['totalPrice'] ?? 0).toDouble(),
      status: json['status'] ?? '',
      paymentMethod: json['paymentMethod'] ?? 'cash',
      paymentStatus: json['paymentStatus'] ?? 'pending',
      reservationCode: json['reservationCode'] ?? '',
      createdAt: json['createdAt'] ?? '',
      paidAt: json['paidAt']?.toString(),
      receiptUrl: json['receiptUrl']?.toString(),
    );
  }
}
