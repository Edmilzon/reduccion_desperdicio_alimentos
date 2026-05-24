import 'package:flutter/material.dart';
import 'package:reduccion_desperdicio_alimentos/features/dashboard/data/models/oferta_model.dart';
import 'package:reduccion_desperdicio_alimentos/features/dashboard/presentation/widgets/product_form_widget.dart';

class EditProductScreen extends StatefulWidget {
  final OfertaModel oferta;
  final VoidCallback? onSuccess;

  const EditProductScreen({
    super.key,
    required this.oferta,
    this.onSuccess,
  });

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  @override
  Widget build(BuildContext context) {
    return ProductFormWidget(
      oferta: widget.oferta,
      onSuccess: widget.onSuccess,
    );
  }
}
