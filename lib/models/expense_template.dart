class ExpenseTemplate {
  final int? id;
  final String nombre;
  final double monto;
  final String categoria;
  final String? nota;
  final String? recurrente;
  final bool favorito;

  ExpenseTemplate({
    this.id,
    required this.nombre,
    required this.monto,
    required this.categoria,
    this.nota,
    this.recurrente,
    this.favorito = false,
  });

  // Convertir a Map para SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'monto': monto,
      'categoria': categoria,
      'nota': nota,
      'recurrente': recurrente,
      'favorito': favorito ? 1 : 0,
    };
  }

  // Crear desde Map (desde SQLite)
  factory ExpenseTemplate.fromMap(Map<String, dynamic> map) {
    return ExpenseTemplate(
      id: map['id'],
      nombre: map['nombre'],
      monto: map['monto'],
      categoria: map['categoria'],
      nota: map['nota'],
      recurrente: map['recurrente'],
      favorito: map['favorito'] == 1,
    );
  }

  // Crear copia con nuevos valores
  ExpenseTemplate copyWith({
    int? id,
    String? nombre,
    double? monto,
    String? categoria,
    String? nota,
    String? recurrente,
    bool? favorito,
  }) {
    return ExpenseTemplate(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      monto: monto ?? this.monto,
      categoria: categoria ?? this.categoria,
      nota: nota ?? this.nota,
      recurrente: recurrente ?? this.recurrente,
      favorito: favorito ?? this.favorito,
    );
  }

  // Convertir plantilla a gasto
  Map<String, dynamic> toExpenseData() {
    return {
      'nombre': nombre,
      'monto': monto,
      'categoria': categoria,
      'fecha': DateTime.now().toIso8601String(),
      'nota': nota,
      'recurrente': recurrente,
    };
  }

  // Obtener texto descriptivo de la recurrencia
  String get recurrenciaText {
    switch (recurrente) {
      case 'semanal':
        return 'Cada semana';
      case 'quincenal':
        return 'Cada 15 días';
      case 'mensual':
        return 'Cada mes';
      case 'anual':
        return 'Cada año';
      default:
        return 'No recurrente';
    }
  }
}
