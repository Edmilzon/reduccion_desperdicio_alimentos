import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:reduccion_desperdicio_alimentos/core/theme/app_colors.dart';
import 'package:reduccion_desperdicio_alimentos/core/services/cloudinary_service.dart';
import 'package:reduccion_desperdicio_alimentos/shared/widgets/custom_input.dart';
import 'package:reduccion_desperdicio_alimentos/shared/widgets/custom_button.dart';
import 'package:reduccion_desperdicio_alimentos/shared/widgets/custom_label.dart';
import 'package:reduccion_desperdicio_alimentos/features/dashboard/data/repositories/dashboard_repository.dart';

class CreateProductScreen extends StatefulWidget {
  final VoidCallback? onSuccess;

  const CreateProductScreen({super.key, this.onSuccess});

  @override
  State<CreateProductScreen> createState() => _CreateProductScreenState();
}

class _CreateProductScreenState extends State<CreateProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repo = DashboardRepository();
  final _cloudinary = CloudinaryService();

  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final priceController = TextEditingController();
  final originalPriceController = TextEditingController();
  final quantityController = TextEditingController();

  List<CategoryModel> _categorias = [];
  CategoryModel? _categoriaSeleccionada;
  DateTime? _pickupStart;
  TimeOfDay? _pickupStartTime;
  DateTime? _pickupEnd;
  TimeOfDay? _pickupEndTime;
  bool isLoading = false;
  bool _categoriasCargadas = false;
  int _commerceId = 0;
  XFile? _selectedImage;
  bool _isUploadingImage = false;
  String? _uploadedImageUrl;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    _commerceId = await _repo.getCommerceIdInt();
    await _cargarCategorias();
  }

  Future<void> _cargarCategorias() async {
    try {
      final cats = await _repo.getCategorias();
      if (mounted) {
        setState(() {
          _categorias = cats;
          _categoriasCargadas = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _categoriasCargadas = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  void _showImageSourceOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galería'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Cámara'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _cloudinary.pickImage(source);

      if (image != null && mounted) {
        setState(() {
          _selectedImage = image;
          _uploadedImageUrl = null;
          _isUploadingImage = true;
        });

        final url = await _cloudinary.uploadImage(image);

        if (mounted) {
          setState(() {
            _isUploadingImage = false;
            _uploadedImageUrl = url;
          });

          if (url != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Imagen subida exitosamente')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Error al subir imagen')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al subir imagen: $e')),
        );
      }
    }
  }

  String? validarRequerido(String? v, String msg) {
    if (v == null || v.isEmpty) return msg;
    return null;
  }

  String? validarRelacionPrecios(String? v) {
    if (v == null || v.isEmpty) return 'El precio oferta es obligatorio';
    final precio = double.tryParse(v);
    if (precio == null || precio <= 0) return 'Precio inválido';
    final original = double.tryParse(originalPriceController.text);
    if (original != null && precio >= original) {
      return 'Precio oferta debe ser menor al original';
    }
    return null;
  }

  String? validarQuantity(String? v) {
    if (v == null || v.isEmpty) return 'Las unidades son obligatorias';
    final q = int.tryParse(v);
    if (q == null || q <= 0) return 'Unidades inválidas';
    return null;
  }

  String? validarPrecioOriginal(String? v) {
    if (v == null || v.isEmpty) return 'El precio original es obligatorio';
    final p = double.tryParse(v);
    if (p == null || p <= 0) return 'Precio inválido';
    return null;
  }

  Future<void> _selectPickupStart() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _pickupStart ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 7)),
    );
    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: _pickupStartTime ?? const TimeOfDay(hour: 10, minute: 0),
      );
      if (time != null) {
        setState(() {
          _pickupStart = date;
          _pickupStartTime = time;
        });
      }
    }
  }

  Future<void> _selectPickupEnd() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _pickupEnd ?? _pickupStart ?? DateTime.now(),
      firstDate: _pickupStart ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 7)),
    );
    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: _pickupEndTime ?? const TimeOfDay(hour: 20, minute: 0),
      );
      if (time != null) {
        setState(() {
          _pickupEnd = date;
          _pickupEndTime = time;
        });
      }
    }
  }

  DateTime _combineDateTime(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoriaSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una categoría')),
      );
      return;
    }
    if (_pickupStart == null || _pickupStartTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona inicio de recogida')),
      );
      return;
    }
    if (_pickupEnd == null || _pickupEndTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona fin de recogida')),
      );
      return;
    }
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La imagen del producto es obligatoria')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final pickupStartDT = _combineDateTime(_pickupStart!, _pickupStartTime!);
      final pickupEndDT = _combineDateTime(_pickupEnd!, _pickupEndTime!);

      if (pickupEndDT.isBefore(pickupStartDT) || pickupEndDT.isAtSameMomentAs(pickupStartDT)) {
        throw Exception('La fecha fin debe ser posterior al inicio de recogida');
      }

      String? imageUrl = _uploadedImageUrl;
      if (imageUrl == null) {
        imageUrl = await _cloudinary.uploadImage(_selectedImage!);
      }

      await _repo.createProduct(
        title: titleController.text.trim(),
        description: descriptionController.text.trim(),
        originalPrice: double.parse(originalPriceController.text),
        price: double.parse(priceController.text),
        quantity: int.parse(quantityController.text),
        pickupStart: pickupStartDT,
        pickupEnd: pickupEndDT,
        commerceId: _commerceId,
        categoryId: _categoriaSeleccionada!.id,
        imageUrl: imageUrl,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Producto publicado exitosamente')),
        );
        _resetForm();
        widget.onSuccess?.call();
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

  void _resetForm() {
    titleController.clear();
    descriptionController.clear();
    priceController.clear();
    originalPriceController.clear();
    quantityController.clear();
    setState(() {
      _selectedImage = null;
      _uploadedImageUrl = null;
      _categoriaSeleccionada = null;
      _pickupStart = null;
      _pickupStartTime = null;
      _pickupEnd = null;
      _pickupEndTime = null;
    });
  }

  String _formatDateTime(DateTime date, TimeOfDay time) {
    return '${date.day}/${date.month} a las ${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Publicar Excedente'),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: !_categoriasCargadas
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Describe tu producto',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Completa los datos del excedente que deseas vender.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),

              CustomLabel('Nombre del producto *'),
              CustomInput(
                controller: titleController,
                hint: 'Ej: Pan Integral Artesano',
                validator: (v) => validarRequerido(v, 'El nombre es obligatorio'),
              ),
              const SizedBox(height: 16),

              CustomLabel('Descripción (opcional)'),
              CustomInput(
                controller: descriptionController,
                hint: 'Describe tu producto...',
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              CustomLabel('Categoría *'),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<CategoryModel>(
                    value: _categoriaSeleccionada,
                    isExpanded: true,
                    hint: Text(_categoriasCargadas
                        ? 'Selecciona categoría'
                        : 'Cargando...'),
                    items: _categorias.map((c) => DropdownMenuItem(
                          value: c,
                          child: Text(c.name),
                        )).toList(),
                    onChanged: (v) => setState(() => _categoriaSeleccionada = v),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomLabel('Precio oferta *'),
                        CustomInput(
                          controller: priceController,
                          hint: '0.00',
                          keyboardType: TextInputType.number,
                          validator: validarRelacionPrecios,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomLabel('Precio original *'),
                        CustomInput(
                          controller: originalPriceController,
                          hint: '0.00',
                          keyboardType: TextInputType.number,
                          validator: validarPrecioOriginal,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              CustomLabel('Unidades disponibles *'),
              CustomInput(
                controller: quantityController,
                hint: '1',
                keyboardType: TextInputType.number,
                validator: validarQuantity,
              ),
              const SizedBox(height: 16),

              CustomLabel('Imagen del producto'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _isUploadingImage ? null : _showImageSourceOptions,
                child: Container(
                  width: double.infinity,
                  height: 160,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: _isUploadingImage
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(color: AppColors.primary),
                              SizedBox(height: 8),
                              Text(
                                'Subiendo imagen...',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        )
                      : _selectedImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.file(
                                    File(_selectedImage!.path),
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Icons.image_not_supported,
                                      color: AppColors.textSecondary,
                                      size: 40,
                                    ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: GestureDetector(
                                      onTap: () => setState(() => _selectedImage = null),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          size: 18,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : _buildImagePlaceholder(),
                ),
              ),
              const SizedBox(height: 16),

              CustomLabel('Inicio de recogida *'),
              InkWell(
                onTap: _selectPickupStart,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time, color: AppColors.textSecondary),
                      const SizedBox(width: 12),
                      Text(
                        _pickupStart != null && _pickupStartTime != null
                            ? _formatDateTime(_pickupStart!, _pickupStartTime!)
                            : 'Selecciona fecha y hora',
                        style: TextStyle(
                          color: _pickupStart != null
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              CustomLabel('Fin de recogida *'),
              InkWell(
                onTap: _selectPickupEnd,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time, color: AppColors.textSecondary),
                      const SizedBox(width: 12),
                      Text(
                        _pickupEnd != null && _pickupEndTime != null
                            ? _formatDateTime(_pickupEnd!, _pickupEndTime!)
                            : 'Selecciona fecha y hora',
                        style: TextStyle(
                          color: _pickupEnd != null
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              CustomButton(
                text: isLoading ? 'Publicando...' : 'PUBLICAR PRODUCTO',
                isLoading: isLoading,
                onPressed: isLoading ? null : _handleSubmit,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Icon(
          Icons.add_photo_alternate_outlined,
          size: 40,
          color: AppColors.textSecondary,
        ),
        SizedBox(height: 8),
        Text(
          'Toca para añadir imagen',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    originalPriceController.dispose();
    quantityController.dispose();
    super.dispose();
  }
}