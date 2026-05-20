import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/services/location_service.dart';
import '../data/map_api_service.dart';

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

  List<MapCommerceModel> _commerces = [];
  LatLng? _currentLocation;
  bool _isLoading = false;
  String? _errorMessage;
  bool _permissionDenied = false;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _permissionDenied = false;
    });

    try {
      final position = await _locationService.getCurrentPosition();
      final currentLatLng = LatLng(position.latitude, position.longitude);
      
      setState(() {
        _currentLocation = currentLatLng;
      });
      
      _mapController.move(currentLatLng, 15.0);
      await _fetchNearbyCommerces(currentLatLng);
    } catch (e) {
      setState(() {
        _permissionDenied = true;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
      _showErrorDialog(_errorMessage!);
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
          location.latitude, location.longitude);
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
        // Mover el mapa al primer resultado
        final first = results.first;
        _mapController.move(LatLng(first.latitude, first.longitude), 14.0);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Restaurantes Cercanos'),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation ?? const LatLng(-16.5, -68.15), // Centro por defecto (ej. La Paz)
              initialZoom: 13.0,
              onTap: (tapPosition, point) {
                // Al tocar el mapa, buscar por esa ubicación (Opcional según la HU)
                _fetchNearbyCommerces(point);
                _mapController.move(point, 15.0);
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
                          hintText: _permissionDenied 
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
          if (_errorMessage != null && !_permissionDenied)
            Positioned(
              bottom: 80,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.9),
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
      floatingActionButton: FloatingActionButton(
        onPressed: _initLocation,
        child: const Icon(Icons.my_location),
        tooltip: 'Mi ubicación',
      ),
    );
  }
}
