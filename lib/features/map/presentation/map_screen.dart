import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:reduccion_desperdicio_alimentos/core/services/location_service.dart';
import '../data/map_api_service.dart';
import 'widgets/commerce_bottom_sheet.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final LocationService _locationService = LocationService();
  final MapApiService _mapApiService = MapApiService();
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  List<MapCommerceModel> _commerces = [];
  LatLng _mapCenter = const LatLng(-17.423, -66.119);
  double _mapZoom = 11.0;
  LatLng? _currentLocation;

  @override
  void initState() {
    super.initState();
    _fetchAllCommerces();
    _tryFetchUserLocation();
  }

  @override
  void dispose() {
    _mapController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _tryFetchUserLocation() async {
    try {
      final position = await _locationService
          .getCurrentPosition()
          .timeout(const Duration(seconds: 8));
      if (!mounted) return;
      final userLoc = LatLng(position.latitude, position.longitude);
      setState(() => _currentLocation = userLoc);
      _mapController.move(userLoc, 15.0);
      setState(() {
        _mapCenter = userLoc;
        _mapZoom = 15.0;
      });
    } catch (_) {}
  }

  Future<void> _fetchAllCommerces() async {
    try {
      final results = await _mapApiService.getAllCommerces();
      if (!mounted) return;
      setState(() => _commerces = results);
    } catch (_) {}
  }

  Future<void> _searchByAddress(String address) async {
    if (address.trim().isEmpty) return;
    try {
      final results = await _mapApiService.getCommercesByAddress(address);
      if (!mounted) return;
      if (results.isNotEmpty) {
        final first = results.first;
        final center = LatLng(first.latitude, first.longitude);
        setState(() {
          _commerces = results;
          _mapCenter = center;
          _mapZoom = 14.0;
        });
        _safeMapMove(center, 14.0);
      } else {
        if (!mounted) return;
        setState(() => _commerces = results);
      }
    } catch (_) {}
  }

  void _safeMapMove(LatLng center, double zoom) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _mapController.move(center, zoom);
    });
  }

  List<Marker> _buildCommerceMarkers() {
    return _commerces.map((commerce) {
      return Marker(
        point: LatLng(commerce.latitude, commerce.longitude),
        width: 150,
        height: 90,
        child: GestureDetector(
          onTap: () => _showCommerceBottomSheet(commerce),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildMarkerLabel(commerce),
              const Icon(Icons.location_on, color: Colors.red, size: 32),
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _buildMarkerLabel(MapCommerceModel commerce) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.green, width: 1),
        boxShadow: const [
          BoxShadow(blurRadius: 4, color: Colors.black12, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            commerce.name,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 11,
              color: Colors.black87,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          if (commerce.branchName != null && commerce.branchName!.isNotEmpty)
            Text(
              commerce.branchName!,
              style: TextStyle(
                fontSize: 9,
                color: Colors.green[700],
                fontStyle: FontStyle.italic,
              ),
            ),
          if (commerce.distance != null)
            Text(
              '${commerce.distance!.toStringAsFixed(1)} km',
              style: const TextStyle(
                color: Colors.green,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }

  void _showCommerceBottomSheet(MapCommerceModel commerce) {
    _safeMapMove(LatLng(commerce.latitude, commerce.longitude), 16.0);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => CommerceBottomSheet(
        commerce: commerce,
        onViewOffers: () => _navigateToRestaurantDetail(commerce),
      ),
    );
  }

  void _navigateToRestaurantDetail(MapCommerceModel commerce) {
    final id = _parseCommerceId(commerce.restaurantId ?? commerce.id);
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: ID de restaurante inválido')),
      );
      return;
    }
    Navigator.pushNamed(
      context,
      '/restaurant-detail',
      arguments: {'commerceId': id},
    );
  }

  int? _parseCommerceId(String id) {
    final parsed = int.tryParse(id);
    if (parsed == null || parsed <= 0) return null;
    return parsed;
  }

  Widget _buildSearchBar() {
    return Positioned(
      top: 10,
      left: 10,
      right: 10,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar restaurante o dirección...',
                    border: InputBorder.none,
                    icon: const Icon(Icons.search),
                  ),
                  onSubmitted: _searchByAddress,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Restaurantes Cercanos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _tryFetchUserLocation,
            tooltip: 'Mi ubicación',
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            key: ValueKey('${_mapCenter.latitude},${_mapCenter.longitude},$_mapZoom'),
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _mapCenter,
              initialZoom: _mapZoom,
              onTap: (_, point) {
                _safeMapMove(point, 15.0);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.ecobocado',
              ),
              MarkerLayer(markers: _buildCommerceMarkers()),
              if (_currentLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _currentLocation!,
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.my_location, color: Colors.blue, size: 30),
                    ),
                  ],
                ),
            ],
          ),
          _buildSearchBar(),
        ],
      ),
    );
  }
}
