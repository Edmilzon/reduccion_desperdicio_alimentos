import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:reduccion_desperdicio_alimentos/core/constants/api_constants.dart';
import '../models/auth_model.dart';

class AuthRepository {
  static const String baseUrl = ApiConstants.baseUrl;
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'auth_user';
  static const String _commerceIdKey = 'commerce_id';
  static const String _commerceNameKey = 'commerce_name';

  Future<AuthResponse> login(String email, String password) async {
    final url = '$baseUrl/auth/login';
    // TODO: Remove debug logs after fixing 308 error
    assert(() {
      // ignore: avoid_print
      print('DEBUG LOGIN URL: $url');
      return true;
    }());
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );
    // TODO: Remove debug logs after fixing 308 error
    assert(() {
      // ignore: avoid_print
      print('DEBUG LOGIN RESPONSE status: ${response.statusCode}');
      print('DEBUG LOGIN RESPONSE headers: ${response.headers}');
      print('DEBUG LOGIN RESPONSE body: ${response.body}');
      return true;
    }());

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final authResponse = AuthResponse.fromJson(data);
      await _saveAuth(authResponse);
      if (authResponse.commerce != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_commerceIdKey, authResponse.commerce!.id);
      }
      await fetchProfile();
      return authResponse;
    } else {
      throw _parseError(response);
    }
  }

  Future<AuthResponse> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      final authResponse = AuthResponse.fromJson(data);
      await _saveAuth(authResponse);
      final user = await fetchProfile();
      if (user == null) {
        throw Exception('Error al obtener perfil');
      }
      return authResponse;
    } else {
      throw _parseError(response);
    }
  }

  Future<AuthResponse> registerCommerce({
    required String ownerName,
    required String email,
    required String password,
    required String commerceName,
    String? nit,
    String? description,
    double? latitude,
    double? longitude,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register-commerce'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'ownerName': ownerName,
        'email': email,
        'password': password,
        'commerceName': commerceName,
        if (nit != null && nit.isNotEmpty) 'nit': nit,
        if (description != null && description.isNotEmpty) 'description': description,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      }),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      final authResponse = AuthResponse.fromJson(data);
      await _saveAuth(authResponse);
      if (authResponse.commerce != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_commerceIdKey, authResponse.commerce!.id);
      }
      final user = await fetchProfile();
      if (user == null) {
        throw Exception('Error al obtener perfil');
      }
      return authResponse;
    } else {
      throw _parseError(response);
    }
  }

  Future<UserModel> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    if (userJson != null) {
      return UserModel.fromJson(jsonDecode(userJson));
    }
    throw Exception('No hay sesión activa');
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<UserModel?> fetchProfile() async {
    final token = await getToken();
    if (token == null) return null;

    final response = await http.get(
      Uri.parse('$baseUrl/auth/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final user = UserModel.fromJson(data['user']);
      if (user.isMerchant && data['commerce'] != null) {
        final prefs = await SharedPreferences.getInstance();
        final commerceId = data['commerce']['id']?.toString();
        if (commerceId != null) {
          await prefs.setString(_commerceIdKey, commerceId);
        }
        final commerceName = data['commerce']['name']?.toString();
        if (commerceName != null) {
          await prefs.setString(_commerceNameKey, commerceName);
        }
      }
      return user;
    }
    return null;
  }

  Future<void> logout() async {
    final token = await getToken();
    if (token != null) {
      try {
        await http.post(
          Uri.parse('$baseUrl/auth/logout'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
      } catch (_) {}
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    await prefs.remove(_commerceIdKey);
    await prefs.remove(_commerceNameKey);
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> _saveAuth(AuthResponse auth) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, auth.accessToken);
    await prefs.setString(_userKey, jsonEncode(auth.user.toJson()));
    if (auth.commerce != null) {
await prefs.setString(_commerceIdKey, auth.commerce!.id);
        await prefs.setString(_commerceNameKey, auth.commerce!.name);
      }
  }

  Future<String?> getCommerceId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_commerceIdKey);
  }

  Exception _parseError(http.Response response) {
    try {
      final data = jsonDecode(response.body);
      final message = data['message'] ?? 'Error desconocido';
      switch (response.statusCode) {
        case 301:
        case 308:
          return Exception('URL del backend incorrecta (redirect). Revisa api_constants.dart');
        case 401:
          return Exception('Credenciales inválidas');
        case 404:
          return Exception('Endpoint no encontrado. ¿Falta /api/ en la URL?');
        case 409:
          return Exception(message);
        case 500:
        case 502:
        case 503:
          return Exception('Error del servidor. Intenta más tarde.');
        default:
          return Exception(message);
      }
    } catch (_) {
      return Exception('Error de conexión (${response.statusCode})');
    }
  }
}

extension UserModelExtension on UserModel {
  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        'role': roleString,
        if (isMerchant) 'isMerchant': true,
      };
}