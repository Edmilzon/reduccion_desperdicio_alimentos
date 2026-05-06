import 'package:flutter/material.dart';
import 'package:reduccion_desperdicio_alimentos/core/theme/app_colors.dart';
import 'package:reduccion_desperdicio_alimentos/shared/widgets/custom_input.dart';
import 'package:reduccion_desperdicio_alimentos/shared/widgets/custom_button.dart';
import 'package:reduccion_desperdicio_alimentos/shared/widgets/custom_label.dart';
import 'package:reduccion_desperdicio_alimentos/features/dashboard/data/repositories/dashboard_repository.dart';

class CreateProductScreen extends StatefulWidget {
  const CreateProductScreen({super.key});

  @override
  State<CreateProductScreen> createState() => _CreateProductScreenState();
}

class _CreateProductScreenState extends State<CreateProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repo = DashboardRepository();

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  String? validarRequerido(String? v, String msg) {
    if (v == null || v.isEmpty) return msg;
    return null;
  }

  String? validarPrecio(String? v) {
    if (v == null || v.isEmpty) return 'El precio es obligatorio';
    final p = double.tryParse(v);
    if (p == null || p <= 0) return 'Precio inválido';
    return null;
  }

  String? validarQuantity(String? v) {
    if (v == null || v.isEmpty) return 'Las unidades son obligatorias';
    final q = int.tryParse(v);
    if (q == null || q <= 0) return 'Unidades inválidas';
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

    setState(() => isLoading = true);

    try {
      final pickupStartDT = _combineDateTime(_pickupStart!, _pickupStartTime!);
      final pickupEndDT = _combineDateTime(_pickupEnd!, _pickupEndTime!);

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
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Producto publicado exitosamente')),
        );
        Navigator.pop(context, true);
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
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
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
                          validator: validarPrecio,
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
                          validator: validarPrecio,
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