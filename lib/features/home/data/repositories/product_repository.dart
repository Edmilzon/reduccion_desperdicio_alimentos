import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product_model.dart';

class ProductRepository {
  static const String baseUrl =
      'http://192.168.0.14:5000';

  Future<List<ProductModel>> getAllProducts() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/products/all'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => ProductModel.fromJson(json)).toList();
      } else {
        throw Exception('Error al cargar productos: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<List<CategoryModel>> getCategories() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/products/categories'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => CategoryModel.fromJson(json)).toList();
      } else {
        throw Exception('Error al cargar categorías: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<List<ProductModel>> searchProducts(String query) async {
    if (query.isEmpty) return [];
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/products/search?q=$query'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => ProductModel.fromJson(json)).toList();
      } else {
        throw Exception('Error en búsqueda: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<List<ProductModel>> getProductsWithFilters({
    int? categoryId,
    int? commerceId,
  }) async {
    final queryParams = <String>[];
    if (categoryId != null) queryParams.add('categoryId=$categoryId');
    if (commerceId != null) queryParams.add('commerceId=$commerceId');

    final url = queryParams.isNotEmpty
        ? '$baseUrl/products?${queryParams.join('&')}'
        : '$baseUrl/products';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => ProductModel.fromJson(json)).toList();
      } else {
        throw Exception('Error al cargar productos: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<List<ProductModel>> getProductsByCommerce(
    int commerceId, {
    String? status,
    int? categoryId,
  }) async {
    final queryParams = <String>[];
    if (status != null) queryParams.add('status=$status');
    if (categoryId != null) queryParams.add('categoryId=$categoryId');

    final url = queryParams.isNotEmpty
        ? '$baseUrl/products/commerce/$commerceId?${queryParams.join('&')}'
        : '$baseUrl/products/commerce/$commerceId';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => ProductModel.fromJson(json)).toList();
      } else {
        throw Exception('Error al cargar productos: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<List<CommerceModel>> getCommerces() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/commerces'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => CommerceModel.fromJson(json)).toList();
      } else {
        throw Exception('Error al cargar comercios: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<ProductModel> getProductById(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/products/$id'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return ProductModel.fromJson(json.decode(response.body));
      } else {
        throw Exception('Error al cargar producto: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }
}