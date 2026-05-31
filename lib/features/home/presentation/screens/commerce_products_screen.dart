import 'package:flutter/material.dart';
import 'package:reduccion_desperdicio_alimentos/core/theme/app_colors.dart';
import 'package:reduccion_desperdicio_alimentos/features/home/data/repositories/product_repository.dart';
import 'package:reduccion_desperdicio_alimentos/features/home/data/models/product_model.dart';
import 'package:reduccion_desperdicio_alimentos/features/home/presentation/screens/product_detail_screen.dart';
import 'package:reduccion_desperdicio_alimentos/shared/widgets/product_item_widget.dart';


class CommerceProductsScreen extends StatefulWidget {
  final CommerceModel commerce;

  const CommerceProductsScreen({super.key, required this.commerce});

  @override
  State<CommerceProductsScreen> createState() => _CommerceProductsScreenState();
}

class _CommerceProductsScreenState extends State<CommerceProductsScreen> {
  final ProductRepository _repository = ProductRepository();
  List<ProductModel> _products = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final products = await _repository.getProductsByCommerce(widget.commerce.id);
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
    final filtered = _searchQuery.isEmpty
        ? _products
        : _products.where((p) {
            final q = _searchQuery.toLowerCase();
            return p.title.toLowerCase().contains(q) || p.description.toLowerCase().contains(q);
          }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: const BackButton(),
        title: Text(
          widget.commerce.name,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppColors.cardBg,
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Buscar en ${widget.commerce.name}...',
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 48, color: Colors.red),
                            const SizedBox(height: 16),
                            Text(_error!, textAlign: TextAlign.center),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadProducts,
                              child: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      )
                    : filtered.isEmpty
                        ? const Center(child: Text('No hay productos'))
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              return ProductItemWidget(
                                product: filtered[index],
                                showCategory: true,
                                showAvailability: true,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ProductDetailScreen(productId: filtered[index].id),
                                    ),
                                  ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}


