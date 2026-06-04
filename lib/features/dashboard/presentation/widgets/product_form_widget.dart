import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:reduccion_desperdicio_alimentos/core/theme/app_colors.dart';
import 'package:reduccion_desperdicio_alimentos/core/services/cloudinary_service.dart';
import 'package:reduccion_desperdicio_alimentos/shared/widgets/custom_input.dart';
import 'package:reduccion_desperdicio_alimentos/shared/widgets/custom_button.dart';
import 'package:reduccion_desperdicio_alimentos/shared/widgets/custom_label.dart';
import 'package:reduccion_desperdicio_alimentos/features/dashboard/data/repositories/dashboard_repository.dart';
import 'package:reduccion_desperdicio_alimentos/features/dashboard/data/models/oferta_model.dart';
import 'package:reduccion_desperdicio_alimentos/features/home/data/models/product_model.dart';

class ProductFormWidget extends StatefulWidget {
  final OfertaModel? oferta;
  final VoidCallback? onSuccess;

  const ProductFormWidget({super.key, this.oferta, this.onSuccess});

  @override
  State<ProductFormWidget> createState() => _ProductFormWidgetState();
}

class _ProductFormWidgetState extends State<ProductFormWidget> {
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
  String? _existingImageUrl;

  bool get _isEditing => widget.oferta != null;

  @override
  void initState() {
    super.initState();
    if (!_isEditing) {
      final now = DateTime.now();
      _pickupStart = now;
      _pickupStartTime = TimeOfDay.fromDateTime(now);
      _pickupEnd = now.add(const Duration(days: 7));
      _pickupEndTime = TimeOfDay.fromDateTime(now.add(const Duration(days: 7)));
    }
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    _commerceId = await _repo.getCommerceIdInt();
    if (!mounted) return;
    await _cargarCategorias();
    if (!mounted) return;
    if (_isEditing) _precargarDatos();
  }

  void _precargarDatos() {
    final o = widget.oferta!;
    titleController.text = o.title;
    descriptionController.text = o.description;
    priceController.text = o.price.toString();
    originalPriceController.text = o.originalPrice.toString();
    quantityController.text = o.quantity.toString();
    _existingImageUrl = o.imageUrl;
    _pickupStart = o.pickupStart;
    _pickupStartTime = TimeOfDay.fromDateTime(o.pickupStart);
    _pickupEnd = o.pickupEnd;
    _pickupEndTime = TimeOfDay.fromDateTime(o.pickupEnd);
  }

  Future<void> _cargarCategorias() async {
    try {
      final cats = await _repo.getCategorias();
      if (mounted) {
        setState(() {
          _categorias = cats;
          _categoriasCargadas = true;
          if (_isEditing) {
            final catName = widget.oferta!.categoryName;
            if (catName != null) {
              _categoriaSeleccionada = _categorias.firstWhere(
                (c) => c.name == catName,
                orElse: () => _categorias.first,
              );
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _categoriasCargadas = true);
        _showSnack('Error al cargar categorías: ${e.toString().replaceFirst("Exception: ", "")}');
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
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isUploadingImage = false);
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
    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: _pickupStartTime ?? TimeOfDay.now(),
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
    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: _pickupEndTime ?? TimeOfDay.now(),
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
      _showSnack('Selecciona una categoría');
      return;
    }
    if (_pickupStart == null || _pickupStartTime == null) {
      _showSnack('Selecciona inicio de recogida');
      return;
    }
    if (_pickupEnd == null || _pickupEndTime == null) {
      _showSnack('Selecciona fin de recogida');
      return;
    }
    if (!_isEditing && _selectedImage == null) {
      _showSnack('La imagen del producto es obligatoria');
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
      if (imageUrl == null && _selectedImage != null) {
        imageUrl = await _cloudinary.uploadImage(_selectedImage!);
      }
      if (imageUrl == null && _isEditing) {
        imageUrl = _existingImageUrl;
      }

      if (_isEditing) {
        await _repo.updateProduct(widget.oferta!.id, {
          'title': titleController.text.trim(),
          'description': descriptionController.text.trim(),
          'originalPrice': double.parse(originalPriceController.text),
          'price': double.parse(priceController.text),
          'quantity': int.parse(quantityController.text),
          'pickupStart': pickupStartDT.toUtc().toIso8601String(),
          'pickupEnd': pickupEndDT.toUtc().toIso8601String(),
          'categoryId': _categoriaSeleccionada!.id,
          if (imageUrl != null) 'imageUrl': imageUrl,
        });
        if (mounted) {
          _showSnack('Producto actualizado exitosamente');
          widget.onSuccess?.call();
          Navigator.pop(context);
        }
      } else {
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
          _showSnack('Producto publicado exitosamente');
          _resetForm();
          widget.onSuccess?.call();
        }
      }
    } catch (e) {
      if (mounted) _showSnack(e.toString());
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
      _existingImageUrl = null;
      _categoriaSeleccionada = null;
      _pickupStart = null;
      _pickupStartTime = null;
      _pickupEnd = null;
      _pickupEndTime = null;
    });
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _formatDateTime(DateTime date, TimeOfDay time) {
    const days = ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];
    final dayName = days[date.weekday - 1];
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$dayName ${date.day}/${date.month} $h:$m';
  }

  String _formatDateOnly(DateTime date) {
    const days = ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];
    final dayName = days[date.weekday - 1];
    return '$dayName ${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Producto' : 'Publicar Excedente'),
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
                    Text(
                      _isEditing ? 'Editar producto' : 'Describe tu producto',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isEditing ? 'Modifica los datos de tu producto.' : 'Completa los datos del excedente que deseas vender.',
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
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
                          hint: const Text('Selecciona categoría'),
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
                    _buildImageSection(),
                    const SizedBox(height: 16),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ventana de recogida',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'La ventana empieza hoy ${_formatDateOnly(DateTime.now())} y dura hasta 7 días.',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 16),
                          CustomLabel('Inicio *'),
                          InkWell(
                            onTap: _selectPickupStart,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.play_arrow, color: AppColors.primary, size: 20),
                                  const SizedBox(width: 10),
                                  Text(
                                    _pickupStart != null && _pickupStartTime != null
                                        ? _formatDateTime(_pickupStart!, _pickupStartTime!)
                                        : 'Selecciona fecha y hora',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: _pickupStart != null ? AppColors.textPrimary : AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          CustomLabel('Fin *'),
                          InkWell(
                            onTap: _selectPickupEnd,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.stop, color: Colors.red, size: 20),
                                  const SizedBox(width: 10),
                                  Text(
                                    _pickupEnd != null && _pickupEndTime != null
                                        ? _formatDateTime(_pickupEnd!, _pickupEndTime!)
                                        : 'Selecciona fecha y hora',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: _pickupEnd != null ? AppColors.textPrimary : AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    CustomButton(
                      text: isLoading
                          ? (_isEditing ? 'Actualizando...' : 'Publicando...')
                          : (_isEditing ? 'ACTUALIZAR PRODUCTO' : 'PUBLICAR PRODUCTO'),
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

  Widget _buildImageSection() {
    return GestureDetector(
      onTap: (_isUploadingImage || isLoading) ? null : _showImageSourceOptions,
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
                    Text('Subiendo imagen...', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  ],
                ),
              )
            : _selectedImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(File(_selectedImage!.path), fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const Icon(Icons.image_not_supported, color: AppColors.textSecondary, size: 40),
                        ),
                        Positioned(
                          top: 8, right: 8,
                          child: GestureDetector(
                            onTap: () => setState(() {
                              _selectedImage = null;
                              if (_isEditing) _existingImageUrl = null;
                            }),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                              child: const Icon(Icons.close, size: 18, color: AppColors.primary),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : _isEditing && _existingImageUrl != null && _existingImageUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(_existingImageUrl!, fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => _buildImagePlaceholder(),
                            ),
                            Positioned(
                              top: 8, right: 8,
                              child: GestureDetector(
                                onTap: () => setState(() {
                                  _selectedImage = null;
                                  _existingImageUrl = null;
                                }),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                  child: const Icon(Icons.close, size: 18, color: AppColors.primary),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : _buildImagePlaceholder(),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.add_photo_alternate_outlined, size: 40, color: AppColors.textSecondary),
        const SizedBox(height: 8),
        Text(
          _isEditing ? 'Toca para cambiar imagen' : 'Toca para añadir imagen',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
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
