import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/restaurant_detail_model.dart';

class RestaurantDetailRepository {
  static const String _baseUrl =
      'https://reduccion-desperdicio-backend.vercel.app';
  static const String _tokenKey = 'auth_token';

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<RestaurantDetailModel> getRestaurantDetail(int commerceId) async {
    final token = await _getToken();
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    final response = await http.get(
      Uri.parse('$_baseUrl/commerces/$commerceId'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return RestaurantDetailModel.fromJson(data);
    } else {
      throw Exception(
        'Error al cargar el restaurante: ${response.statusCode}',
      );
    }
  }
}
