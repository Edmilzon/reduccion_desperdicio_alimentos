import 'package:go_router/go_router.dart';
import '../features/auth/presentation/screens/reset_password_screen.dart';
// Asegúrate de importar correctamente tu AuthController
// import '../features/auth/controllers/auth_controller.dart'; 

final GoRouter appRouter = GoRouter(
  initialLocation: '/', // Reemplaza esto con tu ruta inicial (ej. el Login o el Home)
  routes: [
    // ... tus otras rutas (GoRoute) irían aquí ...

    // Ruta específica para capturar el Deep Link de recuperación de contraseña
    GoRoute(
      path: '/reset',
      builder: (context, state) {
        final token = state.uri.queryParameters['token'] ?? '';
        final email = state.uri.queryParameters['email'] ?? '';

        return ResetPasswordScreen(
          token: token,
          email: email,
          authController: AuthController(), // Reemplázalo por tu inyección (Provider/GetIt) si aplicara
        );
      },
    ),
  ],
);