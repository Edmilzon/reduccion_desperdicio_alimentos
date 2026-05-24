import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:reduccion_desperdicio_alimentos/core/theme/app_colors.dart';
import 'package:reduccion_desperdicio_alimentos/features/auth/data/repositories/auth_repository.dart';
import 'package:reduccion_desperdicio_alimentos/features/auth/presentation/screens/login_screen.dart';
import 'package:reduccion_desperdicio_alimentos/features/home/presentation/screens/client_home_screen.dart';
import 'package:reduccion_desperdicio_alimentos/features/home/presentation/screens/favorites_screen.dart';
import 'package:reduccion_desperdicio_alimentos/features/home/presentation/screens/alerts_screen.dart';
import 'package:reduccion_desperdicio_alimentos/features/orders/presentation/screens/merchant_pending_orders_screen.dart';
import 'package:reduccion_desperdicio_alimentos/features/orders/presentation/screens/my_orders_screen.dart';
import 'package:reduccion_desperdicio_alimentos/shared/widgets/main_shell.dart';

class ProfileScreen extends StatefulWidget {
  final bool isMerchant;

  const ProfileScreen({super.key, this.isMerchant = false});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authRepo = AuthRepository();
  String _userName = 'Usuario';
  String _userEmail = '';
  String _commerceName = '';
  bool _isLoadingUser = true;
  bool _isActuallyMerchant = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final user = await _authRepo.getCurrentUser();
      final prefs = await SharedPreferences.getInstance();
      final commerceName = prefs.getString('commerce_name') ?? '';
      final commerceId = prefs.getString('commerce_id');
      if (mounted) {
        setState(() {
          _userName = user.name.isNotEmpty ? user.name : 'Usuario';
          _userEmail = user.email;
          _commerceName = commerceName;
          _isActuallyMerchant = user.isMerchant && commerceId != null;
          _isLoadingUser = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingUser = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Mi Perfil',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 40,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isLoadingUser ? '...' : _userName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (_isActuallyMerchant) ...[
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const MainShell()),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _commerceName,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.arrow_forward_ios,
                              size: 10,
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    _isLoadingUser ? '' : _userEmail,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (_isActuallyMerchant) ...[
              _buildMenuItem(
                icon: Icons.storefront,
                title: 'Mercado',
                subtitle: 'Ver productos como cliente',
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => ClientHomeScreen()),
                  );
                },
              ),
              const SizedBox(height: 8),
              _buildMenuItem(
                icon: Icons.shopping_bag,
                title: 'Mis Pedidos',
                subtitle: 'Ver historial de pedidos',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyOrdersScreen())),
              ),
              const SizedBox(height: 8),
              _buildMenuItem(
                icon: Icons.inventory_2,
                title: 'Mis Productos',
                subtitle: 'Gestionar ofertas y ventas',
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const MainShell()),
                  );
                },
              ),
              const SizedBox(height: 8),
              _buildMenuItem(
                icon: Icons.receipt_long,
                title: 'Pedidos pendientes',
                subtitle: 'Ver reservas con pago en sucursal',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MerchantPendingOrdersScreen(),
                    ),
                  );
               },
             ),
            ] else ...[
              _buildMenuItem(
                icon: Icons.shopping_bag,
                title: 'Mis Pedidos',
                subtitle: 'Ver historial de pedidos',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyOrdersScreen())),
              ),
              const SizedBox(height: 8),
              _buildMenuItem(
                icon: Icons.favorite,
                title: 'Favoritos',
                subtitle: 'Productos guardados',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FavoritesScreen()),
                ),
              ),
              const SizedBox(height: 8),
              _buildMenuItem(
                icon: Icons.location_on,
                title: 'Mis Direcciones',
                subtitle: 'Gestionar direcciones de entrega',
                onTap: () {},
              ),
              const SizedBox(height: 8),
              _buildMenuItem(
                icon: Icons.notifications,
                title: 'Notificaciones',
                subtitle: 'Configurar alertas',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AlertsScreen()),
                ),
              ),
            ],
            const SizedBox(height: 8),
            _buildMenuItem(
              icon: Icons.settings,
              title: 'Configuración',
              subtitle: 'Ajustes de la cuenta',
              onTap: () {},
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await _authRepo.logout();
                  if (mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                },
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text(
                  'Cerrar Sesión',
                  style: TextStyle(color: Colors.red),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: Colors.red),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: AppColors.textSecondary,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}