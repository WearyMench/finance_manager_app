class Income {
  final int? id;
  final String nombre;
  final double monto;
  final String categoria;
  final DateTime fecha;
  final String? nota;

  Income({
    this.id,
    required this.nombre,
    required this.monto,
    required this.categoria,
    required this.fecha,
    this.nota,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'monto': monto,
      'categoria': categoria,
      'fecha': fecha.toIso8601String(),
      'nota': nota,
    };
  }

  factory Income.fromMap(Map<String, dynamic> map) {
    return Income(
      id: map['id'],
      nombre: map['nombre'],
      monto: map['monto'],
      categoria: map['categoria'],
      fecha: DateTime.parse(map['fecha']),
      nota: map['nota'],
    );
  }

  Income copyWith({
    int? id,
    String? nombre,
    double? monto,
    String? categoria,
    DateTime? fecha,
    String? nota,
  }) {
    return Income(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      monto: monto ?? this.monto,
      categoria: categoria ?? this.categoria,
      fecha: fecha ?? this.fecha,
      nota: nota ?? this.nota,
    );
  }
}
