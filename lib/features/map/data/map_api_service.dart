import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:reduccion_desperdicio_alimentos/core/constants/api_constants.dart';

class MapCommerceModel {
  final String id;
  final String? restaurantId;
  final String name;
  final String? branchName;
  final double latitude;
  final double longitude;
  final double? distance;
  final String? imageUrl;
  final int availableOffers;
  final bool hasActiveOffers;
  final String? pickupLimit;
  final String? description;
  final String? ownerEmail;

  MapCommerceModel({
    required this.id,
    this.restaurantId,
    required this.name,
    this.branchName,
    required this.latitude,
    required this.longitude,
    this.distance,
    this.imageUrl,
    this.availableOffers = 0,
    this.hasActiveOffers = false,
    this.pickupLimit,
    this.description,
    this.ownerEmail,
  });

  factory MapCommerceModel.fromJson(Map<String, dynamic> json) {
    final owner = json['owner'] as Map<String, dynamic>?;
    return MapCommerceModel(
      id: json['id']?.toString() ?? '',
      restaurantId: json['restaurantId']?.toString(),
      name: json['name'] ?? '',
      branchName: json['branchName'] ?? '',
      latitude: double.tryParse(json['latitude']?.toString() ?? '0') ?? 0.0,
      longitude: double.tryParse(json['longitude']?.toString() ?? '0') ?? 0.0,
      distance: json['distance'] != null
          ? double.tryParse(json['distance'].toString())
          : null,
      imageUrl: json['imageUrl']?.toString(),
      availableOffers:
          int.tryParse(json['availableOffers']?.toString() ?? '0') ?? 0,
      hasActiveOffers: json['hasActiveOffers'] ?? false,
      pickupLimit: json['pickupLimit']?.toString(),
      description: json['description']?.toString(),
      ownerEmail: owner?['email']?.toString(),
    );
  }
}

class MapApiService {
  static const String baseUrl = ApiConstants.baseUrl;

  static List<MapCommerceModel>? _cachedCommerces;

  static List<MapCommerceModel>? get cachedCommerces => _cachedCommerces;

  Future<List<MapCommerceModel>> getAllCommerces() async {
    final uri = Uri.parse('$baseUrl/commerces');
    final response = await http
        .get(uri)
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final List<dynamic> data;
      try {
        data = (jsonDecode(response.body) as List<dynamic>?) ?? [];
      } catch (_) {
        throw Exception('Error al procesar la respuesta del servidor');
      }
      return data.map((json) => MapCommerceModel.fromJson(json as Map<String, dynamic>)).toList();
    } else {
      throw Exception(
        'Error al obtener comercios (${response.statusCode})',
      );
    }
  }

  Future<List<MapCommerceModel>> getCommercesByAddress(
    String address, {
    double radiusKm = 0,
  }) async {
    final params = StringBuffer();
    params.write('address=${Uri.encodeComponent(address)}');
    if (radiusKm > 0) {
      params.write('&radius=$radiusKm');
    }
    final uri = Uri.parse('$baseUrl/commerces/by-address?$params');
    final response = await http
        .get(uri)
        .timeout(const Duration(seconds: 20));

    if (response.statusCode == 200) {
      final List<dynamic> data;
      try {
        data = (jsonDecode(response.body) as List<dynamic>?) ?? [];
      } catch (_) {
        throw Exception('Error al procesar la respuesta del servidor');
      }
      return data.map((json) => MapCommerceModel.fromJson(json as Map<String, dynamic>)).toList();
    } else {
      throw Exception(
        'Error al obtener comercios por dirección (${response.statusCode})',
      );
    }
  }

  static void clearCache() {
    _cachedCommerces = null;
  }
}
