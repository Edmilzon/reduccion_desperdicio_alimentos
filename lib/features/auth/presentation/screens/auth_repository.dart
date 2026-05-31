import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthRepository {
  // Ajusta la URL a tu servidor backend real (ej. 10.0.2.2:3000 para Android Emulator)
  final String baseUrl = 'http://10.0.2.2:3000/auth';

  Future<void> forgotPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Error al procesar la solicitud');
      }
    } catch (e) {
      throw Exception('Fallo de red: $e');
    }
  }

  Future<void> resetPassword(String email, String token, String newPassword) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'token': token,
          'newPassword': newPassword,
        }),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        final data = jsonDecode(response.body);
        // Extrae exactamente el mensaje de NestJS: "Token inválido o expirado" o "No puedes repetir..."
        final errorMessage = data['message'];
        if (errorMessage is List) {
          throw Exception(errorMessage.join('\n'));
        }
        throw Exception(errorMessage ?? 'Error al restablecer la contraseña');
      }
    } catch (e) {
      // Mantiene intacta la excepción si es arrojada por la validación
      if (e.toString().contains('Exception:')) rethrow; 
      throw Exception('No se pudo conectar al servidor. Revisa tu internet.');
    }
  }
}