import 'dart:convert';
import 'package:flutter/foundation.dart' show ChangeNotifier, visibleForTesting;
import 'package:http/http.dart' as http;
import 'package:reduccion_desperdicio_alimentos/core/constants/api_constants.dart';
import 'package:reduccion_desperdicio_alimentos/features/home/data/models/product_model.dart';

/// Singleton ChangeNotifier que mantiene el estado global de los filtros.
class FilterStore extends ChangeNotifier {
  FilterStore._();
  static final FilterStore instance = FilterStore._();

  // ── Estado ─────────────────────────────────────────────────
  double _radius = 0.0; // 0 = sin límite
  CategoryModel? _selectedCategory;
  List<CategoryModel> _activeCategories = [];
  bool _loadingCategories = false;

  // ── Getters ─────────────────────────────────────────────────
  double get radius => _radius;
  CategoryModel? get selectedCategory => _selectedCategory;
  List<CategoryModel> get activeCategories => _activeCategories;
  bool get loadingCategories => _loadingCategories;

  /// Número de filtros activos (para el badge)
  int get activeCount {
    int count = 0;
    if (_radius > 0) count++;
    if (_selectedCategory != null) count++;
    return count;
  }

  bool get hasFilters => activeCount > 0;

  // ── Setters ─────────────────────────────────────────────────
  void setRadius(double value) {
    _radius = value;
    notifyListeners();
  }

  void setSelectedCategory(CategoryModel? category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void clearFilters() {
    _radius = 0.0;
    _selectedCategory = null;
    notifyListeners();
  }

  // ── Categoria query string para la API ────────────────────
  String? get categorySlug => _selectedCategory?.slug;

  // ── Carga de categorías activas ──────────────────────────
  /// Solo para pruebas: precarga categorías sin llamar a la API.
  @visibleForTesting
  void setActiveCategoriesForTest(List<CategoryModel> categories) {
    _activeCategories = categories;
    _loadingCategories = false;
    notifyListeners();
  }

  Future<void> fetchActiveCategories() async {
    if (_loadingCategories) return;
    _loadingCategories = true;

    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}/restaurants/categories');
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data;
        try {
          data = (jsonDecode(response.body) as List<dynamic>?) ?? [];
        } catch (_) {
          _activeCategories = [];
          return;
        }
        _activeCategories =
            data.map((j) => CategoryModel.fromJson(j as Map<String, dynamic>)).toList();
      }
    } catch (_) {
      // Error silencioso; la lista queda vacía y se puede reintentar
    } finally {
      _loadingCategories = false;
      notifyListeners();
    }
  }
}
