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
  });

  factory MapCommerceModel.fromJson(Map<String, dynamic> json) {
    return MapCommerceModel(
      id: json['id']?.toString() ?? '',
      restaurantId: json['restaurantId']?.toString(),
      name: json['name'] ?? '',
      branchName: json['branchName'] ?? '',
      // Algunos parseos defensivos para asegurar que sean double
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
    );
  }
}

class MapApiService {
  static const String baseUrl = ApiConstants.baseUrl;

  Future<List<MapCommerceModel>> getNearbyCommerces(
      double lat, double lng) async {
    final uri = Uri.parse('$baseUrl/commerces/nearby?lat=$lat&lng=$lng');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => MapCommerceModel.fromJson(json)).toList();
    } else {
      throw Exception('Error al obtener comercios cercanos');
    }
  }

  Future<List<MapCommerceModel>> getCommercesByAddress(String address) async {
    final uri = Uri.parse(
        '$baseUrl/commerces/by-address?address=${Uri.encodeComponent(address)}');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => MapCommerceModel.fromJson(json)).toList();
    } else {
      throw Exception('Error al obtener comercios por dirección');
    }
  }
}
