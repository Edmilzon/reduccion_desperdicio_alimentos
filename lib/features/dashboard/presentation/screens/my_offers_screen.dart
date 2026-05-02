import 'package:flutter/material.dart';
import 'package:reduccion_desperdicio_alimentos/core/theme/app_colors.dart';
import 'package:reduccion_desperdicio_alimentos/features/dashboard/data/models/oferta_model.dart';
import 'package:reduccion_desperdicio_alimentos/features/dashboard/presentation/widgets/offer_card.dart';

class MyOffersScreen extends StatefulWidget {
  const MyOffersScreen({super.key});

  @override
  State<MyOffersScreen> createState() => _MyOffersScreenState();
}

class _MyOffersScreenState extends State<MyOffersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Datos de prueba — se reemplazarán con Firebase
  final _ofertas = [
    OfertaModel(
      id: '1',
      categoria: 'Panadería',
      nombre: 'Pack Croissants Artesanos',
      unidadesRestantes: 8,
      precio: 4.50,
      precioOriginal: 12.00,
      estado: 'active',
      horaLimite: DateTime.now().add(const Duration(hours: 2)),
      creadaEn: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    OfertaModel(
      id: '2',
      categoria: 'Frutería',
      nombre: 'Cesta Frutas de Temporada',
      unidadesRestantes: 0,
      precio: 8.20,
      precioOriginal: 15.00,
      estado: 'sold',
      horaLimite: DateTime.now().subtract(const Duration(hours: 2)),
      creadaEn: DateTime.now().subtract(const Duration(hours: 6)),
    ),
    OfertaModel(
      id: '3',
      categoria: 'Platos Listos',
      nombre: 'Lasaña Vegetariana (2pax)',
      unidadesRestantes: 3,
      precio: 6.90,
      precioOriginal: 14.50,
      estado: 'active',
      horaLimite: DateTime.now().add(const Duration(hours: 1)),
      creadaEn: DateTime.now().subtract(const Duration(minutes: 30)),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<OfertaModel> get _actuales  => _ofertas.where((o) => o.isActive).toList();
  List<OfertaModel> get _historial => _ofertas.where((o) => o.isSold).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAppBar(),
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
            _buildResumenSemanal(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu, color: AppColors.textPrimary),
            onPressed: () {},
          ),
          const Expanded(
            child: Text(
              'owner',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
            ),
          ),
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.cardBg,
            child: const Icon(Icons.person_outline, color: AppColors.textSecondary, size: 20),
          ),
          const SizedBox(width: 8),
        ],
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
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      itemCount: lista.length,
      itemBuilder: (_, i) => OfferCard(
        oferta: lista[i],
        onEdit: () => _onEdit(lista[i]),
        onDelete: () => _onDelete(lista[i]),
      ),
    );
  }

  Widget _buildResumenSemanal() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.summaryBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resumen Semanal',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.darkBrown,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _resumenStat('24.5kg', 'AHORRO ESTIMADO')),
              Expanded(child: _resumenStat('128 Bs.', 'RECUPERADO')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _resumenStat(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.darkBrown,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.secondary,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  void _onEdit(OfertaModel oferta) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Editar oferta'),
        content: Text('Editar: ${oferta.nombre}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
        ],
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
            onPressed: () => Navigator.pop(context),
            child: const Text('Eliminar', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}
