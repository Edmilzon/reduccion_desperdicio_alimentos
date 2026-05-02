class CategoryModel {
  final int id;
  final String name;
  final String slug;
  final DateTime createdAt;
  final DateTime updatedAt;

  CategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class ProductModel {
  final int id;
  final String title;
  final String description;
  final double originalPrice;
  final double price;
  final int quantity;
  final String imageUrl;
  final DateTime pickupStart;
  final DateTime pickupEnd;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final CategoryModel category;

  ProductModel({
    required this.id,
    required this.title,
    required this.description,
    required this.originalPrice,
    required this.price,
    required this.quantity,
    required this.imageUrl,
    required this.pickupStart,
    required this.pickupEnd,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.category,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      originalPrice: double.tryParse(json['originalPrice']?.toString() ?? '0') ?? 0,
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0,
      quantity: json['quantity'] ?? 0,
      imageUrl: json['imageUrl'] ?? '',
      pickupStart: DateTime.parse(json['pickupStart'] ?? DateTime.now().toIso8601String()),
      pickupEnd: DateTime.parse(json['pickupEnd'] ?? DateTime.now().toIso8601String()),
      status: json['status'] ?? 'active',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
      category: json['category'] != null 
          ? CategoryModel.fromJson(json['category']) 
          : CategoryModel(id: 0, name: '', slug: '', createdAt: DateTime.now(), updatedAt: DateTime.now()),
    );
  }

  double get discountPercentage {
    if (originalPrice > 0) {
      return ((originalPrice - price) / originalPrice * 100).roundToDouble();
    }
    return 0;
  }

  bool get isAvailable => quantity > 0 && status == 'active';
}