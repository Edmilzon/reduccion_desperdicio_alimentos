import 'package:flutter/material.dart';
import 'package:reduccion_desperdicio_alimentos/core/services/location_service.dart';
import 'package:reduccion_desperdicio_alimentos/core/theme/app_colors.dart';
import 'package:reduccion_desperdicio_alimentos/features/map/data/map_api_service.dart';
import '../widgets/nearby_restaurant_card.dart';
import 'package:reduccion_desperdicio_alimentos/features/map/presentation/map_screen.dart';
import 'package:reduccion_desperdicio_alimentos/features/restaurant_detail/presentation/screens/restaurant_detail_screen.dart';

class NearbyRestaurantsScreen extends StatefulWidget {
  const NearbyRestaurantsScreen({super.key});

  @override
  State<NearbyRestaurantsScreen> createState() =>
      _NearbyRestaurantsScreenState();
}

class _NearbyRestaurantsScreenState extends State<NearbyRestaurantsScreen> {
  final LocationService _locationService = LocationService();
  final MapApiService _mapApiService = MapApiService();

  bool _isLoading = true;
  String? _error;
  List<MapCommerceModel> _commerces = [];

  @override
  void initState() {
    super.initState();
    _loadNearbyCommerces();
  }

  Future<void> _loadNearbyCommerces() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final position = await _locationService.getCurrentPosition();

      final commerces = await _mapApiService.getNearbyCommerces(
        position.latitude,
        position.longitude,
      );

      setState(() {
        _commerces = commerces;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_off, size: 50, color: AppColors.primary),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _loadNearbyCommerces,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (_commerces.isEmpty) {
      return const Center(
        child: Text(
          'No hay ofertas cercanas',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.location_on, color: Colors.green),
              const SizedBox(width: 8),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mi ubicación',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Radio: 3 km',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MapScreen(),
                    ),
                  );
                },
                child: const Text('Cambiar'),
              ),
            ],
          ),
        ),

        Container(
          color: AppColors.cardBg,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Locales cercanos',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('${_commerces.length} resultados'),
              ),
            ],
          ),
        ),

        Expanded(
          child: ListView.builder(
            itemCount: _commerces.length + 1,
            itemBuilder: (context, index) {
              if (index == _commerces.length) {
                return const Padding(
                  padding: EdgeInsets.all(12),
                  child: Center(
                    child: Text(
                      'Ordenado de menor a mayor distancia',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                );
              }

              return NearbyRestaurantCard(
                commerce: _commerces[index],
                onTap: () {
                  final id = int.tryParse(_commerces[index].id) ?? 0;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RestaurantDetailScreen(commerceId: id),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}