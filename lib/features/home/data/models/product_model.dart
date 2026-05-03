class CategoryModel {
  final int id;
  final String name;
  final String slug;
  final String? imageUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<ProductModel>? products;

  CategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    this.imageUrl,
    this.createdAt,
    this.updatedAt,
    this.products,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    final productsJson = json['products'] as List<dynamic>?;
    return CategoryModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      imageUrl: json['imageUrl'] ?? json['image_url'],
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt']) : null,
      products: productsJson?.map((p) => ProductModel.fromJson(p)).toList() ?? [],
    );
  }

  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;
  bool get hasSlug => slug.isNotEmpty;
  bool get hasProducts => products != null && products!.isNotEmpty;
  
  int get productCount => products?.length ?? 0;
  
  double? get maxDiscount {
    if (!hasProducts) return null;
    double max = 0;
    for (final p in products!) {
      final discount = p.discountPercentage;
      if (discount > max) max = discount;
    }
    return max > 0 ? max : null;
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
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final CategoryModel? category;

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
    this.createdAt,
    this.updatedAt,
    this.category,
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
      pickupStart: DateTime.tryParse(json['pickupStart'] ?? '') ?? DateTime.now(),
      pickupEnd: DateTime.tryParse(json['pickupEnd'] ?? '') ?? DateTime.now(),
      status: json['status'] ?? 'active',
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt']) : null,
      category: json['category'] != null 
          ? CategoryModel.fromJson(json['category']) 
          : CategoryModel(id: 0, name: '', slug: ''),
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