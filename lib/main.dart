import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:reduccion_desperdicio_alimentos/core/theme/app_colors.dart';
import 'package:reduccion_desperdicio_alimentos/features/auth/data/repositories/auth_repository.dart';
import 'package:reduccion_desperdicio_alimentos/features/auth/presentation/screens/login_screen.dart';
import 'package:reduccion_desperdicio_alimentos/features/home/presentation/screens/client_home_screen.dart';
import 'package:reduccion_desperdicio_alimentos/shared/widgets/main_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(MyApp(prefs: prefs));
}

class MyApp extends StatefulWidget {
  final SharedPreferences prefs;

  const MyApp({super.key, required this.prefs});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _checkingAuth = true;
  Widget? _initialScreen;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final authRepo = AuthRepository();
    final isLoggedIn = await authRepo.isLoggedIn();

    if (!isLoggedIn) {
      if (mounted) {
        setState(() {
          _checkingAuth = false;
          _initialScreen = const LoginScreen();
        });
      }
      return;
    }

    try {
      final user = await authRepo.fetchProfile();
      if (mounted) {
        setState(() {
          _initialScreen = user?.isMerchant == true
              ? const MainShell()
              : const ClientHomeScreen();
          _checkingAuth = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _checkingAuth = false;
          _initialScreen = const LoginScreen();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Eco Bocado',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        fontFamily: 'Roboto',
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
      ),
      home: _checkingAuth
          ? const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            )
          : _initialScreen,
    );
  }
}