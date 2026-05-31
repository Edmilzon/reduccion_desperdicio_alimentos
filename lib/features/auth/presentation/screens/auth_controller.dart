import '../../data/repositories/auth_repository.dart';

/// Controlador simple para manejar los llamados al repositorio de autenticación.
/// Si estás usando un gestor de estado como Bloc o Riverpod, puedes adaptar
/// este proveedor según la herramienta.
class AuthController {
  final AuthRepository _repository;

  AuthController({AuthRepository? repository}) : _repository = repository ?? AuthRepository();

  Future<void> forgotPassword(String email) async {
    await _repository.forgotPassword(email);
  }

  Future<void> resetPassword(String email, String token, String newPassword) async {
    await _repository.resetPassword(email, token, newPassword);
  }
}