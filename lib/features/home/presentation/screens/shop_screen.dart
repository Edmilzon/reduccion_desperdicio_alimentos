import 'package:flutter/material.dart';
import 'package:reduccion_desperdicio_alimentos/core/theme/app_colors.dart';
import 'package:reduccion_desperdicio_alimentos/features/home/data/repositories/product_repository.dart';
import 'package:reduccion_desperdicio_alimentos/features/home/data/models/product_model.dart';
import 'package:reduccion_desperdicio_alimentos/features/home/presentation/screens/commerce_products_screen.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final ProductRepository _repository = ProductRepository();
  List<CommerceModel> _commerces = [];
  List<CategoryModel> _categories = [];
  List<ProductModel> _filteredProducts = [];
  bool _isLoading = true;
  String? _error;
  int? _selectedCategoryId;
  String _searchQuery = '';
  String _sortBy = 'nombre';
  String _status = 'all';

  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final categories = await _repository.getCategories();
      final products = await _repository.getProductsWithFilters(
        categoryId: _selectedCategoryId,
      );
      final commerces = await _repository.getCommerces();
      setState(() {
        _categories = categories;
        _filteredProducts = products;
        _commerces = commerces;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    if (query.isNotEmpty) {
      _searchAll(query);
    } else {
      _loadData();
    }
  }

  Future<void> _searchAll(String query) async {
    setState(() => _isLoading = true);
    try {
      final results = await _repository.searchProducts(query);
      final allCommerces = await _repository.getCommerces();
      setState(() {
        _filteredProducts = results;
        _commerces = allCommerces;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _onFilterCategory(int? categoryId) {
    setState(() {
      _selectedCategoryId = categoryId;
      _isLoading = true;
    });
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final showProducts = _selectedCategoryId != null || _searchQuery.isNotEmpty;
    final filteredProducts = _getFilteredProducts();
    final filteredCommerces = showProducts ? <CommerceModel>[] : _getFilteredCommerces();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        titleSpacing: 0,
        title: _buildSearchField(),
      ),
      body: Column(
        children: [
          if (!showProducts) _buildFilters(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _error != null
                    ? _buildErrorView()
                    : showProducts
                        ? filteredProducts.isEmpty
                            ? const Center(child: Text('No hay resultados'))
                            : _buildProductList(filteredProducts)
                        : filteredCommerces.isEmpty
                            ? const Center(child: Text('No hay restaurantes'))
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: filteredCommerces.length,
                                itemBuilder: (context, index) {
                                  final commerce = filteredCommerces[index];
                                  return _CommerceCard(
                                    commerce: commerce,
                                    products: _filteredProducts.where((p) => p.commerceId == commerce.id).toList(),
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => CommerceProductsScreen(commerce: commerce),
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

  Widget _buildProductList(List<ProductModel> products) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        final commerce = _commerces.firstWhere((c) => c.id == product.commerceId, orElse: () => CommerceModel(id: 0, name: 'Sin nombre'));
        return _ProductItem(
          product: product,
          commerceName: commerce.name,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CommerceProductsScreen(commerce: commerce),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: _onSearchChanged,
      decoration: InputDecoration(
        hintText: 'Buscar productos o restaurantes...',
        prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, size: 20),
                onPressed: () {
                  _searchController.clear();
                  _onSearchChanged('');
                },
              )
            : null,
        filled: true,
        fillColor: AppColors.cardBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: AppColors.cardBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('Categoría', _selectedCategoryId != null
                    ? _categories.firstWhere((c) => c.id == _selectedCategoryId, orElse: () => _categories.first).name
                    : null, () => _showCategoryPicker()),
                const SizedBox(width: 8),
                _buildFilterChip('Ordenar: $_sortBy', null, () => _showSortPicker()),
                const SizedBox(width: 8),
                _buildFilterChip('Estado: $_status', null, () => _showStatusPicker()),
              ],
            ),
          ),
          if (_selectedCategoryId != null) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _onFilterCategory(null),
              child: Row(
                children: [
                  const Icon(Icons.close, size: 14, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    'Categoría: ${_categories.firstWhere((c) => c.id == _selectedCategoryId).name}',
                    style: const TextStyle(color: AppColors.primary, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String? selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected != null ? AppColors.primary.withValues(alpha: 0.15) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected != null ? AppColors.primary : Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              selected ?? label,
              style: TextStyle(
                fontSize: 12,
                color: selected != null ? AppColors.primary : AppColors.textSecondary,
                fontWeight: selected != null ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down, size: 16, color: selected != null ? AppColors.primary : AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  void _showCategoryPicker() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => ListView(
        shrinkWrap: true,
        children: [
          ListTile(
            title: const Text('Todas las categorías'),
            onTap: () {
              _onFilterCategory(null);
              Navigator.pop(ctx);
            },
          ),
          ..._categories.map((c) => ListTile(
            title: Text(c.name),
            onTap: () {
              _onFilterCategory(c.id);
              Navigator.pop(ctx);
            },
          )),
        ],
      ),
    );
  }

  void _showSortPicker() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => ListView(
        shrinkWrap: true,
        children: [
          ListTile(
            title: const Text('Nombre'),
            subtitle: const Text('A-Z'),
            onTap: () {
              setState(() => _sortBy = 'nombre');
              Navigator.pop(ctx);
            },
          ),
          ListTile(
            title: const Text('Precio'),
            subtitle: const Text('Menor a mayor'),
            onTap: () {
              setState(() => _sortBy = 'precio');
              Navigator.pop(ctx);
            },
          ),
          ListTile(
            title: const Text('Descuento'),
            subtitle: const Text('Mayor descuento primero'),
            onTap: () {
              setState(() => _sortBy = 'descuento');
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }

  void _showStatusPicker() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => ListView(
        shrinkWrap: true,
        children: [
          ListTile(
            title: const Text('Todos'),
            onTap: () {
              setState(() => _status = 'all');
              Navigator.pop(ctx);
            },
          ),
          ListTile(
            title: const Text('Activos'),
            subtitle: const Text('Disponibles ahora'),
            onTap: () {
              setState(() => _status = 'active');
              Navigator.pop(ctx);
            },
          ),
          ListTile(
            title: const Text('Agotados'),
            subtitle: const Text('Vendidos'),
            onTap: () {
              setState(() => _status = 'sold_out');
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(_error!, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadData,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  List<ProductModel> _getFilteredProducts() {
    var filtered = List<ProductModel>.from(_filteredProducts);

    if (_selectedCategoryId != null) {
      filtered = filtered.where((p) => p.category?.id == _selectedCategoryId).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered.where((p) {
        return p.title.toLowerCase().contains(q) ||
            p.description.toLowerCase().contains(q);
      }).toList();
    }

    if (_status != 'all') {
      filtered = filtered.where((p) => p.status == _status).toList();
    }

    switch (_sortBy) {
      case 'precio':
        filtered.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'descuento':
        filtered.sort((a, b) => b.discountPercentage.compareTo(a.discountPercentage));
        break;
      default:
        filtered.sort((a, b) => a.title.compareTo(b.title));
    }

    return filtered;
  }

  List<CommerceModel> _getFilteredCommerces() {
    var categoryCommerces = _selectedCategoryId != null
        ? _commerces.where((c) => _filteredProducts.any((p) => p.commerceId == c.id && p.category?.id == _selectedCategoryId)).toList()
        : _commerces;

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      categoryCommerces = categoryCommerces.where((c) {
        return _filteredProducts.any((p) =>
            p.commerceId == c.id &&
            (_status == 'all' || p.status == _status) &&
            (p.title.toLowerCase().contains(q) || (c.name.toLowerCase().contains(q))));
      }).toList();
    }

    if (_status != 'all') {
      categoryCommerces = categoryCommerces.where((c) {
        return _filteredProducts.any((p) =>
            p.commerceId == c.id && p.status == _status);
      }).toList();
    }

    final sorted = List<CommerceModel>.from(categoryCommerces);
    switch (_sortBy) {
      case 'precio':
        sorted.sort((a, b) {
          final pa = _filteredProducts.where((p) => p.commerceId == a.id).fold<double>(0, (s, p) => s + p.price);
          final pb = _filteredProducts.where((p) => p.commerceId == b.id).fold<double>(0, (s, p) => s + p.price);
          return pa.compareTo(pb);
        });
        break;
      case 'descuento':
        sorted.sort((a, b) {
          final pa = _filteredProducts.where((p) => p.commerceId == a.id).fold<double>(0, (s, p) => s + p.discountPercentage);
          final pb = _filteredProducts.where((p) => p.commerceId == b.id).fold<double>(0, (s, p) => s + p.discountPercentage);
          return pb.compareTo(pa);
        });
        break;
      default:
        sorted.sort((a, b) => a.name.compareTo(b.name));
    }

    return sorted;
  }
}

class _CommerceCard extends StatelessWidget {
  final CommerceModel commerce;
  final List<ProductModel> products;
  final VoidCallback? onTap;

  const _CommerceCard({required this.commerce, required this.products, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: Stack(
          children: [
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                    ),
                    child: _buildImage(),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            commerce.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (commerce.description != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              commerce.description!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(right: 16),
                    child: Icon(
                      Icons.arrow_forward_ios,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
            if (discount > 0)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '-${discount.round()}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  double get discount {
    if (products.isEmpty) return 0;
    return products.map((p) => p.discountPercentage).reduce((a, b) => a > b ? a : b);
  }

  Widget _buildImage() {
    if (commerce.hasImage) {
      return ClipRRect(
        borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
        child: Image.network(
          commerce.imageUrl!,
          fit: BoxFit.cover,
          width: 120,
          height: 120,
          errorBuilder: (context, error, stack) => const Icon(
            Icons.store, size: 48, color: AppColors.primary,
          ),
        ),
      );
    }
    return const Icon(Icons.store, size: 48, color: AppColors.primary);
  }
}

class _ProductItem extends StatelessWidget {
  final ProductModel product;
  final String commerceName;
  final VoidCallback? onTap;

  const _ProductItem({required this.product, required this.commerceName, this.onTap});

  @override
  Widget build(BuildContext context) {
    final discount = product.discountPercentage;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
              ),
              child: product.imageUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                      child: Image.network(product.imageUrl, fit: BoxFit.cover, width: 100, height: 100,
                        errorBuilder: (_, _, _) => const Icon(Icons.shopping_bag, size: 40, color: AppColors.primary),
                      ),
                    )
                  : const Icon(Icons.shopping_bag, size: 40, color: AppColors.primary),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      commerceName,
                      style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      product.title,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      product.description,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          '\$${product.price.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                        if (discount > 0) ...[
                          const SizedBox(width: 6),
                          Text(
                            '\$${product.originalPrice.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textLight, decoration: TextDecoration.lineThrough),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(6)),
                            child: Text('-${discount.round()}%', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}