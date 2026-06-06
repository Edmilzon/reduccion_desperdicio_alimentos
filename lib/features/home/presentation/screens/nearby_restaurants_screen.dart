import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:reduccion_desperdicio_alimentos/core/services/location_service.dart';
import 'package:reduccion_desperdicio_alimentos/core/theme/app_colors.dart';
import 'package:reduccion_desperdicio_alimentos/features/map/data/map_api_service.dart';
import 'package:reduccion_desperdicio_alimentos/features/map/presentation/map_screen.dart';
import 'package:reduccion_desperdicio_alimentos/features/restaurant_detail/data/models/restaurant_detail_model.dart';
import 'package:reduccion_desperdicio_alimentos/features/restaurant_detail/data/repositories/restaurant_detail_repository.dart';
import 'package:reduccion_desperdicio_alimentos/features/restaurant_detail/presentation/screens/restaurant_detail_screen.dart';
import 'package:reduccion_desperdicio_alimentos/features/restaurant_detail/presentation/widgets/offer_card.dart';
import '../screens/product_detail_screen.dart';
import '../widgets/nearby_restaurant_card.dart';

class NearbyRestaurantsScreen extends StatefulWidget {
  final bool embedded;
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
  final RestaurantDetailRepository _detailRepo = RestaurantDetailRepository();
  final MapController _mapController = MapController();

  bool _isLoadingList = false;
  List<MapCommerceModel> _commerces = [];
  LatLng _mapCenter = const LatLng(-17.423, -66.119);
  double _mapZoom = 11.0;
  LatLng? _userLocation;
  bool _hasLoadedOnce = false;

  MapCommerceModel? _selectedCommerce;
  List<RestaurantOfferModel> _selectedProducts = [];
  bool _isLoadingProducts = false;

  double get _mapHeight => widget.embedded ? 150.0 : 220.0;

  int? _parseCommerceId(String id) {
    final parsed = int.tryParse(id);
    if (parsed == null || parsed <= 0) return null;
    return parsed;
  }

  void _openRestaurantDetail(MapCommerceModel commerce) {
    final id = _parseCommerceId(commerce.restaurantId ?? commerce.id);
    if (id == null) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(content: Text('Error: ID de restaurante inválido')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RestaurantDetailScreen(commerceId: id),
      ),
    );
  }

  void _selectCommerce(MapCommerceModel commerce) {
    final id = _parseCommerceId(commerce.restaurantId ?? commerce.id);
    if (id == null) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(content: Text('Error: ID de restaurante inválido')),
      );
      return;
    }
    _mapController.move(LatLng(commerce.latitude, commerce.longitude), 16.0);
    setState(() {
      _selectedCommerce = commerce;
      _selectedProducts = [];
      _isLoadingProducts = true;
    });
    _loadProducts(id);
  }

  Future<void> _loadProducts(int commerceId) async {
    try {
      final detail = await _detailRepo.getRestaurantDetail(commerceId);
      if (mounted) {
        setState(() {
          _selectedProducts = detail.offers.where((o) => o.isAvailable).toList();
          _isLoadingProducts = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingProducts = false);
      }
    }
  }

  void _clearSelection() {
    setState(() {
      _selectedCommerce = null;
      _selectedProducts = [];
    });
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
    if (!_hasLoadedOnce && !widget.isTabActive) return;

    _clearSelection();

    if (refresh) {
      setState(() => _isLoadingList = true);
    }

    try {
      final commerces = await _mapApiService.getAllCommerces();

      if (!mounted) return;

      setState(() {
        _commerces = commerces;
        _hasLoadedOnce = true;
      });

      if (commerces.isNotEmpty) {
        _fitAllMarkers();
      }

      _tryFetchUserLocation();
    } catch (_) {
      if (!mounted) return;
      setState(() => _hasLoadedOnce = true);
    } finally {
      if (mounted) setState(() => _isLoadingList = false);
    }
  }

  Future<void> _tryFetchUserLocation() async {
    try {
      final position = await _locationService
          .getCurrentPosition()
          .timeout(const Duration(seconds: 8));
      if (!mounted) return;
      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
      });
    } catch (_) {}
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
              return Marker(
                point: LatLng(commerce.latitude, commerce.longitude),
                width: widget.embedded ? 28 : 36,
                height: widget.embedded ? 28 : 36,
                alignment: Alignment.center,
                child: GestureDetector(
                  onTap: () => _selectCommerce(commerce),
                  child: Icon(
                    Icons.location_on,
                    color: Colors.red,
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
                  : 'Todos los locales',
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
    if (widget.isTabActive) {
      _loadNearbyCommerces();
    }
  }

  @override
  void didUpdateWidget(NearbyRestaurantsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isTabActive && !oldWidget.isTabActive) {
      _loadNearbyCommerces();
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => _loadNearbyCommerces(refresh: true),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _buildMapSection()),
              if (_selectedCommerce != null) ...[
                SliverToBoxAdapter(child: _buildSelectedHeader()),
                ..._buildProductSlivers(),
              ],
              if (_selectedCommerce == null) ...[
                SliverToBoxAdapter(child: _buildSectionHeader()),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => NearbyRestaurantCard(
                      commerce: _commerces[index],
                      onTap: () => _selectCommerce(_commerces[index]),
                    ),
                    childCount: _commerces.length,
                  ),
                ),
              ],
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

  Widget _buildSelectedHeader() {
    return Container(
      color: AppColors.cardBg,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: _clearSelection,
            child: const Icon(Icons.arrow_back, size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedCommerce?.name ?? '',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (_selectedProducts.isNotEmpty)
                  Text(
                    '${_selectedProducts.length} producto${_selectedProducts.length > 1 ? 's' : ''} disponible${_selectedProducts.length > 1 ? 's' : ''}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _openRestaurantDetail(_selectedCommerce!),
            child: const Text('Ver todo', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildProductSlivers() {
    if (_isLoadingProducts) {
      return [
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          ),
        ),
      ];
    }
    if (_selectedProducts.isEmpty) {
      return [SliverToBoxAdapter(child: _buildNoProducts())];
    }
    return [
      SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProductDetailScreen(
                    productId: _selectedProducts[index].id,
                  ),
                ),
              ),
              child: OfferCard(offer: _selectedProducts[index]),
            ),
          ),
          childCount: _selectedProducts.length,
        ),
      ),
    ];
  }

  Widget _buildNoProducts() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(Icons.no_food, size: 48, color: AppColors.textLight),
          const SizedBox(height: 12),
          const Text(
            'Sin productos disponibles',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _selectedCommerce?.name != null
                ? '${_selectedCommerce!.name} no tiene ofertas activas en este momento'
                : 'No hay ofertas disponibles en este momento',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
