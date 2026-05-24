import 'package:flutter/material.dart';
import 'package:reduccion_desperdicio_alimentos/features/dashboard/presentation/widgets/product_form_widget.dart';

class CreateProductScreen extends StatefulWidget {
  final VoidCallback? onSuccess;

  const CreateProductScreen({super.key, this.onSuccess});

  @override
  State<CreateProductScreen> createState() => _CreateProductScreenState();
}

class _CreateProductScreenState extends State<CreateProductScreen> {
  @override
  Widget build(BuildContext context) {
    return ProductFormWidget(onSuccess: widget.onSuccess);
  }
}
