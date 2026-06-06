import 'package:flutter/material.dart';
import '../../../../shared/widgets/custom_input.dart';
import '../../../../shared/widgets/custom_password_input.dart';
import '../../../../shared/widgets/custom_button.dart';
import 'login_screen.dart';
import '../../data/repositories/auth_repository.dart';
import '../../../home/presentation/screens/client_home_screen.dart';

class UserRegisterScreen extends StatefulWidget {
  const UserRegisterScreen({super.key});

  @override
  State<UserRegisterScreen> createState() =>
      _UserRegisterScreenState();
}

class _UserRegisterScreenState extends State<UserRegisterScreen> {
  final _authRepository = AuthRepository();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  bool showPassword = false;
  bool acceptedTerms = false;
  bool isLoading = false;

  String? nameValidator(String? value) {
    if (value == null || value.isEmpty) {
      return "El nombre es obligatorio";
    }
    if (value.length < 3) {
      return "Mínimo 3 caracteres";
    }
    if (!RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$').hasMatch(value)) {
      return "Solo letras permitidas";
    }
    return null;
  }

  String? emailValidator(String? value) {
    if (value == null || value.isEmpty) {
      return "El correo es obligatorio";
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return "Ingrese un correo electrónico válido";
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
      return "Debe contener una mayúscula";
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return "Debe contener un número";
    }
    return null;
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (!acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Debes aceptar los términos y condiciones")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      await _authRepository.register(
        name: nameController.text.trim(),
        email: emailController.text.trim().toLowerCase(),
        password: passwordController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Registro exitoso")),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ClientHomeScreen()),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
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
                "Crear cuenta",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              CustomInput(
                controller: nameController,
                hint: "Ej: Juan Pérez",
                label: "Nombre completo",
                validator: nameValidator,
              ),

              const SizedBox(height: 20),

              CustomInput(
                controller: emailController,
                hint: "ejemplo@email.com",
                label: "Correo electrónico",
                keyboardType: TextInputType.emailAddress,
                validator: emailValidator,
              ),

              const SizedBox(height: 20),

              CustomPasswordInput(
                hint: "********",
                controller: passwordController,
                obscureText: !showPassword,
                onToggle: () => setState(() => showPassword = !showPassword),
                validator: passwordValidator,
              ),

              const SizedBox(height: 20),

              Row(
                children: [
                  Checkbox(
                    value: acceptedTerms,
                    onChanged: (v) {
                      setState(() => acceptedTerms = v ?? false);
                    },
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() => acceptedTerms = !acceptedTerms);
                      },
                      child: const Text("Acepto términos y condiciones"),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              CustomButton(
                text: isLoading ? "Cargando..." : "INSCRIBIRSE",
                isLoading: isLoading,
                onPressed: isLoading ? null : _handleRegister,
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