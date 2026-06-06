import 'package:flutter/material.dart';
import 'package:reduccion_desperdicio_alimentos/core/theme/app_colors.dart';
import 'package:reduccion_desperdicio_alimentos/core/services/cart_repository.dart';
import 'package:reduccion_desperdicio_alimentos/core/services/favorites_repository.dart';
import 'package:reduccion_desperdicio_alimentos/core/services/price_cache_repository.dart';
import 'package:reduccion_desperdicio_alimentos/core/services/alerts_repository.dart';
import 'package:reduccion_desperdicio_alimentos/features/home/data/repositories/product_repository.dart';
import 'package:reduccion_desperdicio_alimentos/features/home/data/models/product_model.dart';
import 'package:reduccion_desperdicio_alimentos/shared/widgets/countdown_timer.dart';
import 'package:reduccion_desperdicio_alimentos/shared/widgets/quantity_button.dart';

class ProductDetailScreen extends StatefulWidget {
  final int productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final ProductRepository _repository = ProductRepository();
  final CartRepository _cartRepo = CartRepository();
  final FavoritesRepository _favoritesRepo = FavoritesRepository();
  final PriceCacheRepository _priceCacheRepo = PriceCacheRepository();
  final AlertsRepository _alertsRepo = AlertsRepository();
  ProductModel? _product;
  bool _isLoading = true;
  String? _error;
  int _quantity = 1;
  bool _isFavorite = false;
  bool _priceDropped = false;
  double? _previousPrice;

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  DateTime _boliviaTime(DateTime dt) {
    return dt.toUtc().subtract(const Duration(hours: 4));
  }

  Future<void> _loadProduct() async {
    setState(() {
      _isLoading = true;
      _quantity = 1;
    });
    try {
      final product = await _repository.getProductById(widget.productId);
      final favoriteIds = await _favoritesRepo.getFavorites();
      final cachedPrice = await _priceCacheRepo.getLastPrice(widget.productId);
      final dropped = cachedPrice != null && product.price < cachedPrice;
      await _priceCacheRepo.updatePrice(widget.productId, product.price);
      if (dropped && product.isExpiringSoon) {
        final existing = await _alertsRepo.getAlerts();
        final alreadyAlerted = existing.any(
          (a) => a.productId == product.id && a.type == 'bajo_precio',
        );
        if (!alreadyAlerted) {
          _alertsRepo.addAlert(
            type: 'bajo_precio',
            productId: product.id,
            title: '¡Precio bajó!',
            message: '${product.title} ahora está a Bs. ${product.price.toStringAsFixed(2)}',
          );
        }
      }
      setState(() {
        _product = product;
        _isFavorite = favoriteIds.contains(widget.productId);
        _priceDropped = dropped;
        _previousPrice = cachedPrice;
        _quantity = 1;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    if (_isFavorite) {
      await _favoritesRepo.removeFavorite(widget.productId);
    } else if (_product != null) {
      final p = _product!;
      await _favoritesRepo.toggleFavorite(widget.productId, productData: {
        'id': p.id,
        'title': p.title,
        'price': p.price,
        'originalPrice': p.originalPrice,
        'imageUrl': p.imageUrl,
        'commerceName': p.commerceName,
        'pickupEnd': p.pickupEnd.toIso8601String(),
        'status': p.status,
        'quantity': p.quantity,
      });
    }
    setState(() => _isFavorite = !_isFavorite);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          if (_product != null)
            IconButton(
              icon: Icon(
                _isFavorite ? Icons.favorite : Icons.favorite_border,
                color: _isFavorite ? Colors.red : AppColors.textPrimary,
                size: 26,
              ),
              onPressed: _toggleFavorite,
            ),
        ],
      ),
      body: _isLoading
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
                        onPressed: _loadProduct,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : _buildBody(),
    );
  }

  Widget _buildBody() {
    final p = _product!;
    final discount = p.discountPercentage;
    final isAvailable = p.isAvailable;

    return Column(
      children: [
        Expanded(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildImageSection(p, discount, isAvailable)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: _buildHeader(p),
                ),
              ),
              if (_priceDropped)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: _buildPriceDropBanner(),
                  ),
                ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: _buildPickupSection(p),
                ),
              ),
              if (p.isExpiringSoon)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: _buildCountdownSection(p),
                  ),
                ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: _buildInfoGrid(p),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
            ],
          ),
        ),
        _buildBottomBar(p, isAvailable),
      ],
    );
  }

  Widget _buildImageSection(ProductModel p, double discount, bool isAvailable) {
    return SizedBox(
      height: 220,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          p.imageUrl.isNotEmpty
              ? Image.network(p.imageUrl, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.image, size: 80, color: Colors.grey),
                  ),
                )
              : Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.shopping_bag, size: 80, color: Colors.grey),
                ),
          Positioned(
            bottom: 12,
            left: 16,
            child: Row(
              children: [
                if (discount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '-${discount.round()}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if (discount > 0) const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isAvailable
                        ? Colors.green.withValues(alpha: 0.9)
                        : Colors.red.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isAvailable ? 'Disponible' : 'Agotado',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ProductModel p) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (p.category != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    p.category!.name,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                p.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              if (p.commerceName != null)
                Row(
                  children: [
                    Icon(Icons.store_outlined, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      p.commerceName!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Bs. ${p.price.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            if (p.originalPrice > p.price)
              Text(
                'Bs. ${p.originalPrice.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[400],
                  decoration: TextDecoration.lineThrough,
                ),
              ),
            if (p.originalPrice > p.price)
              Text(
                'Ahorras Bs. ${(p.originalPrice - p.price).toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildPriceDropBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.trending_down, size: 16, color: Colors.green),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '¡Precio reducido! Antes Bs. ${_previousPrice?.toStringAsFixed(2) ?? ''}',
              style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPickupSection(ProductModel p) {
    final start = _boliviaTime(p.pickupStart);
    final end = _boliviaTime(p.pickupEnd);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.amber.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.access_time, size: 18, color: AppColors.darkBrown),
              const SizedBox(width: 8),
              const Text(
                'Recoger en tienda',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkBrown,
                ),
              ),
              const Spacer(),
              Text(
                'Bolivia (UTC-4)',
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          const Divider(height: 16, color: AppColors.amber),
          Row(
            children: [
              _buildPickupBlock('Desde', start),
              Container(
                width: 1,
                height: 36,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                color: AppColors.amber.withValues(alpha: 0.3),
              ),
              _buildPickupBlock('Hasta', end),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPickupBlock(String label, DateTime dt) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(height: 2),
          Text(
            '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          Text(
            '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.darkBrown),
          ),
        ],
      ),
    );
  }

  Widget _buildCountdownSection(ProductModel p) {
    final minutesLeft = p.pickupEnd.difference(DateTime.now()).inMinutes;
    final urgent = minutesLeft <= 5;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: urgent ? Colors.red.withValues(alpha: 0.08) : AppColors.alertBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: urgent ? Colors.red.withValues(alpha: 0.3) : AppColors.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.timer, color: urgent ? Colors.red : AppColors.primary, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  urgent ? '¡Se acaba!' : 'Última oportunidad',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                CountdownTimer(target: p.pickupEnd),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoGrid(ProductModel p) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Detalles',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _infoTile(Icons.inventory_2_outlined, 'Stock', '${p.quantity} u.')),
              if (p.commerceName != null)
                Expanded(child: _infoTile(Icons.store_outlined, 'Tienda', p.commerceName!)),
            ],
          ),
          const SizedBox(height: 8),
          if (p.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                p.description,
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
            Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomBar(ProductModel p, bool isAvailable) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  QuantityButton(
                    icon: Icons.remove,
                    size: 32,
                    onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      '$_quantity',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  QuantityButton(
                    icon: Icons.add,
                    size: 32,
                    onPressed: _quantity < p.quantity ? () => setState(() => _quantity++) : null,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isAvailable ? AppColors.primary : Colors.grey,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: isAvailable ? () => _addToCart(p) : null,
                  child: Text(
                    isAvailable ? 'Agregar al Carrito' : 'Agotado',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addToCart(ProductModel p) async {
    final cartItem = CartItem(
      productId: p.id,
      title: p.title,
      price: p.price,
      imageUrl: p.imageUrl,
      quantity: _quantity,
      commerceId: p.commerceId,
      commerceName: p.commerceName,
      stock: p.quantity,
      pickupEnd: p.pickupEnd,
    );
    await _cartRepo.addItem(cartItem, p.quantity);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$_quantity ${_quantity == 1 ? "unidad" : "unidades"} añadida${_quantity == 1 ? "" : "s"} al carrito'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Ver Carrito',
            textColor: Colors.white,
            onPressed: () {
              CartRepository.navigateToCartNotifier.value = true;
              Navigator.pop(context);
            },
          ),
        ),
      );
    }
  }
}
