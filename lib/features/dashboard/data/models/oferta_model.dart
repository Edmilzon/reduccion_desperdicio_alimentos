class OfertaModel {
  final String id;
  final String categoria;
  final String nombre;
  final int unidadesRestantes;
  final double precio;
  final double? precioOriginal;
  final String estado; // 'active' | 'sold'
  final DateTime horaLimite;
  final DateTime creadaEn;

  const OfertaModel({
    required this.id,
    required this.categoria,
    required this.nombre,
    required this.unidadesRestantes,
    required this.precio,
    this.precioOriginal,
    required this.estado,
    required this.horaLimite,
    required this.creadaEn,
  });

  bool get isActive => estado == 'active';
  bool get isSold   => estado == 'sold';

  bool get isExpiringSoon {
    final diff = horaLimite.difference(DateTime.now());
    return isActive && diff.inMinutes <= 30 && diff.inMinutes > 0;
  }
}
