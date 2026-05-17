import 'dart:convert';
import 'package:http/http.dart' as http;

class MapCommerceModel {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double? distance;

  MapCommerceModel({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.distance,
  });

  factory MapCommerceModel.fromJson(Map<String, dynamic> json) {
    return MapCommerceModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      // Algunos parseos defensivos para asegurar que sean double
      latitude: double.tryParse(json['latitude']?.toString() ?? '0') ?? 0.0,
      longitude: double.tryParse(json['longitude']?.toString() ?? '0') ?? 0.0,
      distance: json['distance'] != null
          ? double.tryParse(json['distance'].toString())
          : null,
    );
  }
}

class MapApiService {
  static const String baseUrl =
      'https://reduccion-desperdicio-backend.vercel.app'; // URL Base consistente con auth_repository

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
