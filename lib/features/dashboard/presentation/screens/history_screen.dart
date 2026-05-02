import 'package:flutter/material.dart';
import 'package:reduccion_desperdicio_alimentos/core/theme/app_colors.dart';
import 'package:reduccion_desperdicio_alimentos/features/dashboard/data/models/oferta_model.dart';
import 'package:reduccion_desperdicio_alimentos/features/dashboard/presentation/widgets/offer_card.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  static final _historial = [
    OfertaModel(
      id: 'h1',
      categoria: 'Panadería',
      nombre: 'Pack Panadería Familiar',
      unidadesRestantes: 0,
      precio: 5.00,
      precioOriginal: 13.00,
      estado: 'sold',
      horaLimite: DateTime.now().subtract(const Duration(days: 1)),
      creadaEn: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
    ),
    OfertaModel(
      id: 'h2',
      categoria: 'Menú del Día',
      nombre: 'Menú Ejecutivo Completo',
      unidadesRestantes: 0,
      precio: 7.50,
      precioOriginal: 18.00,
      estado: 'sold',
      horaLimite: DateTime.now().subtract(const Duration(days: 2)),
      creadaEn: DateTime.now().subtract(const Duration(days: 2, hours: 4)),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
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
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 20),
                  const Text(
                    'Historial',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Todas tus ofertas pasadas.',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 20),
                  ..._historial.map(
                    (o) => OfferCard(oferta: o),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
