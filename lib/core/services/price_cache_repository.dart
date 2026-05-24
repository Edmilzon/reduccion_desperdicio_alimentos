import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PriceCacheRepository {
  static const String _key = 'price_cache';

  Future<Map<String, double>> _getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_key);
    if (data == null) return {};
    final decoded = jsonDecode(data) as Map<String, dynamic>;
    return decoded.map((k, v) => MapEntry(k, (v as num).toDouble()));
  }

  Future<double?> getLastPrice(int productId) async {
    final cache = await _getAll();
    return cache[productId.toString()];
  }

  Future<bool> hasPriceDropped(int productId, double currentPrice) async {
    final lastPrice = await getLastPrice(productId);
    if (lastPrice == null) return false;
    return currentPrice < lastPrice;
  }

  Future<void> updatePrice(int productId, double price) async {
    final cache = await _getAll();
    cache[productId.toString()] = price;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(cache));
  }
}
