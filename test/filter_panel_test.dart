import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reduccion_desperdicio_alimentos/core/theme/app_colors.dart';
import 'package:reduccion_desperdicio_alimentos/features/home/data/models/product_model.dart';
import 'package:reduccion_desperdicio_alimentos/features/map/data/filter_store.dart';
import 'package:reduccion_desperdicio_alimentos/features/map/presentation/widgets/filter_panel.dart';

void main() {
  final store = FilterStore.instance;

  setUp(() {
    store.clearFilters();
    store.setActiveCategoriesForTest([
      CategoryModel(id: 1, name: 'Panadería', slug: 'panaderia'),
      CategoryModel(id: 4, name: 'Comida Rápida', slug: 'comida-rapida'),
    ]);
  });

  Widget buildPanel() {
    return const MaterialApp(
      home: Scaffold(
        body: FilterPanel(),
      ),
    );
  }

  testWidgets('FRONT-01: muestra slider de distancia y chips de categoría',
      (tester) async {
    await tester.pumpWidget(buildPanel());
    await tester.pumpAndSettle();

    expect(find.text('Filtros de búsqueda'), findsOneWidget);
    expect(find.text('Radio de distancia'), findsOneWidget);
    expect(find.text('Tipo de comida'), findsOneWidget);
    expect(find.byType(Slider), findsOneWidget);
    expect(find.text('Panadería'), findsOneWidget);
    expect(find.text('Comida Rápida'), findsOneWidget);
    expect(find.text('Todas'), findsOneWidget);
  });

  testWidgets('FRONT-05: botón Limpiar resetea selección temporal',
      (tester) async {
    store.setRadius(8);
    store.setSelectedCategory(
      CategoryModel(id: 1, name: 'Panadería', slug: 'panaderia'),
    );

    await tester.pumpWidget(buildPanel());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Limpiar'));
    await tester.pumpAndSettle();

    expect(find.text('Cualquier distancia'), findsOneWidget);
  });

  testWidgets('FRONT-01: aplicar filtros actualiza FilterStore', (tester) async {
    await tester.pumpWidget(buildPanel());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Comida Rápida'));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(Slider), const Offset(80, 0));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Aplicar filtros'));
    await tester.pumpAndSettle();

    expect(store.selectedCategory?.slug, 'comida-rapida');
    expect(store.radius, greaterThan(0));
  });

  testWidgets('CA-15: chips seleccionados se resaltan', (tester) async {
    await tester.pumpWidget(buildPanel());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Panadería'));
    await tester.pumpAndSettle();

    final chip = tester.widget<AnimatedContainer>(
      find
          .ancestor(
            of: find.text('Panadería'),
            matching: find.byType(AnimatedContainer),
          )
          .first,
    );

    final decoration = chip.decoration as BoxDecoration?;
    expect(decoration?.color, AppColors.primary);
  });
}
