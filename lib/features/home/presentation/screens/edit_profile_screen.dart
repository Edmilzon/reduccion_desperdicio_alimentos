import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:reduccion_desperdicio_alimentos/core/theme/app_colors.dart';
import 'package:reduccion_desperdicio_alimentos/features/auth/data/repositories/auth_repository.dart';
import 'package:reduccion_desperdicio_alimentos/shared/widgets/custom_input.dart';
import 'package:reduccion_desperdicio_alimentos/shared/widgets/custom_button.dart';

class EditProfileScreen extends StatefulWidget {
  final bool isMerchant;

  const EditProfileScreen({super.key, this.isMerchant = false});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _authRepo = AuthRepository();
  final _nameController = TextEditingController();
  final _commerceNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _nitController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _commerceNameController.dispose();
    _descriptionController.dispose();
    _nitController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final user = await _authRepo.getCurrentUser();
      _nameController.text = user.name;
      if (widget.isMerchant) {
        final prefs = await SharedPreferences.getInstance();
        _commerceNameController.text = prefs.getString(AuthRepository.commerceNameKey) ?? '';
        _descriptionController.text = prefs.getString('commerce_description') ?? '';
        _nitController.text = prefs.getString('commerce_nit') ?? '';
      }
      if (mounted) setState(() => _isLoading = false);
    } catch (_) {
      if (mounted) setState(() { _isLoading = false; _error = 'Error al cargar perfil'; });
    }
  }

  Future<void> _save() async {
    setState(() { _isSaving = true; _error = null; });

    try {
      await _authRepo.updateProfile(name: _nameController.text.trim());

      if (widget.isMerchant) {
        final commerceId = await _authRepo.getCommerceId();
        if (commerceId != null) {
          await _authRepo.updateCommerce(
            commerceId: commerceId,
            name: _commerceNameController.text.trim(),
            description: _descriptionController.text.trim(),
            nit: _nitController.text.trim(),
          );
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil actualizado correctamente')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _isSaving = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Editar Perfil',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Información personal'),
                  const SizedBox(height: 12),
                  CustomInput(
                    controller: _nameController,
                    label: 'Nombre',
                    hint: 'Tu nombre',
                  ),
                  if (widget.isMerchant) ...[
                    const SizedBox(height: 24),
                    _buildSectionTitle('Información del comercio'),
                    const SizedBox(height: 12),
                    CustomInput(
                      controller: _commerceNameController,
                      label: 'Nombre del comercio',
                      hint: 'Nombre de tu tienda',
                    ),
                    const SizedBox(height: 12),
                    CustomInput(
                      controller: _descriptionController,
                      label: 'Descripción',
                      hint: 'Describe tu comercio',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    CustomInput(
                      controller: _nitController,
                      label: 'NIT',
                      hint: 'Número de identificación tributaria',
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 32),
                  CustomButton(
                    text: 'Guardar cambios',
                    isLoading: _isSaving,
                    onPressed: _isSaving ? null : _save,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }
}
