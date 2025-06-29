import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/expense.dart';
import '../models/income.dart';
import '../models/expense_template.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'gestor_gastos.db');
    return await openDatabase(
      path,
      version: 5,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE gastos(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        monto REAL NOT NULL,
        categoria TEXT NOT NULL,
        fecha TEXT NOT NULL,
        nota TEXT,
        recurrente TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE ingresos(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        monto REAL NOT NULL,
        categoria TEXT NOT NULL,
        fecha TEXT NOT NULL,
        nota TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE plantillas_gastos(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        monto REAL NOT NULL,
        categoria TEXT NOT NULL,
        nota TEXT,
        recurrente TEXT,
        favorito INTEGER DEFAULT 0
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE gastos ADD COLUMN nota TEXT;');
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE ingresos(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nombre TEXT NOT NULL,
          monto REAL NOT NULL,
          categoria TEXT NOT NULL,
          fecha TEXT NOT NULL,
          nota TEXT
        )
      ''');
    }
    if (oldVersion < 4) {
      await db.execute('ALTER TABLE gastos ADD COLUMN recurrente TEXT;');
    }
    if (oldVersion < 5) {
      await db.execute('''
        CREATE TABLE plantillas_gastos(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nombre TEXT NOT NULL,
          monto REAL NOT NULL,
          categoria TEXT NOT NULL,
          nota TEXT,
          recurrente TEXT,
          favorito INTEGER DEFAULT 0
        )
      ''');
    }
  }

  // Insertar un nuevo gasto
  Future<int> insertExpense(Expense expense) async {
    final db = await database;
    return await db.insert('gastos', expense.toMap());
  }

  // Obtener todos los gastos
  Future<List<Expense>> getAllExpenses() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'gastos',
      orderBy: 'fecha DESC',
    );
    return List.generate(maps.length, (i) => Expense.fromMap(maps[i]));
  }

  // Obtener un gasto por ID
  Future<Expense?> getExpenseById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'gastos',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Expense.fromMap(maps.first);
    }
    return null;
  }

  // Actualizar un gasto
  Future<int> updateExpense(Expense expense) async {
    final db = await database;
    return await db.update(
      'gastos',
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  // Eliminar un gasto por ID
  Future<int> deleteExpense(int id) async {
    final db = await database;
    return await db.delete('gastos', where: 'id = ?', whereArgs: [id]);
  }

  // Obtener total gastado
  Future<double> getTotalExpenses() async {
    final db = await database;
    final result = await db.rawQuery('SELECT SUM(monto) as total FROM gastos');
    return result.first['total'] as double? ?? 0.0;
  }

  // Obtener gastos por categoría
  Future<Map<String, double>> getExpensesByCategory() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT categoria, SUM(monto) as total 
      FROM gastos 
      GROUP BY categoria
    ''');

    Map<String, double> categoryTotals = {};
    for (var row in result) {
      categoryTotals[row['categoria'] as String] = row['total'] as double;
    }
    return categoryTotals;
  }

  // Obtener gastos por mes
  Future<Map<String, double>> getExpensesByMonth() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT strftime('%Y-%m', fecha) as mes, SUM(monto) as total 
      FROM gastos 
      GROUP BY strftime('%Y-%m', fecha)
      ORDER BY mes DESC
      LIMIT 12
    ''');

    Map<String, double> monthTotals = {};
    for (var row in result) {
      monthTotals[row['mes'] as String] = row['total'] as double;
    }
    return monthTotals;
  }

  // Obtener gastos recurrentes
  Future<List<Expense>> getRecurringExpenses() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'gastos',
      where: 'recurrente IS NOT NULL AND recurrente != ?',
      whereArgs: ['ninguna'],
      orderBy: 'fecha DESC',
    );
    return List.generate(maps.length, (i) => Expense.fromMap(maps[i]));
  }

  // Crear siguiente gasto recurrente
  Future<void> createNextRecurrence(Expense expense) async {
    final nextExpense = expense.createNextRecurrence();
    if (nextExpense != null) {
      await insertExpense(nextExpense);
    }
  }

  // Ingresos
  Future<int> insertIncome(Income income) async {
    final db = await database;
    return await db.insert('ingresos', income.toMap());
  }

  Future<List<Income>> getAllIncomes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'ingresos',
      orderBy: 'fecha DESC',
    );
    return List.generate(maps.length, (i) => Income.fromMap(maps[i]));
  }

  Future<int> updateIncome(Income income) async {
    final db = await database;
    return await db.update(
      'ingresos',
      income.toMap(),
      where: 'id = ?',
      whereArgs: [income.id],
    );
  }

  Future<int> deleteIncome(int id) async {
    final db = await database;
    return await db.delete('ingresos', where: 'id = ?', whereArgs: [id]);
  }

  Future<double> getTotalIncomesThisMonth() async {
    final db = await database;
    final now = DateTime.now();
    final result = await db.rawQuery(
      '''
      SELECT SUM(monto) as total FROM ingresos
      WHERE strftime('%Y-%m', fecha) = ?
    ''',
      [
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}',
      ],
    );
    return result.first['total'] as double? ?? 0.0;
  }

  // Obtener total de ingresos
  Future<double> getTotalIncomes() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(monto) as total FROM ingresos',
    );
    return result.first['total'] as double? ?? 0.0;
  }

  // Obtener ingresos por categoría
  Future<Map<String, double>> getIncomesByCategory() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT categoria, SUM(monto) as total 
      FROM ingresos 
      GROUP BY categoria
    ''');

    Map<String, double> categoryTotals = {};
    for (var row in result) {
      categoryTotals[row['categoria'] as String] = row['total'] as double;
    }
    return categoryTotals;
  }

  // Obtener ingresos por mes
  Future<Map<String, double>> getIncomesByMonth() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT strftime('%Y-%m', fecha) as mes, SUM(monto) as total 
      FROM ingresos 
      GROUP BY strftime('%Y-%m', fecha)
      ORDER BY mes DESC
      LIMIT 12
    ''');

    Map<String, double> monthTotals = {};
    for (var row in result) {
      monthTotals[row['mes'] as String] = row['total'] as double;
    }
    return monthTotals;
  }

  // Plantillas de gastos
  Future<int> insertExpenseTemplate(ExpenseTemplate template) async {
    final db = await database;
    return await db.insert('plantillas_gastos', template.toMap());
  }

  Future<List<ExpenseTemplate>> getAllExpenseTemplates() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'plantillas_gastos',
      orderBy: 'favorito DESC, nombre ASC',
    );
    return List.generate(maps.length, (i) => ExpenseTemplate.fromMap(maps[i]));
  }

  Future<List<ExpenseTemplate>> getFavoriteExpenseTemplates() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'plantillas_gastos',
      where: 'favorito = ?',
      whereArgs: [1],
      orderBy: 'nombre ASC',
    );
    return List.generate(maps.length, (i) => ExpenseTemplate.fromMap(maps[i]));
  }

  Future<int> updateExpenseTemplate(ExpenseTemplate template) async {
    final db = await database;
    return await db.update(
      'plantillas_gastos',
      template.toMap(),
      where: 'id = ?',
      whereArgs: [template.id],
    );
  }

  Future<int> deleteExpenseTemplate(int id) async {
    final db = await database;
    return await db.delete(
      'plantillas_gastos',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> toggleFavoriteTemplate(int id, bool favorito) async {
    final db = await database;
    await db.update(
      'plantillas_gastos',
      {'favorito': favorito ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
