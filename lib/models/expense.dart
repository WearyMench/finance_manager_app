class Expense {
  final int? id;
  final String nombre;
  final double monto;
  final String categoria;
  final DateTime fecha;
  final String? nota;
  final String?
  recurrente; // 'ninguna', 'mensual', 'semanal', 'quincenal', 'anual'

  Expense({
    this.id,
    required this.nombre,
    required this.monto,
    required this.categoria,
    required this.fecha,
    this.nota,
    this.recurrente,
  });

  // Convertir a Map para SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'monto': monto,
      'categoria': categoria,
      'fecha': fecha.toIso8601String(),
      'nota': nota,
      'recurrente': recurrente,
    };
  }

  // Crear desde Map (desde SQLite)
  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'],
      nombre: map['nombre'],
      monto: map['monto'],
      categoria: map['categoria'],
      fecha: DateTime.parse(map['fecha']),
      nota: map['nota'],
      recurrente: map['recurrente'],
    );
  }

  // Crear copia con nuevos valores
  Expense copyWith({
    int? id,
    String? nombre,
    double? monto,
    String? categoria,
    DateTime? fecha,
    String? nota,
    String? recurrente,
  }) {
    return Expense(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      monto: monto ?? this.monto,
      categoria: categoria ?? this.categoria,
      fecha: fecha ?? this.fecha,
      nota: nota ?? this.nota,
      recurrente: recurrente ?? this.recurrente,
    );
  }

  // Crear gasto recurrente para el siguiente período
  Expense? createNextRecurrence() {
    if (recurrente == null || recurrente == 'ninguna') return null;

    DateTime nextDate;
    switch (recurrente) {
      case 'semanal':
        nextDate = fecha.add(const Duration(days: 7));
        break;
      case 'quincenal':
        nextDate = fecha.add(const Duration(days: 15));
        break;
      case 'mensual':
        nextDate = DateTime(fecha.year, fecha.month + 1, fecha.day);
        break;
      case 'anual':
        nextDate = DateTime(fecha.year + 1, fecha.month, fecha.day);
        break;
      default:
        return null;
    }

    return copyWith(id: null, fecha: nextDate);
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
