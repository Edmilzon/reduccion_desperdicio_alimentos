import 'package:flutter/material.dart';
import '../../data/repositories/auth_repository.dart';
import 'login_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;

  const ResetPasswordScreen({
    Key? key,
    required this.email,
  }) : super(key: key);

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tokenController = TextEditingController();
  final _passController = TextEditingController();
  final _confirmPassController = TextEditingController();
  final _authRepo = AuthRepository();

  bool _isObscure1 = true;
  bool _isObscure2 = true;
  bool _isLoading = false;

  bool get _hasMinLength => _passController.text.length >= 8;
  bool get _hasUppercase => RegExp(r'[A-Z]').hasMatch(_passController.text);
  bool get _hasNumber => RegExp(r'[0-9]').hasMatch(_passController.text);
  bool get _doPasswordsMatch =>
      _passController.text == _confirmPassController.text &&
      _confirmPassController.text.isNotEmpty;
  bool get _isPasswordValid =>
      _hasMinLength && _hasUppercase && _hasNumber && _doPasswordsMatch;

  @override
  void initState() {
    super.initState();
    _passController.addListener(() => setState(() {}));
    _confirmPassController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _passController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _authRepo.resetPassword(
        widget.email,
        _tokenController.text.trim(),
        _passController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Contraseña actualizada con éxito.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Restablecer Contraseña')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Correo: ${widget.email}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _tokenController,
                decoration: const InputDecoration(
                  labelText: 'Código de recuperación',
                  prefixIcon: Icon(Icons.vpn_key_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa el código recibido por correo';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _passController,
                obscureText: _isObscure1,
                decoration: InputDecoration(
                  labelText: 'Nueva contraseña',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_isObscure1 ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _isObscure1 = !_isObscure1),
                  ),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              _buildPasswordRequirements(),
              const SizedBox(height: 24),
              TextFormField(
                controller: _confirmPassController,
                obscureText: _isObscure2,
                decoration: InputDecoration(
                  labelText: 'Confirmar contraseña',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_isObscure2 ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _isObscure2 = !_isObscure2),
                  ),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              if (_confirmPassController.text.isNotEmpty)
                Text(
                  _doPasswordsMatch
                      ? '✓ Las contraseñas coinciden'
                      : '✗ Las contraseñas no coinciden',
                  style: TextStyle(
                    color: _doPasswordsMatch ? Colors.green : Colors.red,
                    fontSize: 12,
                  ),
                ),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: (_isLoading || !_isPasswordValid) ? null : _submit,
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Restablecer Contraseña'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordRequirements() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _requirementRow('Mínimo 8 caracteres', _hasMinLength),
        _requirementRow('Al menos una mayúscula', _hasUppercase),
        _requirementRow('Al menos un número', _hasNumber),
      ],
    );
  }

  Widget _requirementRow(String text, bool satisfied) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          Icon(
            satisfied ? Icons.check_circle : Icons.circle_outlined,
            size: 14,
            color: satisfied ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(fontSize: 12, color: satisfied ? Colors.green : Colors.grey[600])),
        ],
      ),
    );
  }
}
