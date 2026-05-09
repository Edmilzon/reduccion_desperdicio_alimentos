import 'package:flutter/material.dart';
import 'package:reduccion_desperdicio_alimentos/core/theme/app_colors.dart';
import 'package:reduccion_desperdicio_alimentos/features/home/data/repositories/product_repository.dart';
import 'package:reduccion_desperdicio_alimentos/features/home/data/models/product_model.dart';
import 'package:reduccion_desperdicio_alimentos/features/home/presentation/widgets/category_card.dart';
import 'package:reduccion_desperdicio_alimentos/features/home/presentation/widgets/product_list_item.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final ProductRepository _repository = ProductRepository();
  final TextEditingController _searchController = TextEditingController();
  List<CategoryModel> _categories = [];
  List<ProductModel> _filteredProducts = [];
  bool _isLoading = true;
  String? _error;
  CategoryModel? _selectedCategory;
  int? _selectedCategoryId;

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
    try {
      final categories = await _repository.getCategories();
      final products = await _repository.getProductsWithFilters();
      setState(() {
        _categories = categories;
        _filteredProducts = products;
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
    if (query.isEmpty) {
      _applyFilters();
      return;
    }
    _searchProducts(query);
  }

  Future<void> _searchProducts(String query) async {
    setState(() => _isLoading = true);
    try {
      final results = await _repository.searchProducts(query);
      setState(() {
        _filteredProducts = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _applyFilters() async {
    setState(() => _isLoading = true);
    try {
      final results = await _repository.getProductsWithFilters(
        categoryId: _selectedCategoryId,
      );
      setState(() {
        _filteredProducts = results;
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
      _selectedCategory = null;
    });
    _applyFilters();
  }

  void _onCategoryTap(CategoryModel category) {
    setState(() {
      _selectedCategory = category;
      _selectedCategoryId = category.id;
      _searchController.clear();
    });
    _applyFilters();
  }

  void _backToCategories() {
    setState(() {
      _selectedCategory = null;
      _selectedCategoryId = null;
      _searchController.clear();
    });
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    if (_categories.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          FilterChip(
            label: const Text('Todos'),
            selected: _selectedCategoryId == null,
            onSelected: (_) => _onFilterCategory(null),
            selectedColor: AppColors.primary.withValues(alpha: 0.2),
            checkmarkColor: AppColors.primary,
          ),
          const SizedBox(width: 8),
          ..._categories.map((cat) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(cat.name),
              selected: _selectedCategoryId == cat.id,
              onSelected: (_) => _onFilterCategory(cat.id),
              selectedColor: AppColors.primary.withValues(alpha: 0.2),
              checkmarkColor: AppColors.primary,
            ),
          )),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      leading: _selectedCategory != null
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: _backToCategories,
            )
          : null,
      titleSpacing: 0,
      title: Padding(
        padding: const EdgeInsets.only(right: 16),
        child: _buildSearchField(),
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: _onSearchChanged,
      autofocus: true,
      decoration: InputDecoration(
        hintText: _selectedCategory != null 
            ? 'Buscar en ${_selectedCategory!.name}...'
            : 'Buscar productos...',
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

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_error != null) {
      return _buildErrorView();
    }

    if (_selectedCategory != null) {
      return _buildProductList();
    }

    return _buildCategoryList();
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

  Widget _buildCategoryList() {
    if (_categories.isEmpty) {
      return const Center(child: Text('No hay categorías'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final category = _categories[index];
        return CategoryCard(
          category: category,
          onTap: () => _onCategoryTap(category),
        );
      },
    );
  }

  Widget _buildProductList() {
    if (_filteredProducts.isEmpty) {
      return const Center(child: Text('No hay productos'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredProducts.length,
      itemBuilder: (context, index) {
        final product = _filteredProducts[index];
        return ProductListItem(product: product);
      },
    );
  }
}