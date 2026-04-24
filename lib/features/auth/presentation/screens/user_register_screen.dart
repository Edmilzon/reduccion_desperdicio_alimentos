import 'package:flutter/material.dart';
import '../../../../shared/widgets/custom_input.dart';
import '../../../../shared/widgets/custom_button.dart';
import 'login_screen.dart';

class UserRegisterScreen extends StatefulWidget {
  const UserRegisterScreen({super.key});

  @override
  State<UserRegisterScreen> createState() =>
      _UserRegisterScreenState();
}

class _UserRegisterScreenState extends State<UserRegisterScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  bool showPassword = false;
  bool isLoading = false;

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
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "El nombre es obligatorio";
                  }

                  if (value.length < 3) {
                    return "Mínimo 3 caracteres";
                  }

                  if (!RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ ]+$')
                      .hasMatch(value)) {
                    return "Solo letras permitidas";
                  }

                  return null;
                },
              ),

              const SizedBox(height: 20),

              CustomInput(
                controller: emailController,
                hint: "ejemplo@email.com",
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
                obscureText: !showPassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    showPassword
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      showPassword = !showPassword;
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

                  if (!RegExp(r'[A-Z]').hasMatch(value)) {
                    return "Debe contener una mayúscula";
                  }

                  if (!RegExp(r'[0-9]').hasMatch(value)) {
                    return "Debe contener un número";
                  }

                  return null;
                },
              ),

              const SizedBox(height: 30),

              CustomButton(
                text: isLoading
                    ? "Cargando..."
                    : "INSCRIBIRSE",
                onPressed: isLoading
                    ? null
                    : () async {
                        if (_formKey.currentState!.validate()) {
                          setState(() => isLoading = true);

                          await Future.delayed(
                            const Duration(seconds: 2),
                          );

                          setState(() => isLoading = false);

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Registro exitoso 🚀",
                              ),
                            ),
                          );

                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const Placeholder(),
                            ),
                          );
                        }
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