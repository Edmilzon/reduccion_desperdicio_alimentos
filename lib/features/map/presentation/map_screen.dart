import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/services/location_service.dart';
import '../../../core/theme/app_colors.dart';
import '../data/filter_store.dart';
import '../data/map_api_service.dart';
import 'widgets/filter_panel.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final LocationService _locationService = LocationService();
  final MapApiService _mapApiService = MapApiService();
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  final FilterStore _filters = FilterStore.instance;

  List<MapCommerceModel> _commerces = [];
  LatLng _mapCenter = const LatLng(-17.423, -66.119);
  double _mapZoom = 13.0;
  LatLng? _currentLocation;
  bool _isLoading = false;
  String? _errorMessage;
  bool _initialLocationError = false;

  @override
  void initState() {
    super.initState();
    _filters.addListener(_onFiltersChanged);
    if (_filters.activeCategories.isEmpty) {
      _filters.fetchActiveCategories();
    }
    _initLocation();
  }

  void _onFiltersChanged() {
    if (mounted) _fetchNearbyCommerces(_mapCenter);
  }

  void _safeMapMove(LatLng center, double zoom) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        _mapController.move(center, zoom);
      } catch (_) {
        setState(() {
          _mapCenter = center;
          _mapZoom = zoom;
        });
      }
    });
  }

  Future<void> _initLocation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _initialLocationError = false;
    });

    try {
      final position = await _locationService.getCurrentPosition();
      final currentLatLng = LatLng(position.latitude, position.longitude);
      
      setState(() {
        _currentLocation = currentLatLng;
        _mapCenter = currentLatLng;
        _mapZoom = 15.0;
      });

      _safeMapMove(currentLatLng, 15.0);
      await _fetchNearbyCommerces(currentLatLng);
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '');
      setState(() {
        _initialLocationError = true;
        _errorMessage = msg;
      });
      await _fetchNearbyCommerces(_mapCenter);
      if (mounted) _showErrorDialog(msg);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchNearbyCommerces(LatLng location) async {
    setState(() => _isLoading = true);
    try {
      final results = await _mapApiService.getNearbyCommerces(
        location.latitude,
        location.longitude,
        radiusKm: _filters.radius,
        category: _filters.categorySlug,
      );
      setState(() {
        _commerces = results;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar restaurantes cercanos.';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _searchByAddress(String address) async {
    if (address.trim().isEmpty) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final results = await _mapApiService.getCommercesByAddress(address);
      setState(() {
        _commerces = results;
      });
      
      if (results.isNotEmpty) {
        final first = results.first;
        final center = LatLng(first.latitude, first.longitude);
        setState(() {
          _mapCenter = center;
          _mapZoom = 14.0;
        });
        _safeMapMove(center, 14.0);
      } else {
        setState(() {
          _errorMessage = 'No se encontraron restaurantes cerca de esa dirección.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al buscar por dirección.';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Timer? _debounceTimer;

  void _debouncedFetch(LatLng center) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _fetchNearbyCommerces(center);
    });
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Aviso de Ubicación'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  void _showCommerceBottomSheet(MapCommerceModel commerce) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final bool isInactive = !commerce.hasActiveOffers;
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          commerce.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        if (commerce.branchName != null && commerce.branchName!.isNotEmpty)
                          Text(
                            commerce.branchName!,
                            style: TextStyle(color: Colors.green[700], fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                      ],
                    ),
                  ),
                  if (commerce.distance != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${commerce.distance!.toStringAsFixed(1)} km',
                        style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (commerce.description != null)
                Text(
                  commerce.description!,
                  style: TextStyle(color: Colors.grey[600]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Icon(Icons.access_time, size: 18, color: isInactive ? Colors.grey : Colors.orange),
                  const SizedBox(width: 8),
                  Text(
                    isInactive 
                      ? 'Sin ofertas activas en esta sede' 
                      : 'Recogida hasta: ${commerce.pickupLimit ?? "Sin definir"}',
                    style: TextStyle(
                      color: isInactive ? Colors.grey : Colors.black87,
                      fontWeight: isInactive ? FontWeight.normal : FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final restaurantId = int.tryParse(
                          commerce.restaurantId ?? commerce.id,
                        ) ??
                        0;
                    if (restaurantId <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Error: ID de restaurante inválido')),
                      );
                      return;
                    }
                    Navigator.pushNamed(
                      context,
                      '/restaurant-detail',
                      arguments: {'commerceId': restaurantId},
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: Colors.green,
                    disabledBackgroundColor: Colors.grey[300],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(
                    isInactive
                        ? 'VER LOCAL (SIN OFERTAS ACTIVAS)'
                        : 'VER OFERTAS DISPONIBLES',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _filters.removeListener(_onFiltersChanged);
    _debounceTimer?.cancel();
    _mapController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int filterCount = _filters.activeCount;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Restaurantes Cercanos'),
      ),
      body: Stack(
        children: [
          FlutterMap(
            key: ValueKey('${_mapCenter.latitude},${_mapCenter.longitude},$_mapZoom'),
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _mapCenter,
              initialZoom: _mapZoom,
              onTap: (tapPosition, point) {
                _fetchNearbyCommerces(point);
                _safeMapMove(point, 15.0);
              },
              onPositionChanged: (position, hasGesture) {
                if (hasGesture) {
                  _debouncedFetch(position.center);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.ecobocado',
              ),
              MarkerLayer(
                markers: _commerces.map((commerce) {
                  final bool isInactive = !commerce.hasActiveOffers;
                  return Marker(
                    point: LatLng(commerce.latitude, commerce.longitude),
                    width: 150,
                    height: 90,
                    child: GestureDetector(
                      onTap: () {
                        // Aquí se implementará el bottom sheet en la siguiente tarea
                        _showCommerceBottomSheet(commerce);
                      },
                      child: Opacity(
                        opacity: isInactive ? 0.6 : 1.0,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: isInactive ? Colors.grey[200] : Colors.white,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isInactive ? Colors.grey : Colors.green,
                                  width: 1,
                                ),
                                boxShadow: const [
                                  BoxShadow(blurRadius: 4, color: Colors.black12, offset: Offset(0, 2))
                                ]
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    commerce.name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold, 
                                      fontSize: 11,
                                      color: isInactive ? Colors.grey[700] : Colors.black87,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (commerce.branchName != null && commerce.branchName!.isNotEmpty)
                                    Text(
                                      commerce.branchName!,
                                      style: TextStyle(
                                        fontSize: 9, 
                                        color: isInactive ? Colors.grey : Colors.green[700],
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  if (commerce.distance != null)
                                    Text(
                                      '${commerce.distance!.toStringAsFixed(1)} km',
                                      style: TextStyle(
                                        color: isInactive ? Colors.grey : Colors.green, 
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.location_on,
                              color: isInactive ? Colors.grey : Colors.red,
                              size: 32,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              if (_currentLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _currentLocation!,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.my_location,
                        color: Colors.blue,
                        size: 30,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          
          // Barra de Búsqueda
          Positioned(
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
                          hintText: _initialLocationError 
                            ? 'Ingresa tu dirección manualmente' 
                            : 'Buscar restaurante o dirección...',
                          border: InputBorder.none,
                          icon: const Icon(Icons.search),
                        ),
                        onSubmitted: (value) => _searchByAddress(value),
                      ),
                    ),
                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          
          // Mensajes de error en la UI
          if (_errorMessage != null)
            Positioned(
              bottom: 80,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // FAB Filtros
          FloatingActionButton(
            heroTag: 'filter_fab',
            onPressed: () async {
              final applied = await showFilterPanel(context);
              if (applied == true && mounted) {
                _fetchNearbyCommerces(_currentLocation ?? _mapCenter);
              }
            },
            backgroundColor:
                filterCount > 0 ? AppColors.primary : Colors.white,
            foregroundColor:
                filterCount > 0 ? Colors.white : AppColors.primary,
            tooltip: 'Filtros',
            child: Badge(
              isLabelVisible: filterCount > 0,
              label: Text('$filterCount'),
              backgroundColor: Colors.white,
              textColor: AppColors.primary,
              child: const Icon(Icons.tune),
            ),
          ),
          const SizedBox(height: 12),
          // FAB Mi ubicación
          FloatingActionButton(
            heroTag: 'location_fab',
            onPressed: _initLocation,
            tooltip: 'Mi ubicación',
            child: const Icon(Icons.my_location),
          ),
        ],
      ),
    );
  }
}
