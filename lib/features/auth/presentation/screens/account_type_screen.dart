import 'package:flutter/material.dart';
import 'user_register_screen.dart';
import 'commerce_register_screen.dart';
import 'login_screen.dart';

class AccountTypeScreen extends StatefulWidget {
  const AccountTypeScreen({super.key});

  @override
  State<AccountTypeScreen> createState() => _AccountTypeScreenState();
}

class _AccountTypeScreenState extends State<AccountTypeScreen> {
  String selectedType = "";

  void selectType(String type) {
    setState(() {
      selectedType = type;
    });
  }

  void navigate() {
    if (selectedType == "Usuario") {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const UserRegisterScreen()),
      );
    } else if (selectedType == "Restaurante") {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CommerceRegisterScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 40),

            // LOGO
            Image.asset(
              'assets/images/logo.png',
              height: 100,
            ),

            const SizedBox(height: 20),

            const Text(
              "Crear una cuenta",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            const Text("¿Cómo vas a usar la app?"),

            const SizedBox(height: 30),

            // RESTAURANTE
            GestureDetector(
              onTap: () => selectType("Restaurante"),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: selectedType == "Restaurante"
                      ? Colors.red[200]
                      : Colors.grey[200],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Restaurante"),
                    if (selectedType == "Restaurante")
                      const Icon(Icons.check, color: Colors.green),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // USUARIO
            GestureDetector(
              onTap: () => selectType("Usuario"),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: selectedType == "Usuario"
                      ? Colors.red[200]
                      : Colors.grey[200],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Usuario"),
                    if (selectedType == "Usuario")
                      const Icon(Icons.check, color: Colors.green),
                  ],
                ),
              ),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: selectedType.isEmpty
                      ? Colors.grey
                      : Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                onPressed: selectedType.isEmpty ? null : navigate,
                child: const Text(
                  "COMENZAR",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),

            const SizedBox(height: 15),

            
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("¿Ya tienes cuenta? "),
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
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}