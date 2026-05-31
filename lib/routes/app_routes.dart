import 'package:flutter/material.dart';
import 'package:reduccion_desperdicio_alimentos/features/auth/presentation/screens/login_screen.dart';
import 'package:reduccion_desperdicio_alimentos/features/auth/presentation/screens/account_type_screen.dart';
import 'package:reduccion_desperdicio_alimentos/features/auth/presentation/screens/user_register_screen.dart';
import 'package:reduccion_desperdicio_alimentos/features/auth/presentation/screens/commerce_register_screen.dart';
import 'package:reduccion_desperdicio_alimentos/features/auth/presentation/screens/commerce_access_screen.dart';
import 'package:reduccion_desperdicio_alimentos/features/home/presentation/screens/client_home_screen.dart';
import 'package:reduccion_desperdicio_alimentos/features/restaurant_detail/presentation/screens/restaurant_detail_screen.dart';
import 'package:reduccion_desperdicio_alimentos/shared/widgets/main_shell.dart';

class AppRoutes {
  static Route<dynamic>? generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/login':
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case '/account-type':
        return MaterialPageRoute(builder: (_) => const AccountTypeScreen());
      case '/user-register':
        return MaterialPageRoute(builder: (_) => const UserRegisterScreen());
      case '/commerce-register':
        return MaterialPageRoute(builder: (_) => const CommerceRegisterScreen());
      case '/commerce-access':
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => CommerceAccessScreen(
            ownerName: args?['ownerName'] ?? '',
            commerceName: args?['commerceName'] ?? '',
            phone: args?['phone'] ?? '',
            nit: args?['nit'] ?? '',
            description: args?['description'] ?? '',
            latitude: args?['latitude'] as double?,
            longitude: args?['longitude'] as double?,
          ),
        );
      case '/client-home':
        return MaterialPageRoute(builder: (_) => const ClientHomeScreen());
      case '/merchant-home':
        return MaterialPageRoute(builder: (_) => const MainShell());
      case '/restaurant-detail':
        final args = settings.arguments as Map<String, dynamic>?;
        final commerceId = args?['commerceId'] as int? ?? 0;
        return MaterialPageRoute(
          builder: (_) => RestaurantDetailScreen(commerceId: commerceId),
        );
      default:
        return null;
    }
  }
}