import 'package:flutter/material.dart';
import 'package:reduccion_desperdicio_alimentos/core/services/location_service.dart';
import 'commerce_access_screen.dart';
import 'login_screen.dart';
import '../../../../shared/widgets/custom_input.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/custom_label.dart';
import '../../../../core/theme/app_colors.dart';

class CommerceRegisterScreen extends StatefulWidget {
  const CommerceRegisterScreen({super.key});

  @override
  State<CommerceRegisterScreen> createState() =>
      _CommerceRegisterScreenState();
}

class _CommerceRegisterScreenState extends State<CommerceRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _locationService = LocationService();

  final ownerController = TextEditingController();
  final commerceController = TextEditingController();
  final phoneController = TextEditingController();
  final nitController = TextEditingController();
  final descriptionController = TextEditingController();

  bool isLoading = false;
  bool _isGettingLocation = false;
  double? _latitude;
  double? _longitude;

  String? requiredField(String? value, String message) {
    if (value == null || value.trim().isEmpty) {
      return message;
    }
    return null;
  }

  String? minLength(String? value, int min, String message) {
    if (value == null || value.length < min) {
      return message;
    }
    return null;
  }

  String? onlyLetters(String? value) {
    if (value == null || value.isEmpty) return null;
    final regex = RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ ]+$');
    if (!regex.hasMatch(value)) {
      return "Solo letras permitidas";
    }
    return null;
  }

  String? phoneValidator(String? value) {
    if (value == null || value.isEmpty) {
      return "El teléfono es obligatorio";
    }
    final regex = RegExp(r'^[0-9]{8,12}$');
    if (!regex.hasMatch(value)) {
      return "Debe tener entre 8 y 12 dígitos";
    }
    return null;
  }

  Future<void> _getLocation() async {
    setState(() => _isGettingLocation = true);
    try {
      final position = await _locationService.getCurrentPosition();
      if (mounted) {
        setState(() {
          _latitude = position.latitude;
          _longitude = position.longitude;
          _isGettingLocation = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ubicación obtenida correctamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGettingLocation = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al obtener ubicación: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              const Text(
                "Registra tu restaurante",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 25),

              const CustomLabel("Nombre del restaurante"),
              CustomInput(
                hint: "Ej: Pollos Copacabana",
                controller: commerceController,
                validator: (v) {
                  return requiredField(
                        v,
                        "El nombre del restaurante es obligatorio",
                      ) ??
                      minLength(v, 3, "Mínimo 3 caracteres");
                },
              ),

              const SizedBox(height: 15),

              const CustomLabel("Nombre del propietario"),
              CustomInput(
                hint: "Ej: Juan Pérez",
                controller: ownerController,
                validator: (v) {
                  return requiredField(
                        v,
                        "El nombre del propietario es obligatorio",
                      ) ??
                      onlyLetters(v);
                },
              ),

              const SizedBox(height: 15),

              const CustomLabel("Teléfono"),
              CustomInput(
                hint: "+591 7XXXXXXX",
                controller: phoneController,
                keyboardType: TextInputType.phone,
                validator: phoneValidator,
              ),

              const SizedBox(height: 15),

              const CustomLabel("NIT (opcional)"),
              CustomInput(
                hint: "Ej: 123456789",
                controller: nitController,
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 15),

              const CustomLabel("Descripción (opcional)"),
              CustomInput(
                hint: "Ej: Comida rápida, delivery...",
                controller: descriptionController,
                maxLines: 3,
              ),

              const SizedBox(height: 15),

              const CustomLabel("Ubicación (opcional)"),
              const Text(
                "Agrega la ubicación de tu restaurante para que los clientes te encuentren fácilmente",
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _isGettingLocation ? null : _getLocation,
                icon: _isGettingLocation
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(_latitude != null ? Icons.check_circle : Icons.location_on),
                label: Text(_latitude != null
                    ? "Ubicación obtenida"
                    : _isGettingLocation
                        ? "Obteniendo..."
                        : "Obtener ubicación actual"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _latitude != null ? Colors.green : AppColors.primary,
                  side: BorderSide(
                    color: _latitude != null ? Colors.green : AppColors.primary,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              CustomButton(
                text: "SIGUIENTE",
                isLoading: isLoading,
                onPressed: () async {
                  if (!_formKey.currentState!.validate()) return;

                  final navigator = Navigator.of(context);
                  setState(() => isLoading = true);

                  await Future.delayed(const Duration(milliseconds: 500));

                  setState(() => isLoading = false);

                  if (!mounted) return;
                  navigator.push(
                    MaterialPageRoute(
                      builder: (_) => CommerceAccessScreen(
                        ownerName: ownerController.text.trim(),
                        commerceName: commerceController.text.trim(),
                        phone: phoneController.text.trim(),
                        nit: nitController.text.trim(),
                        description: descriptionController.text.trim(),
                        latitude: _latitude,
                        longitude: _longitude,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              Center(
                child: Column(
                  children: [
                    const Text("¿Ya tienes una cuenta?"),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        "Iniciar sesión",
                        style: TextStyle(color: Colors.green),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}