import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/shell_wrapper.dart';
import '../../data/models/product_model.dart';
import '../../data/repositories/product_repository.dart';
import '../widgets/featured_product_card.dart';
import '../widgets/product_card.dart';
import 'product_detail_screen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final ProductRepository _repository = ProductRepository();
  List<ProductModel> _products = [];
  bool _isLoading = true;
  String? _error;
  int? _expandedIndex;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final products = await _repository.getProductsWithFilters();
      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $_error', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadProducts,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_products.isEmpty) {
      return const Center(child: Text('No hay productos disponibles'));
    }

    return RefreshIndicator(
      onRefresh: _loadProducts,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Oferta del Día',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 450,
                    child: FeaturedProductCard(
                      product: _products.first,
                      isExpanded: _expandedIndex == 0,
                      onExpand: () {
                        setState(() {
                          _expandedIndex = _expandedIndex == 0 ? null : 0;
                        });
                      },
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ShellWrapper(
                            child: ProductDetailScreen(productId: _products.first.id),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Más Productos',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.7,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final product = _products[index + 1];
                  return ProductCard(
                    product: product,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ShellWrapper(
                          child: ProductDetailScreen(productId: product.id),
                        ),
                      ),
                    ),
                    onVer: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ShellWrapper(
                          child: ProductDetailScreen(productId: product.id),
                        ),
                      ),
                    ),
                  );
                },
                childCount: _products.length > 1 ? _products.length - 1 : 0,
              ),
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 20)),
        ],
      ),
    );
  }
}