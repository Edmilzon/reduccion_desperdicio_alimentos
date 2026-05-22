import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CartItem {
  final int productId;
  final String title;
  final double price;
  final String imageUrl;
  final int quantity;
  final int? commerceId;
  final String? commerceName;
  final int stock;
  final DateTime? pickupEnd;

  CartItem({
    required this.productId,
    required this.title,
    required this.price,
    required this.imageUrl,
    required this.quantity,
    this.commerceId,
    this.commerceName,
    required this.stock,
    this.pickupEnd,
  });

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'title': title,
    'price': price,
    'imageUrl': imageUrl,
    'quantity': quantity,
    'commerceId': commerceId,
    'commerceName': commerceName,
    'stock': stock,
    'pickupEnd': pickupEnd?.toIso8601String(),
  };

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
    productId: json['productId'] ?? 0,
    title: json['title'] ?? '',
    price: (json['price'] ?? 0).toDouble(),
    imageUrl: json['imageUrl'] ?? '',
    quantity: json['quantity'] ?? 1,
    commerceId: json['commerceId'],
    commerceName: json['commerceName'],
    stock: json['stock'] != null ? (json['stock'] is int ? json['stock'] : int.tryParse(json['stock'].toString()) ?? 0) : (json['quantity'] ?? 0),
    pickupEnd: json['pickupEnd'] != null ? DateTime.tryParse(json['pickupEnd']) : null,
  );

  CartItem copyWith({int? quantity}) => CartItem(
    productId: productId,
    title: title,
    price: price,
    imageUrl: imageUrl,
    quantity: quantity ?? this.quantity,
    commerceId: commerceId,
    commerceName: commerceName,
    stock: stock,
    pickupEnd: pickupEnd,
  );
}

class _CartNotifier extends ChangeNotifier {
  void refresh() => notifyListeners();
}

class CartRepository {
  static const String _cartKey = 'cart_items';
  static final _CartNotifier _notifier = _CartNotifier();

  static _CartNotifier get notifier => _notifier;
  
  Future<List<CartItem>> getCartItems() async {
    final prefs = await SharedPreferences.getInstance();
    final cartJson = prefs.getString(_cartKey);
    if (cartJson == null) return [];
    
    final List<dynamic> cartList = jsonDecode(cartJson);
    return cartList.map((item) => CartItem.fromJson(item)).toList();
  }

  Future<void> addItem(CartItem item, int availableStock) async {
    final items = await getCartItems();
    final existingIndex = items.indexWhere((i) => i.productId == item.productId);
    
    if (existingIndex >= 0) {
      final currentQty = items[existingIndex].quantity;
      final newQty = currentQty + item.quantity;
      if (newQty > availableStock) {
        items[existingIndex] = items[existingIndex].copyWith(quantity: availableStock);
      } else {
        items[existingIndex] = items[existingIndex].copyWith(quantity: newQty);
      }
    } else {
      final qty = item.quantity > availableStock ? availableStock : item.quantity;
      items.add(item.copyWith(quantity: qty));
    }
    
    await _saveItems(items);
    _notifier.refresh();
  }

  Future<void> updateQuantity(int productId, int quantity, int availableStock) async {
    final items = await getCartItems();
    final index = items.indexWhere((i) => i.productId == productId);
    
    if (index >= 0) {
      if (quantity <= 0) {
        items.removeAt(index);
      } else {
        final cappedQty = quantity > availableStock ? availableStock : quantity;
        items[index] = items[index].copyWith(quantity: cappedQty);
      }
      await _saveItems(items);
      _notifier.refresh();
    }
  }

  Future<void> removeItem(int productId) async {
    final items = await getCartItems();
    items.removeWhere((i) => i.productId == productId);
    await _saveItems(items);
    _notifier.refresh();
  }

  Future<void> clearCart() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cartKey);
    _notifier.refresh();
  }

  Future<int> getItemCount() async {
    final items = await getCartItems();
    return items.fold<int>(0, (sum, item) => sum + item.quantity);
  }

  Future<double> getTotalPrice() async {
    final items = await getCartItems();
    return items.fold<double>(0.0, (sum, item) => sum + (item.price * item.quantity));
  }

  Future<void> _saveItems(List<CartItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final cartJson = jsonEncode(items.map((i) => i.toJson()).toList());
    await prefs.setString(_cartKey, cartJson);
  }
}