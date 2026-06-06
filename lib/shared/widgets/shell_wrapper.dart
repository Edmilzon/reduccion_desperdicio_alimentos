import 'package:flutter/material.dart';
import 'package:reduccion_desperdicio_alimentos/core/theme/app_colors.dart';
import 'package:reduccion_desperdicio_alimentos/shared/widgets/custom_navbar.dart';

class ShellWrapper extends StatefulWidget {
  final Widget child;

  const ShellWrapper({
    super.key,
    required this.child,
  });

  @override
  State<ShellWrapper> createState() => _ShellWrapperState();
}

class _ShellWrapperState extends State<ShellWrapper> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: widget.child,
      bottomNavigationBar: CustomNavbar(
        currentIndex: 0,
        onTap: (index) {
          Navigator.popUntil(context, (route) => route.isFirst);
        },
      ),
    );
  }
}
