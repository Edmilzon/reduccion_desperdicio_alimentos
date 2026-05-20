import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CartItem {
  final int productId;
  final String title;
  final double price;
  final String imageUrl;
  final int quantity;
  final int? commerceId;
  final String? commerceName;

  CartItem({
    required this.productId,
    required this.title,
    required this.price,
    required this.imageUrl,
    required this.quantity,
    this.commerceId,
    this.commerceName,
  });

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'title': title,
    'price': price,
    'imageUrl': imageUrl,
    'quantity': quantity,
    'commerceId': commerceId,
    'commerceName': commerceName,
  };

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
    productId: json['productId'] ?? 0,
    title: json['title'] ?? '',
    price: (json['price'] ?? 0).toDouble(),
    imageUrl: json['imageUrl'] ?? '',
    quantity: json['quantity'] ?? 1,
    commerceId: json['commerceId'],
    commerceName: json['commerceName'],
  );

  CartItem copyWith({int? quantity}) => CartItem(
    productId: productId,
    title: title,
    price: price,
    imageUrl: imageUrl,
    quantity: quantity ?? this.quantity,
    commerceId: commerceId,
    commerceName: commerceName,
  );
}

class CartRepository {
  static const String _cartKey = 'cart_items';
  
  Future<List<CartItem>> getCartItems() async {
    final prefs = await SharedPreferences.getInstance();
    final cartJson = prefs.getString(_cartKey);
    if (cartJson == null) return [];
    
    final List<dynamic> cartList = jsonDecode(cartJson);
    return cartList.map((item) => CartItem.fromJson(item)).toList();
  }

  Future<void> addItem(CartItem item) async {
    final items = await getCartItems();
    final existingIndex = items.indexWhere((i) => i.productId == item.productId);
    
    if (existingIndex >= 0) {
      items[existingIndex] = items[existingIndex].copyWith(
        quantity: items[existingIndex].quantity + item.quantity,
      );
    } else {
      items.add(item);
    }
    
    await _saveItems(items);
  }

  Future<void> updateQuantity(int productId, int quantity) async {
    final items = await getCartItems();
    final index = items.indexWhere((i) => i.productId == productId);
    
    if (index >= 0) {
      if (quantity <= 0) {
        items.removeAt(index);
      } else {
        items[index] = items[index].copyWith(quantity: quantity);
      }
      await _saveItems(items);
    }
  }

  Future<void> removeItem(int productId) async {
    final items = await getCartItems();
    items.removeWhere((i) => i.productId == productId);
    await _saveItems(items);
  }

  Future<void> clearCart() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cartKey);
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