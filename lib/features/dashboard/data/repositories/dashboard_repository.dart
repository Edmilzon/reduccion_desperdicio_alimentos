import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/oferta_model.dart';

class DashboardRepository {
  static const String baseUrl =
      'https://reduccion-desperdicio-backend.vercel.app';
  static const String _tokenKey = 'auth_token';

  Future<List<CategoryModel>> getCategorias() async {
    final response = await http.get(
      Uri.parse('$baseUrl/products/categories'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => CategoryModel.fromJson(json)).toList();
    } else {
      throw Exception('Error al cargar categorías');
    }
  }

  Future<List<OfertaModel>> getMisOfertas() async {
    final token = await _getToken();
    if (token == null) throw Exception('No hay sesión');

    final response = await http.get(
      Uri.parse('$baseUrl/products/all'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => OfertaModel.fromJson(json)).toList();
    } else {
      throw Exception('Error al cargar ofertas');
    }
  }

  Future<Map<String, dynamic>> getDashboardStats(String commerceId) async {
    final token = await _getToken();
    if (token == null) throw Exception('No hay sesión');

    final response = await http.get(
      Uri.parse('$baseUrl/dashboard/commerce/$commerceId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al cargar estadísticas');
    }
  }

  Future<int> createProduct({
    required String title,
    required String description,
    required double originalPrice,
    required double price,
    required int quantity,
    required DateTime pickupStart,
    required DateTime pickupEnd,
    required int commerceId,
    required int categoryId,
    String? imageUrl,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception('No hay sesión');

    final response = await http.post(
      Uri.parse('$baseUrl/products'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'title': title,
        'description': description,
        'originalPrice': originalPrice,
        'price': price,
        'quantity': quantity,
        'pickupStart': pickupStart.toUtc().toIso8601String(),
        'pickupEnd': pickupEnd.toUtc().toIso8601String(),
        'commerceId': commerceId,
        'categoryId': categoryId,
        if (imageUrl != null) 'imageUrl': imageUrl,
      }),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return data['id'] ?? 0;
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Error al crear producto');
    }
  }

  Future<void> updateProduct(int id, Map<String, dynamic> productData) async {
    final token = await _getToken();
    if (token == null) throw Exception('No hay sesión');

    final response = await http.patch(
      Uri.parse('$baseUrl/products/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(productData),
    );

    if (response.statusCode != 200) {
      throw Exception('Error al actualizar producto');
    }
  }

  Future<void> deleteProduct(int id) async {
    final token = await _getToken();
    if (token == null) throw Exception('No hay sesión');

    final response = await http.delete(
      Uri.parse('$baseUrl/products/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Error al eliminar producto');
    }
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }
}

class CategoryModel {
  final int id;
  final String name;
  final String slug;
  final String? imageUrl;

  CategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    this.imageUrl,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      imageUrl: json['imageUrl'],
    );
  }
}