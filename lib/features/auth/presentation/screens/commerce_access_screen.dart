import 'package:flutter/material.dart';
import 'login_screen.dart';
import '../../../../shared/widgets/custom_input.dart';
import '../../../../shared/widgets/custom_password_input.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/custom_label.dart';
import '../../data/repositories/auth_repository.dart';
import '../../../../shared/widgets/main_shell.dart';

class CommerceAccessScreen extends StatefulWidget {
  final String ownerName;
  final String commerceName;
  final String nit;
  final String description;
  final double? latitude;
  final double? longitude;

  const CommerceAccessScreen({
    super.key,
    required this.ownerName,
    required this.commerceName,
    required this.nit,
    required this.description,
    this.latitude,
    this.longitude,
  });

  @override
  State<CommerceAccessScreen> createState() =>
      _CommerceAccessScreenState();
}

class _CommerceAccessScreenState extends State<CommerceAccessScreen> {
  final _authRepository = AuthRepository();
  final _formKey = GlobalKey<FormState>();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
  bool acceptedTerms = false;
  bool isLoading = false;

  bool get passwordsMatch =>
      passwordController.text == confirmPasswordController.text;

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (!acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Debes aceptar los términos")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      await _authRepository.registerCommerce(
        ownerName: widget.ownerName,
        email: emailController.text.trim().toLowerCase(),
        password: passwordController.text,
        commerceName: widget.commerceName,
        nit: widget.nit.isNotEmpty ? widget.nit : null,
        description: widget.description.isNotEmpty ? widget.description : null,
        latitude: widget.latitude,
        longitude: widget.longitude,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Registro exitoso")),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainShell()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // ---------------- VALIDATORS ----------------

  String? emailValidator(String? value) {
    if (value == null || value.isEmpty) {
      return "El correo es obligatorio";
    }

    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!regex.hasMatch(value)) {
      return "Correo no válido";
    }

    return null;
  }

  String? passwordValidator(String? value) {
    if (value == null || value.isEmpty) {
      return "La contraseña es obligatoria";
    }

    if (value.length < 8) {
      return "Mínimo 8 caracteres";
    }

    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return "Debe tener una mayúscula";
    }

    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return "Debe tener un número";
    }

    return null;
  }

  String? confirmPasswordValidator(String? value) {
    if (value == null || value.isEmpty) {
      return "Confirma la contraseña";
    }

    if (!passwordsMatch) {
      return "Las contraseñas no coinciden";
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const BackButton()),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              const Text(
                "Crea tu acceso",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 25),

              // EMAIL
              const CustomLabel("Correo electrónico"),
              CustomInput(
                hint: "ej: negocio@email.com",
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                validator: emailValidator,
              ),

              const SizedBox(height: 15),

              const CustomLabel("Contraseña"),
              CustomPasswordInput(
                hint: "********",
                controller: passwordController,
                obscureText: obscurePassword,
                onToggle: () => setState(() => obscurePassword = !obscurePassword),
                onChanged: (_) => setState(() {}),
                validator: passwordValidator,
              ),

              const SizedBox(height: 15),

              const CustomLabel("Confirmar contraseña"),
              CustomPasswordInput(
                hint: "********",
                controller: confirmPasswordController,
                obscureText: obscureConfirmPassword,
                onToggle: () => setState(() => obscureConfirmPassword = !obscureConfirmPassword),
                onChanged: (_) => setState(() {}),
                validator: confirmPasswordValidator,
              ),

              const SizedBox(height: 10),

              if (confirmPasswordController.text.isNotEmpty)
                Text(
                  passwordsMatch
                      ? "✔ Contraseñas coinciden"
                      : "✖ No coinciden",
                  style: TextStyle(
                    color: passwordsMatch
                        ? Colors.green
                        : Colors.red,
                  ),
                ),

              const SizedBox(height: 20),

              Row(
                children: [
                  Checkbox(
                    value: acceptedTerms,
                    onChanged: (v) {
                      setState(() => acceptedTerms = v!);
                    },
                  ),
                  const Expanded(
                    child: Text("Acepto términos y condiciones"),
                  ),
                ],
              ),

              const SizedBox(height: 25),

              CustomButton(
                text: isLoading ? "Cargando..." : "REGISTRARSE",
                isLoading: isLoading,
                onPressed: isLoading ? null : _handleRegister,
              ),

              const SizedBox(height: 20),

              Center(
                child: Column(
                  children: [
                    const Text("¿Ya tienes cuenta?"),
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