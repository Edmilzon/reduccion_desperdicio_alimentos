import 'package:flutter/material.dart';
import 'package:reduccion_desperdicio_alimentos/core/theme/app_colors.dart';
import 'package:reduccion_desperdicio_alimentos/features/dashboard/data/models/oferta_model.dart';
import 'package:reduccion_desperdicio_alimentos/features/dashboard/data/repositories/dashboard_repository.dart';
import 'package:reduccion_desperdicio_alimentos/features/dashboard/presentation/widgets/offer_card.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _repo = DashboardRepository();
  List<OfertaModel> _ofertas = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarHistorial();
  }

  Future<void> _cargarHistorial() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final ofertas = await _repo.getMisOfertas();
      if (mounted) {
        setState(() {
          _ofertas = ofertas.where((o) => o.isSold).toList();
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
                          onPressed: _cargarHistorial,
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Historial',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Tus productos vendidos',
                              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: _ofertas.isEmpty
                            ? const Center(
                                child: Text(
                                  'No hay historial aún.',
                                  style: TextStyle(color: AppColors.textSecondary),
                                ),
                              )
                            : RefreshIndicator(
                                onRefresh: _cargarHistorial,
                                child: ListView.builder(
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  itemCount: _ofertas.length,
                                  itemBuilder: (_, i) => OfferCard(
                                    oferta: _ofertas[i],
                                    onEdit: () {},
                                    onDelete: () {},
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
      ),
    );
  }
}