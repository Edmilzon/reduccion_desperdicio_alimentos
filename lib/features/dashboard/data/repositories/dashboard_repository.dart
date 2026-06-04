import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:reduccion_desperdicio_alimentos/core/constants/api_constants.dart';
import '../models/oferta_model.dart';
import '../../../home/data/models/product_model.dart';

class DashboardRepository {
  static const String baseUrl = ApiConstants.baseUrl;
  static const String _tokenKey = 'auth_token';
  static const String _commerceIdKey = 'commerce_id';

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<String?> _getCommerceId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_commerceIdKey);
  }

  Future<int> getCommerceIdInt() async {
    String? id = await _getCommerceId();
    id ??= await _fetchCommerceIdFromApi();
    if (id == null) throw Exception('No hay comercio asociado. Inicia sesión como comerciante.');
    final parsed = int.tryParse(id);
    if (parsed == null) throw Exception('ID de comercio inválido. Revisa SharedPreferences.');
    return parsed;
  }

  Map<String, dynamic>? _extractCommerce(Map<String, dynamic> data) {
    return data['commerce'] ?? data['user']?['commerce'];
  }

  Future<String?> _fetchCommerceIdFromApi({bool clearOnAuthError = true}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    if (token == null) return null;
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final commerce = _extractCommerce(data);
        if (commerce != null) {
          final id = commerce['id']?.toString();
          if (id != null) {
            await prefs.setString(_commerceIdKey, id);
          }
          return id;
        }
        if (data['user'] != null && data['user']['role'] != 'merchant') {
          throw Exception('No eres un comerciante');
        }
      }
      if (response.statusCode == 401 && clearOnAuthError) {
        await prefs.remove(_tokenKey);
        await prefs.remove(_commerceIdKey);
        throw Exception('Sesión expirada. Por favor inicia sesión de nuevo.');
      }
    } on http.ClientException {
      throw Exception('Error de conexión. Verifica tu internet.');
    } on FormatException {
      throw Exception('Error al procesar la respuesta del servidor.');
    }
    return null;
  }

  Future<List<CategoryModel>> getCategorias() async {
    final response = await http.get(
      Uri.parse('$baseUrl/products/categories'),
      headers: {'Content-Type': 'application/json'},
    ).timeout(const Duration(seconds: 15));

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
    
    String? commerceId = await _getCommerceId();
    commerceId ??= await _fetchCommerceIdFromApi(clearOnAuthError: false);
    if (commerceId == null) throw Exception('No hay comercio asociado. Inicia sesión como comerciante.');

    final response = await http.get(
      Uri.parse('$baseUrl/commerces/$commerceId/products'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> products = data['products'] ?? [];
      return products.map((json) => OfertaModel.fromJson(json)).toList();
    } else {
      throw Exception('Error al cargar ofertas');
    }
  }

  Future<Map<String, dynamic>> getDashboardStats(String commerceId) async {
    final token = await _getToken();
    if (token == null) throw Exception('No hay sesión');

    final response = await http.get(
      Uri.parse('$baseUrl/products/commerce/$commerceId/stats'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 15));

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
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return data['id'] ?? 0;
    } else {
      try {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Error al crear producto (${response.statusCode})');
      } catch (_) {
        throw Exception('Error al crear producto (${response.statusCode})');
      }
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
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200 && response.statusCode != 204) {
      final msg = _extractError(response);
      throw Exception(msg);
    }
  }

  String _extractError(http.Response response) {
    try {
      final data = jsonDecode(response.body);
      return data['message']?.toString() ?? 'Error desconocido (${response.statusCode})';
    } catch (_) {
      return 'Error del servidor (${response.statusCode})';
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
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200 && response.statusCode != 204) {
      final msg = _extractError(response);
      throw Exception(msg);
    }
  }
}