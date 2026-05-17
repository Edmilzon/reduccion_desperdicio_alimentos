class RestaurantDetailModel {
  final int id;
  final String name;
  final String? description;
  final String? address;
  final String? openTime;
  final String? closeTime;
  final double? latitude;
  final double? longitude;
  final String? nit;
  final List<RestaurantOfferModel> offers;

  RestaurantDetailModel({
    required this.id,
    required this.name,
    this.description,
    this.address,
    this.openTime,
    this.closeTime,
    this.latitude,
    this.longitude,
    this.nit,
    required this.offers,
  });

  factory RestaurantDetailModel.fromJson(Map<String, dynamic> json) {
    final productsJson = json['products'] as List<dynamic>?;
    return RestaurantDetailModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      address: json['address']?.toString(),
      openTime: json['openTime']?.toString(),
      closeTime: json['closeTime']?.toString(),
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
      nit: json['nit']?.toString(),
      offers: productsJson
              ?.map((p) =>
                  RestaurantOfferModel.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  static double? _parseDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString());
  }

  bool get hasCoordinates => latitude != null && longitude != null;
  bool get hasOffers => offers.isNotEmpty;

  String get scheduleText {
    if (openTime != null && closeTime != null) {
      return '$openTime - $closeTime';
    }
    return 'Horario no disponible';
  }
}

class RestaurantOfferModel {
  final int id;
  final String title;
  final String description;
  final double originalPrice;
  final double price;
  final int quantity;
  final String? imageUrl;
  final DateTime pickupEnd;
  final String? status;

  RestaurantOfferModel({
    required this.id,
    required this.title,
    required this.description,
    required this.originalPrice,
    required this.price,
    required this.quantity,
    this.imageUrl,
    required this.pickupEnd,
    this.status,
  });

  factory RestaurantOfferModel.fromJson(Map<String, dynamic> json) {
    return RestaurantOfferModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      originalPrice: _parseDouble(json['originalPrice']) ?? 0,
      price: _parseDouble(json['price']) ?? 0,
      quantity: json['quantity'] is int ? json['quantity'] as int : int.tryParse(json['quantity']?.toString() ?? '0') ?? 0,
      imageUrl: json['imageUrl']?.toString(),
      pickupEnd: DateTime.tryParse(json['pickupEnd']?.toString() ?? '') ??
          DateTime.now(),
      status: json['status']?.toString(),
    );
  }

  static double? _parseDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString());
  }

  double get discountPercentage {
    if (originalPrice > 0) {
      return ((originalPrice - price) / originalPrice * 100).roundToDouble();
    }
    return 0;
  }

  bool get isAvailable => status == 'active' && quantity > 0;
}
