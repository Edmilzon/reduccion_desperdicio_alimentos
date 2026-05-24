import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesRepository {
  static const String _key = 'favorite_products';

  static final _FavoritesNotifier _notifier = _FavoritesNotifier();
  static _FavoritesNotifier get notifier => _notifier;

  Future<Set<int>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_key);
    if (data == null) return {};
    final list = jsonDecode(data) as List<dynamic>;
    return list.map((e) => e as int).toSet();
  }

  Future<bool> isFavorite(int productId) async {
    final favorites = await getFavorites();
    return favorites.contains(productId);
  }

  Future<void> addFavorite(int productId) async {
    final favorites = await getFavorites();
    favorites.add(productId);
    await _save(favorites);
    _notifier.refresh();
  }

  Future<void> removeFavorite(int productId) async {
    final favorites = await getFavorites();
    favorites.remove(productId);
    await _save(favorites);
    _notifier.refresh();
  }

  Future<void> toggleFavorite(int productId) async {
    final favorites = await getFavorites();
    if (favorites.contains(productId)) {
      favorites.remove(productId);
    } else {
      favorites.add(productId);
    }
    await _save(favorites);
    _notifier.refresh();
  }

  Future<void> _save(Set<int> favorites) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(favorites.toList()));
  }
}

class _FavoritesNotifier extends ChangeNotifier {
  void refresh() => notifyListeners();
}
