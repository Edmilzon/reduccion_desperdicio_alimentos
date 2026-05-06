import 'package:flutter/material.dart';
import '../../../../shared/widgets/custom_input.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../home/presentation/screens/client_home_screen.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/models/auth_model.dart';
import 'account_type_screen.dart';
import '../../../../shared/widgets/main_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _authRepository = AuthRepository();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  bool obscurePassword = true;
  bool isLoading = false;

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final authResponse = await _authRepository.login(
        emailController.text.trim(),
        passwordController.text,
      );

      if (mounted) {
        _navigateByRole(authResponse.user);
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

  void _navigateByRole(UserModel user) {
    final destination = user.isMerchant
        ? const MainShell()
        : const ClientHomeScreen();
    
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => destination),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),

                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                ),

                const SizedBox(height: 10),

                const Text(
                  "Inicio de Sesión",
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 40),

                CustomInput(
                  controller: emailController,
                  hint: "Ej: usuario@email.com",
                  label: "Correo electrónico",
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "El correo es obligatorio";
                    }

                    final emailRegex = RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    );

                    if (!emailRegex.hasMatch(value)) {
                      return "Correo no válido";
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 20),

                CustomInput(
                  controller: passwordController,
                  hint: "********",
                  label: "Contraseña",
                  obscureText: obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        obscurePassword = !obscurePassword;
                      });
                    },
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "La contraseña es obligatoria";
                    }

                    if (value.length < 6) {
                      return "Mínimo 6 caracteres";
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 10),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    child: const Text(
                      "¿Olvidaste tu contraseña?",
                      style: TextStyle(color: Colors.black87),
                    ),
                  ),
                ),

                const SizedBox(height: 80),

                CustomButton(
                  text: isLoading ? "Cargando..." : "Iniciar Sesión",
                  isLoading: isLoading,
                  onPressed: isLoading ? null : _handleLogin,
                ),

                const SizedBox(height: 30),

                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("¿No tienes cuenta? "),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AccountTypeScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          "Crear cuenta",
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}