import 'package:flutter/material.dart';
import 'package:reduccion_desperdicio_alimentos/core/theme/app_colors.dart';
import 'package:reduccion_desperdicio_alimentos/features/dashboard/data/models/oferta_model.dart';
import 'package:reduccion_desperdicio_alimentos/features/dashboard/presentation/widgets/actividad_tile.dart';
import 'package:reduccion_desperdicio_alimentos/features/dashboard/presentation/widgets/rendimiento_card.dart';
import 'package:reduccion_desperdicio_alimentos/features/dashboard/presentation/widgets/stats_mini_card.dart';
import 'package:reduccion_desperdicio_alimentos/features/dashboard/presentation/widgets/time_alert_banner.dart';
import 'package:reduccion_desperdicio_alimentos/features/dashboard/presentation/widgets/ventas_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  // Datos de prueba — se reemplazarán con Firebase
  static final _ofertas = [
    OfertaModel(
      id: '1',
      categoria: 'Panadería',
      nombre: 'Pack Panadería Familiar',
      unidadesRestantes: 3,
      precio: 4.50,
      precioOriginal: 12.00,
      estado: 'active',
      horaLimite: DateTime.now().add(const Duration(minutes: 12)),
      creadaEn: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    OfertaModel(
      id: '2',
      categoria: 'Frutería',
      nombre: 'Cesta Frutas de Temporada',
      unidadesRestantes: 0,
      precio: 8.20,
      precioOriginal: 15.00,
      estado: 'sold',
      horaLimite: DateTime.now().subtract(const Duration(hours: 1)),
      creadaEn: DateTime.now().subtract(const Duration(hours: 5)),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final ofertaAlerta = _ofertas.where((o) => o.isExpiringSoon).firstOrNull;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
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
                  _buildStatsRow(),
                  if (ofertaAlerta != null) ...[
                    const SizedBox(height: 16),
                    TimeAlertBanner(oferta: ofertaAlerta),
                  ],
                  const SizedBox(height: 16),
                  RendimientoCard(
                    ofertasActivas: 15,
                    ofertasVendidas: 28,
                    tasaExito: 84,
                    tiempoPromedioMin: 45,
                  ),
                  const SizedBox(height: 20),
                  _buildActividadHeader(),
                  const SizedBox(height: 4),
                  _buildActividad(),
                  const SizedBox(height: 20),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      floating: true,
      leading: IconButton(
        icon: const Icon(Icons.menu, color: AppColors.textPrimary),
        onPressed: () {},
      ),
      title: const Text(
        'owner',
        style: TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w800,
          fontSize: 20,
        ),
      ),
      centerTitle: true,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.cardBg,
            child: const Icon(Icons.person_outline, color: AppColors.textSecondary, size: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'Panel de Control',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Gestión activa de excedentes y ventas',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 5,
          child: VentasCard(ventas: 12400, porcentajeCambio: 14),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 4,
          child: Column(
            children: const [
              StatsMiniCard(
                icon: Icons.inventory_2_outlined,
                label1: 'Productos',
                label2: 'Activos',
                value: '42',
              ),
              SizedBox(height: 10),
              StatsMiniCard(
                icon: Icons.restaurant_menu_outlined,
                label1: 'Platos',
                label2: 'Vendidos',
                value: '128',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActividadHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Actividad Reciente',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          'Ver todo',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildActividad() {
    return Column(
      children: const [
        Divider(height: 1),
        ActividadTile(
          tipo: TipoActividad.vendida,
          titulo: 'Oferta Vendida',
          subtitulo: 'Menú Ejecutivo x2 · Hace 5m',
          monto: 24.00,
        ),
        Divider(height: 1),
        ActividadTile(
          tipo: TipoActividad.nueva,
          titulo: 'Nueva Oferta',
          subtitulo: 'Rolls de Canela · Hace 12m',
          badge: 'ACTIVO',
        ),
        Divider(height: 1),
        ActividadTile(
          tipo: TipoActividad.stock,
          titulo: 'Stock Actualizado',
          subtitulo: 'Bebidas Naturales · Hace 1h',
        ),
      ],
    );
  }
}
