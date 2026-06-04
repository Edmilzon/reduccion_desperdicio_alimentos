import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CachedFavoriteProduct {
  final int id;
  final String title;
  final double price;
  final double originalPrice;
  final String? imageUrl;
  final String? commerceName;
  final DateTime pickupEnd;
  final String status;
  final int quantity;

  CachedFavoriteProduct({
    required this.id,
    required this.title,
    required this.price,
    required this.originalPrice,
    this.imageUrl,
    this.commerceName,
    required this.pickupEnd,
    required this.status,
    required this.quantity,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'price': price,
    'originalPrice': originalPrice,
    'imageUrl': imageUrl,
    'commerceName': commerceName,
    'pickupEnd': pickupEnd.toIso8601String(),
    'status': status,
    'quantity': quantity,
  };

  factory CachedFavoriteProduct.fromJson(Map<String, dynamic> json) =>
      CachedFavoriteProduct(
        id: json['id'] ?? 0,
        title: json['title'] ?? '',
        price: (json['price'] ?? 0).toDouble(),
        originalPrice: (json['originalPrice'] ?? 0).toDouble(),
        imageUrl: json['imageUrl'],
        commerceName: json['commerceName'],
        pickupEnd: DateTime.tryParse(json['pickupEnd'] ?? '') ?? DateTime.now(),
        status: json['status'] ?? 'active',
        quantity: json['quantity'] ?? 0,
      );

  double get discountPercentage {
    if (originalPrice > 0) {
      return ((originalPrice - price) / originalPrice * 100).roundToDouble();
    }
    return 0;
  }

  bool get isAvailable => quantity > 0 && status == 'active';

  bool get isExpiringSoon {
    final diff = pickupEnd.difference(DateTime.now());
    return isAvailable && diff.inMinutes <= 30 && diff.inMinutes > 0;
  }
}

class FavoritesRepository {
  static const String _idsKey = 'favorite_products';
  static const String _dataKey = 'favorite_products_data';

  static final _FavoritesNotifier _notifier = _FavoritesNotifier();
  static _FavoritesNotifier get notifier => _notifier;

  Future<Set<int>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_idsKey);
    if (data == null) return {};
    final list = jsonDecode(data) as List<dynamic>;
    return list.map((e) => e as int).toSet();
  }

  Future<bool> isFavorite(int productId) async {
    final favorites = await getFavorites();
    return favorites.contains(productId);
  }

  Future<List<CachedFavoriteProduct>> getFavoriteProducts() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_dataKey);
    if (data == null) return [];
    final map = jsonDecode(data) as Map<String, dynamic>;
    final ids = await getFavorites();
    return map.entries
        .where((e) => ids.contains(int.tryParse(e.key) ?? 0))
        .map((e) => CachedFavoriteProduct.fromJson(e.value))
        .toList()
      ..sort((a, b) => b.pickupEnd.compareTo(a.pickupEnd));
  }

  Future<void> addFavorite(int productId, {Map<String, dynamic>? productData}) async {
    final favorites = await getFavorites();
    favorites.add(productId);
    await _saveIds(favorites);

    if (productData != null) {
      await _saveProductData(productId, productData);
    }

    _notifier.refresh();
  }

  Future<void> removeFavorite(int productId) async {
    final favorites = await getFavorites();
    favorites.remove(productId);
    await _saveIds(favorites);

    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_dataKey);
    if (data != null) {
      final map = jsonDecode(data) as Map<String, dynamic>;
      map.remove(productId.toString());
      await prefs.setString(_dataKey, jsonEncode(map));
    }

    _notifier.refresh();
  }

  Future<void> toggleFavorite(int productId, {Map<String, dynamic>? productData}) async {
    final favorites = await getFavorites();
    if (favorites.contains(productId)) {
      favorites.remove(productId);
      await _saveIds(favorites);
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_dataKey);
      if (data != null) {
        final map = jsonDecode(data) as Map<String, dynamic>;
        map.remove(productId.toString());
        await prefs.setString(_dataKey, jsonEncode(map));
      }
    } else {
      favorites.add(productId);
      await _saveIds(favorites);
      if (productData != null) {
        await _saveProductData(productId, productData);
      }
    }
    _notifier.refresh();
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_idsKey);
    await prefs.remove(_dataKey);
    _notifier.refresh();
  }

  Future<void> _saveIds(Set<int> favorites) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_idsKey, jsonEncode(favorites.toList()));
  }

  Future<void> _saveProductData(int productId, Map<String, dynamic> productData) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_dataKey);
    final map = data != null ? jsonDecode(data) as Map<String, dynamic> : <String, dynamic>{};
    map[productId.toString()] = productData;
    await prefs.setString(_dataKey, jsonEncode(map));
  }
}

class _FavoritesNotifier extends ChangeNotifier {
  void refresh() => notifyListeners();
}
