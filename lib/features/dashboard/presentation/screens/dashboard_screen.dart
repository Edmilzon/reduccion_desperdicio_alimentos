import 'package:flutter/material.dart';
import 'package:reduccion_desperdicio_alimentos/core/theme/app_colors.dart';
import 'package:reduccion_desperdicio_alimentos/features/dashboard/data/models/oferta_model.dart';
import 'package:reduccion_desperdicio_alimentos/features/dashboard/data/repositories/dashboard_repository.dart';
import 'package:reduccion_desperdicio_alimentos/features/dashboard/presentation/widgets/stats_mini_card.dart';
import 'package:reduccion_desperdicio_alimentos/features/dashboard/presentation/widgets/ventas_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _repo = DashboardRepository();
  List<OfertaModel> _ofertas = [];
  Map<String, dynamic>? _stats;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final commerceId = await _repo.getCommerceIdInt();
      final stats = await _repo.getDashboardStats(commerceId.toString());
      final ofertas = await _repo.getMisOfertas();
      if (mounted) {
        setState(() {
          _stats = stats;
          _ofertas = ofertas;
          _isLoading = false;
        });
      }
    } catch (e) {
      try {
        final ofertas = await _repo.getMisOfertas();
        if (mounted) {
          setState(() {
            _ofertas = ofertas;
            _isLoading = false;
          });
        }
      } catch (_) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _error = e.toString();
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ofertaAlerta = _ofertas.where((o) => o.isExpiringSoon).firstOrNull;
    
    double ventasTotal = 0;
    int productosActivos = 0;
    int productosVendidos = 0;
    
    if (_stats != null) {
      ventasTotal = (_stats!['totalRevenue'] ?? _stats!['ventasTotales'] ?? 0).toDouble();
      productosActivos = _stats!['activeProducts'] ?? _stats!['productosActivos'] ?? 0;
      productosVendidos = _stats!['soldProducts'] ?? _stats!['productosVendidos'] ?? 0;
    } else {
      ventasTotal = _ofertas.fold<double>(0, (sum, o) => sum + o.price);
      productosActivos = _ofertas.where((o) => o.isActive).length;
      productosVendidos = _ofertas.where((o) => o.isSold).length;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_error!),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _cargarDatos,
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _cargarDatos,
                    child: CustomScrollView(
                      slivers: [
                        _buildAppBar(),
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          sliver: SliverList(
                            delegate: SliverChildListDelegate([
                              const SizedBox(height: 20),
                              _buildHeader(),
                              const SizedBox(height: 20),
                              _buildStatsRow(ventasTotal, productosActivos, productosVendidos),
                              const SizedBox(height: 16),
                              if (ofertaAlerta != null)
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.alertBg,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.warning, color: AppColors.primary),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'La oferta "${ofertaAlerta.nombre}" expira pronto',
                                          style: const TextStyle(color: AppColors.primary),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              const SizedBox(height: 16),
                              const SizedBox(height: 20),
                            ]),
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }

  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      floating: true,
      leading: const SizedBox.shrink(),
      title: const Text(
        'Panel',
        style: TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w800,
          fontSize: 20,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Estadísticas',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Resumen de tu negocio',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildStatsRow(double ventas, int activos, int vendidos) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 5,
          child: VentasCard(ventas: ventas),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 4,
          child: Column(
            children: [
              StatsMiniCard(
                icon: Icons.inventory_2_outlined,
                label1: 'Productos',
                label2: 'Activos',
                value: activos.toString(),
              ),
              const SizedBox(height: 10),
              StatsMiniCard(
                icon: Icons.restaurant_menu_outlined,
                label1: 'Vendidos',
                label2: 'Total',
                value: vendidos.toString(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}