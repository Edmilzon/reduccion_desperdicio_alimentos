import 'package:flutter/material.dart';
import 'package:reduccion_desperdicio_alimentos/core/theme/app_colors.dart';
import 'package:reduccion_desperdicio_alimentos/features/dashboard/data/models/oferta_model.dart';
import 'package:reduccion_desperdicio_alimentos/features/dashboard/data/repositories/dashboard_repository.dart';
import 'package:reduccion_desperdicio_alimentos/features/dashboard/presentation/screens/edit_product_screen.dart';
import 'package:reduccion_desperdicio_alimentos/features/dashboard/presentation/widgets/offer_card.dart';

class MyOffersScreen extends StatefulWidget {
  final void Function(VoidCallback)? onRefreshRegistered;

  const MyOffersScreen({super.key, this.onRefreshRegistered});

  @override
  State<MyOffersScreen> createState() => _MyOffersScreenState();
}

class _MyOffersScreenState extends State<MyOffersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _repo = DashboardRepository();

  List<OfertaModel> _ofertas = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
    cargarOfertas();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onRefreshRegistered?.call(_refreshOffers);
    });
  }

  void _refreshOffers() {
    cargarOfertas();
  }

  Future<void> cargarOfertas() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final ofertas = await _repo.getMisOfertas();
      if (mounted) {
        setState(() {
          _ofertas = ofertas;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<OfertaModel> get _actuales => _ofertas.where((o) => o.isActive).toList();
  List<OfertaModel> get _historial => _ofertas.where((o) => o.isSold).toList();

  @override
  Widget build(BuildContext context) {
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
                          onPressed: cargarOfertas,
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            SizedBox(height: 16),
                            Text(
                              'Mis Excedentes',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Gestiona tus publicaciones actuales y pasadas.',
                              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                            ),
                            SizedBox(height: 16),
                          ],
                        ),
                      ),
                      _buildTabBar(),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildLista(_actuales),
                            _buildLista(_historial),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.primary, width: 1.5),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
        tabs: const [
          Tab(text: 'Actuales'),
          Tab(text: 'Historial'),
        ],
      ),
    );
  }

  Widget _buildLista(List<OfertaModel> lista) {
    if (lista.isEmpty) {
      return const Center(
        child: Text(
          'No hay ofertas en esta sección.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: cargarOfertas,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        itemCount: lista.length,
        itemBuilder: (_, i) => OfferCard(
          oferta: lista[i],
          onEdit: () => _onEdit(lista[i]),
          onDelete: () => _onDelete(lista[i]),
        ),
      ),
    );
  }

void _onDelete(OfertaModel oferta) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar oferta'),
        content: Text('¿Estás seguro de eliminar "${oferta.nombre}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _repo.deleteProduct(oferta.id);
                cargarOfertas();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString())),
                  );
                }
              }
            },
            child: const Text('Eliminar', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  void _onEdit(OfertaModel oferta) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditProductScreen(
          oferta: oferta,
          onSuccess: cargarOfertas,
        ),
      ),
    );
  }
}