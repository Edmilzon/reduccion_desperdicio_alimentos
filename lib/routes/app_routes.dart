import 'package:flutter/material.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/account_type_screen.dart';
import '../features/auth/presentation/screens/user_register_screen.dart';
import '../features/auth/presentation/screens/commerce_register_screen.dart';
import '../features/auth/presentation/screens/commerce_access_screen.dart';
import '../features/home/presentation/screens/client_home_screen.dart';
import '../features/restaurant_detail/presentation/screens/restaurant_detail_screen.dart';
import '../shared/widgets/main_shell.dart';

class AppRoutes {
  static const String login = '/login';
  static const String accountType = '/account-type';
  static const String userRegister = '/user-register';
  static const String commerceRegister = '/commerce-register';
  static const String commerceAccess = '/commerce-access';
  static const String clientHome = '/client-home';
  static const String merchantHome = '/merchant-home';
  static const String restaurantDetail = '/restaurant-detail';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case accountType:
        return MaterialPageRoute(builder: (_) => const AccountTypeScreen());
      case userRegister:
        return MaterialPageRoute(builder: (_) => const UserRegisterScreen());
      case commerceRegister:
        return MaterialPageRoute(
          builder: (_) => const CommerceRegisterScreen(),
        );
      case commerceAccess:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => CommerceAccessScreen(
            ownerName: args?['ownerName']?.toString() ?? '',
            commerceName: args?['commerceName']?.toString() ?? '',
          ),
        );
      case clientHome:
        return MaterialPageRoute(builder: (_) => const ClientHomeScreen());
      case merchantHome:
        return MaterialPageRoute(builder: (_) => const MainShell());
      case restaurantDetail:
        final detailArgs = settings.arguments as Map<String, dynamic>?;
        final commerceId = detailArgs?['commerceId'] as int? ?? 0;
        return MaterialPageRoute(
          builder: (_) => RestaurantDetailScreen(commerceId: commerceId),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Ruta no encontrada')),
          ),
        );
    }
  }
}
