class OfertaModel {
  final int id;
  final String title;
  final String description;
  final double originalPrice;
  final double price;
  final int quantity;
  final String? imageUrl;
  final DateTime pickupStart;
  final DateTime pickupEnd;
  final String? status;
  final DateTime? createdAt;
  final int? categoryId;
  final String? categoryName;
  final int? commerceId;

  OfertaModel({
    this.id = 0,
    this.title = '',
    this.description = '',
    this.originalPrice = 0,
    this.price = 0,
    this.quantity = 0,
    this.imageUrl,
    DateTime? pickupStart,
    DateTime? pickupEnd,
    this.status,
    this.createdAt,
    this.categoryId,
    this.categoryName,
    this.commerceId,
  })  : pickupStart = pickupStart ?? DateTime.now(),
        pickupEnd = pickupEnd ?? DateTime.now().add(const Duration(hours: 2));

  factory OfertaModel.fromJson(Map<String, dynamic> json) {
    final idVal = json['id'];
    return OfertaModel(
      id: idVal is int ? idVal : int.tryParse(idVal?.toString() ?? '0') ?? 0,
      title: json['title'] ?? json['nombre'] ?? '',
      description: json['description'] ?? '',
      originalPrice: _parseDouble(json['originalPrice']) ?? _parseDouble(json['precioOriginal']) ?? 0,
      price: _parseDouble(json['price']) ?? _parseDouble(json['precio']) ?? 0,
      quantity: json['quantity'] ?? json['unidadesRestantes'] ?? 0,
      imageUrl: json['imageUrl'],
      pickupStart: _parseDateTime(json['pickupStart']) ?? _parseDateTime(json['horaLimite']),
      pickupEnd: _parseDateTime(json['pickupEnd']),
      status: json['status'] ?? json['estado'],
      createdAt: _parseDateTime(json['createdAt']) ?? _parseDateTime(json['creadaEn']),
      categoryId: json['categoryId'],
      categoryName: json['categoryName'] ?? json['categoria'],
      commerceId: json['commerceId'],
    );
  }

  factory OfertaModel.legacy({
    dynamic id,
    String? categoria,
    String? nombre,
    int? unidadesRestantes,
    double? precio,
    double? precioOriginal,
    String? estado,
    DateTime? horaLimite,
    DateTime? creadaEn,
  }) {
    return OfertaModel(
      id: id is int ? id : int.tryParse(id?.toString() ?? '0') ?? 0,
      title: nombre ?? '',
      description: '',
      originalPrice: precioOriginal ?? precio ?? 0,
      price: precio ?? 0,
      quantity: unidadesRestantes ?? 0,
      pickupEnd: horaLimite ?? DateTime.now(),
      createdAt: horaLimite ?? DateTime.now(),
      status: estado == 'sold' ? 'sold' : 'active',
      categoryName: categoria,
    );
  }

  static double? _parseDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString());
  }

  static DateTime? _parseDateTime(dynamic v) {
    if (v == null) return null;
    if (v is String) return DateTime.tryParse(v);
    if (v is DateTime) return v;
    return null;
  }

  bool get isActive => status == 'active';
  bool get isSold => status == 'sold' || quantity == 0;

  bool get isExpiringSoon {
    final diff = pickupEnd.difference(DateTime.now());
    return isActive && diff.inMinutes <= 30 && diff.inMinutes > 0;
  }

  double get discountPercentage {
    if (originalPrice > 0) {
      return ((originalPrice - price) / originalPrice * 100);
    }
    return 0;
  }

  String get nombre => title;
  String get categoria => categoryName ?? '';
  double get precio => price;
  double? get precioOriginal => originalPrice > 0 ? originalPrice : null;
  String get estado => status ?? 'active';
  DateTime get horaLimite => pickupEnd;
  DateTime get creadaEn => createdAt ?? DateTime.now();
  int get unidadesRestantes => quantity;
}