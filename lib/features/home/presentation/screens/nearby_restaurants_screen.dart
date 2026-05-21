import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:reduccion_desperdicio_alimentos/core/services/location_service.dart';
import 'package:reduccion_desperdicio_alimentos/core/theme/app_colors.dart';
import 'package:reduccion_desperdicio_alimentos/features/map/data/map_api_service.dart';
import 'package:reduccion_desperdicio_alimentos/features/map/presentation/map_screen.dart';
import 'package:reduccion_desperdicio_alimentos/features/restaurant_detail/presentation/screens/restaurant_detail_screen.dart';
import '../widgets/nearby_restaurant_card.dart';

class NearbyRestaurantsScreen extends StatefulWidget {
  /// Dentro de Tienda → Cercanos: layout compacto sin desbordar.
  final bool embedded;

  /// Pestaña Mapa del menú inferior: carga al activarse.
  final bool isTabActive;

  const NearbyRestaurantsScreen({
    super.key,
    this.embedded = false,
    this.isTabActive = true,
  });

  @override
  State<NearbyRestaurantsScreen> createState() =>
      _NearbyRestaurantsScreenState();
}

class _NearbyRestaurantsScreenState extends State<NearbyRestaurantsScreen> {
  final LocationService _locationService = LocationService();
  final MapApiService _mapApiService = MapApiService();
  final MapController _mapController = MapController();

  bool _isLoading = false;
  bool _isLoadingList = false;
  String? _error;
  List<MapCommerceModel> _commerces = [];
  LatLng _mapCenter = const LatLng(-17.423, -66.119);
  double _mapZoom = 12.0;
  LatLng? _userLocation;
  bool _hasLoadedOnce = false;

  double get _mapHeight => widget.embedded ? 150.0 : 220.0;

  int _commerceRestaurantId(MapCommerceModel commerce) {
    return int.tryParse(commerce.restaurantId ?? commerce.id) ?? 0;
  }

  void _openRestaurantDetail(MapCommerceModel commerce) {
    final id = _commerceRestaurantId(commerce);
    if (id <= 0) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RestaurantDetailScreen(commerceId: id),
      ),
    );
  }

  void _applyCachedData() {
    final cached = MapApiService.cachedCommerces;
    if (cached == null || cached.isEmpty) return;
    setState(() {
      _commerces = cached;
      _isLoading = false;
      _mapCenter = LatLng(cached.first.latitude, cached.first.longitude);
      _mapZoom = 12.0;
    });
    if (!widget.embedded) _fitAllMarkers();
  }

  void _fitAllMarkers() {
    if (_commerces.isEmpty || widget.embedded) return;

    final points = <LatLng>[
      for (final c in _commerces) LatLng(c.latitude, c.longitude),
      if (_userLocation != null) _userLocation!,
    ];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || points.isEmpty) return;
      try {
        _mapController.fitCamera(
          CameraFit.bounds(
            bounds: LatLngBounds.fromPoints(points),
            padding: const EdgeInsets.all(40),
          ),
        );
      } catch (_) {}
    });
  }

  Future<void> _loadNearbyCommerces({bool refresh = false}) async {
    if (refresh) {
      setState(() => _isLoadingList = true);
    } else {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    double lat = _mapCenter.latitude;
    double lng = _mapCenter.longitude;
    String? locationWarning;

    try {
      final position = await _locationService
          .getCurrentPosition()
          .timeout(const Duration(seconds: 8));
      lat = position.latitude;
      lng = position.longitude;
      _userLocation = LatLng(lat, lng);
      _mapCenter = _userLocation!;
      _mapZoom = 13.0;
    } catch (e) {
      locationWarning = e.toString().replaceAll('Exception: ', '');
    }

    try {
      final commerces = await _mapApiService.getNearbyCommerces(lat, lng);

      if (!mounted) return;

      setState(() {
        _commerces = commerces;
        _hasLoadedOnce = true;
        if (commerces.isNotEmpty) {
          _mapCenter =
              LatLng(commerces.first.latitude, commerces.first.longitude);
          _mapZoom = 12.0;
        }
        _error = commerces.isEmpty
            ? (locationWarning ??
                'No hay locales registrados. Verifica que el servidor esté activo.')
            : locationWarning;
      });

      _fitAllMarkers();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _hasLoadedOnce = true;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingList = false;
        });
      }
    }
  }

  Widget _buildMapSection() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        widget.embedded ? 12 : 0,
        widget.embedded ? 8 : 0,
        widget.embedded ? 12 : 0,
        0,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.embedded ? 12 : 0),
        child: SizedBox(
          height: _mapHeight,
          child: Stack(
            clipBehavior: Clip.hardEdge,
            fit: StackFit.expand,
            children: [
              _buildMap(),
              if (_isLoading)
                Container(
                  color: Colors.white.withValues(alpha: 0.7),
                  child: const Center(
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                ),
              Positioned(
                top: 6,
                right: 6,
                child: Material(
                  color: Colors.white,
                  elevation: 2,
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MapScreen(),
                        ),
                      );
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(Icons.fullscreen, size: 18),
                    ),
                  ),
                ),
              ),
              if (_commerces.isNotEmpty && !widget.embedded)
                Positioned(
                  bottom: 6,
                  left: 6,
                  child: Material(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      child: Text(
                        '${_commerces.length} locales',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _mapCenter,
        initialZoom: _mapZoom,
        interactionOptions: InteractionOptions(
          flags: widget.embedded
              ? InteractiveFlag.pinchZoom | InteractiveFlag.drag
              : InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.ecobocado',
        ),
        if (_commerces.isNotEmpty)
          MarkerLayer(
            markers: _commerces.map((commerce) {
              final inactive = !commerce.hasActiveOffers;
              return Marker(
                point: LatLng(commerce.latitude, commerce.longitude),
                width: widget.embedded ? 28 : 36,
                height: widget.embedded ? 28 : 36,
                alignment: Alignment.center,
                child: GestureDetector(
                  onTap: () => _openRestaurantDetail(commerce),
                  child: Icon(
                    Icons.location_on,
                    color: inactive ? Colors.grey : Colors.red,
                    size: widget.embedded ? 26 : 32,
                  ),
                ),
              );
            }).toList(),
          ),
        if (_userLocation != null)
          MarkerLayer(
            markers: [
              Marker(
                point: _userLocation!,
                width: 24,
                height: 24,
                child: const Icon(
                  Icons.my_location,
                  color: Colors.blue,
                  size: 22,
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildSectionHeader() {
    return Container(
      color: AppColors.cardBg,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              widget.embedded
                  ? 'Locales cercanos'
                  : 'Todos los locales (más cercanos primero)',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (_commerces.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('${_commerces.length}'),
            ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _applyCachedData();
    if (widget.isTabActive) {
      _loadNearbyCommerces();
    }
  }

  @override
  void didUpdateWidget(NearbyRestaurantsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isTabActive && !oldWidget.isTabActive) {
      _applyCachedData();
      if (_commerces.isEmpty) {
        _loadNearbyCommerces();
      } else {
        _fitAllMarkers();
      }
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _commerces.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.primary),
              SizedBox(height: 12),
              Text(
                'Cargando locales...',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    if (!_hasLoadedOnce && !widget.isTabActive && _commerces.isEmpty) {
      return const Center(
        child: Text(
          'Abre esta pestaña para ver el mapa',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    if (_commerces.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.store_outlined,
                  size: 48, color: AppColors.textSecondary),
              const SizedBox(height: 12),
              Text(
                _error ?? 'No se encontraron locales',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadNearbyCommerces,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => _loadNearbyCommerces(refresh: true),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _buildMapSection()),
              if (_error != null && !_isLoading)
                SliverToBoxAdapter(
                  child: Container(
                    width: double.infinity,
                    color: Colors.orange.shade50,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Text(
                      _error!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade900,
                      ),
                    ),
                  ),
                ),
              SliverToBoxAdapter(child: _buildSectionHeader()),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => NearbyRestaurantCard(
                    commerce: _commerces[index],
                    onTap: () => _openRestaurantDetail(_commerces[index]),
                  ),
                  childCount: _commerces.length,
                ),
              ),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Center(
                    child: Text(
                      'Ordenado de menor a mayor distancia',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_isLoadingList)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(color: AppColors.primary),
          ),
      ],
    );
  }
}
