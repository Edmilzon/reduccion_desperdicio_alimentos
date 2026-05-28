import 'package:flutter_test/flutter_test.dart';
import 'package:reduccion_desperdicio_alimentos/features/home/data/models/product_model.dart';
import 'package:reduccion_desperdicio_alimentos/features/map/data/filter_store.dart';

void main() {
  final store = FilterStore.instance;

  setUp(() {
    store.clearFilters();
    store.setActiveCategoriesForTest([
      CategoryModel(id: 1, name: 'Panadería', slug: 'panaderia'),
      CategoryModel(id: 4, name: 'Comida Rápida', slug: 'comida-rapida'),
    ]);
  });

  test('CA-15: activeCount refleja filtros activos', () {
    expect(store.activeCount, 0);

    store.setRadius(5);
    expect(store.activeCount, 1);

    store.setSelectedCategory(
      CategoryModel(id: 4, name: 'Comida Rápida', slug: 'comida-rapida'),
    );
    expect(store.activeCount, 2);
    expect(store.hasFilters, isTrue);
  });

  test('CA-16: clearFilters restablece estado inicial', () {
    store.setRadius(10);
    store.setSelectedCategory(
      CategoryModel(id: 1, name: 'Panadería', slug: 'panaderia'),
    );

    store.clearFilters();

    expect(store.radius, 0);
    expect(store.selectedCategory, isNull);
    expect(store.activeCount, 0);
    expect(store.categorySlug, isNull);
  });

  test('categorySlug devuelve slug de la categoría seleccionada', () {
    store.setSelectedCategory(
      CategoryModel(id: 4, name: 'Comida Rápida', slug: 'comida-rapida'),
    );
    expect(store.categorySlug, 'comida-rapida');
  });
}
