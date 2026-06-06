import 'package:flutter/material.dart';
import 'package:reduccion_desperdicio_alimentos/core/theme/app_colors.dart';
import 'package:reduccion_desperdicio_alimentos/features/dashboard/data/models/oferta_model.dart';
import 'package:reduccion_desperdicio_alimentos/features/dashboard/data/repositories/dashboard_repository.dart';
import 'package:reduccion_desperdicio_alimentos/features/dashboard/presentation/widgets/stats_chart.dart';
import 'package:reduccion_desperdicio_alimentos/features/orders/data/models/order_model.dart';
import 'package:reduccion_desperdicio_alimentos/features/orders/data/repositories/order_repository.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _repo = DashboardRepository();
  final _orderRepo = OrderRepository();
  List<OfertaModel> _ofertas = [];
  List<OrderModel> _orders = [];
  Map<String, dynamic>? _stats;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    if (!mounted) return;
    setState(() { _isLoading = true; _error = null; });

    try {
      final commerceId = await _repo.getCommerceIdInt();
      if (!mounted) return;

      final stats = _repo.getDashboardStats(commerceId.toString());
      final ofertas = _repo.getMisOfertas();
      final orders = _orderRepo.getMerchantOrders();

      final results = await Future.wait([stats, ofertas, orders],
        eagerError: false,
      );

      if (!mounted) return;
      setState(() {
        _stats = results[0] as Map<String, dynamic>;
        _ofertas = results[1] as List<OfertaModel>;
        _orders = results[2] as List<OrderModel>;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      try {
        final ofertas = await _repo.getMisOfertas();
        List<OrderModel> orders = [];
        try {
          orders = await _orderRepo.getMerchantOrders();
        } catch (_) {}
        if (!mounted) return;
        setState(() { _ofertas = ofertas; _orders = orders; _isLoading = false; });
      } catch (e2) {
        if (!mounted) return;
        setState(() { _isLoading = false; _error = e2.toString(); });
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
                              const SizedBox(height: 16),
                              _buildHeader(),
                              const SizedBox(height: 20),
                              _buildMetricsGrid(),
                              const SizedBox(height: 20),
                              _buildChartCard(),
                              const SizedBox(height: 16),
                              _buildCategoryCard(),
                              const SizedBox(height: 16),
                              if (_nearExpiryOffers.isNotEmpty) _buildNearExpiryCard(),
                              const SizedBox(height: 24),
                            ]),
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }

  List<OrderModel> get _pedidosDeHoy {
    final hoy = DateTime.now();
    return _orders.where((o) =>
      o.createdAt != null &&
      o.createdAt!.day == hoy.day &&
      o.createdAt!.month == hoy.month &&
      o.createdAt!.year == hoy.year
    ).toList();
  }

  double get _ventas {
    return _pedidosDeHoy.fold<double>(0, (sum, o) => sum + o.totalPrice);
  }

  int get _ofertasActivas => _stats?['activeOffers'] ?? _ofertas.where((o) => o.isActive).length;

  int get _unidsVendidas {
    return _pedidosDeHoy.fold<int>(0, (sum, o) => sum + o.quantity);
  }

  int get _pedidosHoy => _pedidosDeHoy.length;

  int get _ofertasHoy => _stats?['todayOffers'] ?? 0;
  int get _proxVencer => _stats?['nearExpiryCount'] ?? 0;
  List<dynamic> get _nearExpiryOffers => _stats?['nearExpiryOffers'] ?? [];

  List<_CategoryCount> get _categoryCounts {
    final map = <String, int>{};
    for (final o in _ofertas) {
      final cat = o.categoryName ?? 'Sin categoría';
      map[cat] = (map[cat] ?? 0) + 1;
    }
    final sorted = map.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final total = _ofertas.length;
    final colors = [AppColors.primary, AppColors.amber, Colors.green, Colors.blue, Colors.purple, Colors.teal, Colors.orange, Colors.pink];
    return sorted.asMap().entries.map((e) => _CategoryCount(
      name: e.value.key,
      count: e.value.value,
      total: total,
      color: colors[e.key % colors.length],
    )).toList();
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
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

  Widget _buildMetricsGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _MetricCard(
              icon: Icons.trending_up,
              label: 'Ventas hoy',
              value: '\$${_formatNumber(_ventas.toInt())}',
              color: Colors.green,
              bgColor: Colors.green.withValues(alpha: 0.08),
            )),
            const SizedBox(width: 10),
            Expanded(child: _MetricCard(
              icon: Icons.inventory_2_outlined,
              label: 'Ofertas activas',
              value: _ofertasActivas.toString(),
              color: AppColors.primary,
              bgColor: AppColors.primary.withValues(alpha: 0.08),
            )),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _MetricCard(
              icon: Icons.receipt_long_outlined,
              label: 'Pedidos hoy',
              value: _pedidosHoy.toString(),
              color: Colors.blue,
              bgColor: Colors.blue.withValues(alpha: 0.08),
            )),
            const SizedBox(width: 10),
            Expanded(child: _MetricCard(
              icon: Icons.shopping_cart_outlined,
              label: 'Unid. vendidas',
              value: _unidsVendidas.toString(),
              color: Colors.purple,
              bgColor: Colors.purple.withValues(alpha: 0.08),
            )),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _MetricCard(
              icon: Icons.add_circle_outline,
              label: 'Ofertas hoy',
              value: _ofertasHoy.toString(),
              color: Colors.teal,
              bgColor: Colors.teal.withValues(alpha: 0.08),
            )),
            const SizedBox(width: 10),
            Expanded(child: _MetricCard(
              icon: Icons.access_alarm,
              label: 'Próx. a vencer',
              value: _proxVencer.toString(),
              color: AppColors.amber,
              bgColor: AppColors.amber.withValues(alpha: 0.12),
            )),
          ],
        ),
      ],
    );
  }

  Widget _buildChartCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 3, height: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text(
                'Actividad semanal',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Ofertas publicadas por día',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          WeeklyBarChart(ofertas: _ofertas),
        ],
      ),
    );
  }

  Widget _buildCategoryCard() {
    final cats = _categoryCounts;
    if (cats.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 3, height: 16, color: AppColors.amber),
              const SizedBox(width: 8),
              const Text(
                'Categorías',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Distribución de productos',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          ...cats.map((c) => CategoryBar(
            name: c.name,
            count: c.count,
            total: c.total,
            color: c.color,
          )),
        ],
      ),
    );
  }

  Widget _buildNearExpiryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.alertBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Próximos a vencer',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$_proxVencer',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...(_nearExpiryOffers.take(5).map((offer) {
            final title = offer['title'] ?? offer['nombre'] ?? 'Producto';
            final qty = offer['quantity'] ?? 0;
            final price = double.tryParse(offer['price']?.toString() ?? '') ?? 0;
            final pickupEnd = offer['pickupEnd'] != null
                ? DateTime.tryParse(offer['pickupEnd'].toString())
                : null;
            final remaining = pickupEnd?.difference(DateTime.now());
            final mins = remaining?.inMinutes ?? 0;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary)),
                        Text('$qty unid. · \$${price.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: mins <= 30 ? Colors.red.withValues(alpha: 0.1) : AppColors.amber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      mins <= 0
                          ? 'Vencido'
                          : mins < 60
                              ? '$mins min'
                              : '${mins ~/ 60}h ${mins % 60}m',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: mins <= 30 ? Colors.red : AppColors.darkBrown,
                      ),
                    ),
                  ),
                ],
              ),
            );
          })),
        ],
      ),
    );
  }

  String _formatNumber(int n) {
    final s = n.toString();
    final result = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) result.write(',');
      result.write(s[i]);
    }
    return result.toString();
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Color bgColor;

  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: color,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryCount {
  final String name;
  final int count;
  final int total;
  final Color color;
  _CategoryCount({
    required this.name,
    required this.count,
    required this.total,
    required this.color,
  });
}
