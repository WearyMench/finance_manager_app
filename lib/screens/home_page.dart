import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../db/database_helper.dart';
import 'add_expense_page.dart';
import 'edit_expense_page.dart';
import 'stats_page.dart';
import 'editar_nombre_page.dart';
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import '../utils/web_csv_download.dart'
    if (dart.library.html) '../utils/web_csv_download_web.dart';
import 'package:file_picker/file_picker.dart';
import '../main.dart';
import 'add_income_page.dart';
import '../models/income.dart';
import 'edit_income_page.dart';
import 'templates_page.dart';
import '../utils/app_colors.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Expense> _expenses = [];
  List<Expense> _filteredExpenses = [];
  List<Income> _incomes = [];
  List<Income> _filteredIncomes = [];
  String _username = '';
  bool _isLoading = true;
  double _monthlyBudget = 0.0;
  double _totalThisMonth = 0.0;
  String _currencyCode = 'DOP';
  String _currencySymbol = 'RD\$';
  final Map<String, String> _currencies = {
    'DOP': 'RD\$',
    'MXN': '\$',
    'USD': '\$',
    'EUR': '€',
    'COP': '\$',
    'ARS': '\$',
  };

  // Para búsqueda y filtro
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'Todas';
  List<String> _defaultCategories = [
    'Comida',
    'Transporte',
    'Ocio',
    'Servicios',
    'Ropa',
    'Otros',
  ];
  List<String> _customCategories = [];
  List<String> get _categoriesList => [
    'Todas',
    ..._defaultCategories,
    ..._customCategories,
  ];

  double _totalIncomesThisMonth = 0.0;
  String _filterType = 'Gastos'; // 'Gastos', 'Ingresos', 'Ambos'

  // Filtros avanzados
  bool _showAdvancedFilters = false;
  DateTime? _startDate;
  DateTime? _endDate;
  double? _minAmount;
  double? _maxAmount;
  bool _searchInNotes = false;
  final TextEditingController _minAmountController = TextEditingController();
  final TextEditingController _maxAmountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_applyFilters);
    _loadBudget();
    _loadCurrency();
    _loadCategories();
    _loadIncomes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _minAmountController.dispose();
    _maxAmountController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await _loadUsername();
    await _loadExpenses();
  }

  Future<void> _loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = prefs.getString('username') ?? 'Usuario';
    });
  }

  Future<void> _loadExpenses() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final expenses = await _dbHelper.getAllExpenses();
      setState(() {
        _expenses = expenses;
        _isLoading = false;
      });
      _applyFilters();
      _calculateTotalThisMonth();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al cargar gastos: $e')));
      }
    }
  }

  Future<void> _loadBudget() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _monthlyBudget = prefs.getDouble('monthly_budget') ?? 0.0;
    });
    _calculateTotalThisMonth();
  }

  Future<void> _saveBudget(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('monthly_budget', value);
    setState(() {
      _monthlyBudget = value;
    });
    _calculateTotalThisMonth();
  }

  void _calculateTotalThisMonth() {
    final now = DateTime.now();
    final expenses = _expenses.where(
      (e) => e.fecha.year == now.year && e.fecha.month == now.month,
    );
    setState(() {
      _totalThisMonth = expenses.fold(0.0, (sum, e) => sum + e.monto);
    });
  }

  void _showBudgetDialog() {
    final controller = TextEditingController(
      text: _monthlyBudget > 0 ? _monthlyBudget.toStringAsFixed(2) : '',
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Definir presupuesto mensual'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Presupuesto (MXN)',
            prefixIcon: Icon(Icons.attach_money),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final value =
                  double.tryParse(controller.text.replaceAll(',', '.')) ?? 0.0;
              _saveBudget(value);
              Navigator.of(context).pop();
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _applyFilters() {
    String search = _searchController.text.toLowerCase();
    String category = _selectedCategory;

    setState(() {
      // Filtrar gastos
      _filteredExpenses = _expenses.where((expense) {
        // Filtro de búsqueda
        final matchesSearch =
            expense.nombre.toLowerCase().contains(search) ||
            (_searchInNotes &&
                expense.nota != null &&
                expense.nota!.toLowerCase().contains(search));

        // Filtro de categoría
        final matchesCategory =
            category == 'Todas' || expense.categoria == category;

        // Filtro de fecha
        final matchesDate =
            (_startDate == null ||
                expense.fecha.isAfter(
                  _startDate!.subtract(const Duration(days: 1)),
                )) &&
            (_endDate == null ||
                expense.fecha.isBefore(_endDate!.add(const Duration(days: 1))));

        // Filtro de monto
        final matchesAmount =
            (_minAmount == null || expense.monto >= _minAmount!) &&
            (_maxAmount == null || expense.monto <= _maxAmount!);

        return matchesSearch && matchesCategory && matchesDate && matchesAmount;
      }).toList();

      // Filtrar ingresos
      _filteredIncomes = _incomes.where((income) {
        // Filtro de búsqueda
        final matchesSearch =
            income.nombre.toLowerCase().contains(search) ||
            (_searchInNotes &&
                income.nota != null &&
                income.nota!.toLowerCase().contains(search));

        // Filtro de categoría
        final matchesCategory =
            category == 'Todas' || income.categoria == category;

        // Filtro de fecha
        final matchesDate =
            (_startDate == null ||
                income.fecha.isAfter(
                  _startDate!.subtract(const Duration(days: 1)),
                )) &&
            (_endDate == null ||
                income.fecha.isBefore(_endDate!.add(const Duration(days: 1))));

        // Filtro de monto
        final matchesAmount =
            (_minAmount == null || income.monto >= _minAmount!) &&
            (_maxAmount == null || income.monto <= _maxAmount!);

        return matchesSearch && matchesCategory && matchesDate && matchesAmount;
      }).toList();
    });
  }

  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
      });
      _applyFilters();
    }
  }

  Future<void> _selectEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
      _applyFilters();
    }
  }

  void _updateAmountFilters() {
    setState(() {
      _minAmount = double.tryParse(
        _minAmountController.text.replaceAll(',', '.'),
      );
      _maxAmount = double.tryParse(
        _maxAmountController.text.replaceAll(',', '.'),
      );
    });
    _applyFilters();
  }

  void _clearAdvancedFilters() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _minAmount = null;
      _maxAmount = null;
      _searchInNotes = false;
      _minAmountController.clear();
      _maxAmountController.clear();
    });
    _applyFilters();
  }

  String _getDateRangeText() {
    if (_startDate == null && _endDate == null) return 'Todas las fechas';
    if (_startDate != null && _endDate != null) {
      return '${DateFormat('dd/MM/yyyy').format(_startDate!)} - ${DateFormat('dd/MM/yyyy').format(_endDate!)}';
    }
    if (_startDate != null)
      return 'Desde ${DateFormat('dd/MM/yyyy').format(_startDate!)}';
    if (_endDate != null)
      return 'Hasta ${DateFormat('dd/MM/yyyy').format(_endDate!)}';
    return 'Todas las fechas';
  }

  String _getAmountRangeText() {
    if (_minAmount == null && _maxAmount == null) return 'Todos los montos';
    if (_minAmount != null && _maxAmount != null) {
      return '${NumberFormat.currency(locale: 'es_MX', symbol: _currencySymbol).format(_minAmount!)} - ${NumberFormat.currency(locale: 'es_MX', symbol: _currencySymbol).format(_maxAmount!)}';
    }
    if (_minAmount != null)
      return 'Desde ${NumberFormat.currency(locale: 'es_MX', symbol: _currencySymbol).format(_minAmount!)}';
    if (_maxAmount != null)
      return 'Hasta ${NumberFormat.currency(locale: 'es_MX', symbol: _currencySymbol).format(_maxAmount!)}';
    return 'Todos los montos';
  }

  Future<void> _deleteExpense(int id) async {
    try {
      await _dbHelper.deleteExpense(id);
      await _loadExpenses();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gasto eliminado correctamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al eliminar: $e')));
      }
    }
  }

  void _showDeleteDialog(Expense expense) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Gasto'),
        content: Text(
          '¿Estás seguro de que quieres eliminar "${expense.nombre}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteExpense(expense.id!);
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.getDangerColor(context),
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportToCSV() async {
    try {
      // Encabezados
      List<List<dynamic>> rows = [
        ['ID', 'Nombre', 'Monto', 'Categoría', 'Fecha', 'Nota'],
      ];
      // Datos
      for (var expense
          in _filteredExpenses.isNotEmpty ? _filteredExpenses : _expenses) {
        rows.add([
          expense.id ?? '',
          expense.nombre,
          expense.monto,
          expense.categoria,
          expense.fecha.toIso8601String(),
          expense.nota ?? '',
        ]);
      }
      String csvData = const ListToCsvConverter().convert(rows);

      if (kIsWeb) {
        downloadCsvWeb(csvData);
      } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        // Escritorio: guardar en carpeta Descargas
        final directory = await getDownloadsDirectory();
        final path = directory != null
            ? directory.path
            : (await getApplicationDocumentsDirectory()).path;
        final file = File('$path/gastos.csv');
        await file.writeAsString(csvData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Archivo exportado en: ${file.path}')),
          );
        }
      } else {
        // Móvil: copiar al portapapeles
        await Clipboard.setData(ClipboardData(text: csvData));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'CSV copiado al portapapeles (puedes pegarlo en un email o app de notas)',
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al exportar: $e')));
      }
    }
  }

  Future<void> _exportIncomesToCSV() async {
    try {
      // Encabezados
      List<List<dynamic>> rows = [
        ['ID', 'Nombre', 'Monto', 'Categoría', 'Fecha', 'Nota'],
      ];
      // Datos
      for (var income in _filteredIncomes) {
        rows.add([
          income.id ?? '',
          income.nombre,
          income.monto,
          income.categoria,
          income.fecha.toIso8601String(),
          income.nota ?? '',
        ]);
      }
      String csvData = const ListToCsvConverter().convert(rows);

      if (kIsWeb) {
        downloadCsvWeb(csvData);
      } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        // Escritorio: guardar en carpeta Descargas
        final directory = await getDownloadsDirectory();
        final path = directory != null
            ? directory.path
            : (await getApplicationDocumentsDirectory()).path;
        final file = File('$path/ingresos.csv');
        await file.writeAsString(csvData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Archivo exportado en: ${file.path}')),
          );
        }
      } else {
        // Móvil: copiar al portapapeles
        await Clipboard.setData(ClipboardData(text: csvData));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'CSV copiado al portapapeles (puedes pegarlo en un email o app de notas)',
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al exportar: $e')));
      }
    }
  }

  Future<void> _importFromCSV() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      final content = String.fromCharCodes(
        file.bytes ?? await File(file.path!).readAsBytes(),
      );
      final rows = const CsvToListConverter().convert(content, eol: '\n');
      int imported = 0;
      for (int i = 1; i < rows.length; i++) {
        final row = rows[i];
        if (row.length < 5) continue;
        try {
          final nombre = row[1]?.toString() ?? '';
          final monto = double.tryParse(row[2].toString()) ?? 0.0;
          final categoria = row[3]?.toString() ?? '';
          final fecha = DateTime.tryParse(row[4].toString()) ?? DateTime.now();
          final nota = row.length > 5 ? row[5]?.toString() : null;
          if (nombre.isEmpty || monto <= 0 || categoria.isEmpty) continue;
          final expense = Expense(
            nombre: nombre,
            monto: monto,
            categoria: categoria,
            fecha: fecha,
            nota: (nota != null && nota.isNotEmpty) ? nota : null,
          );
          await _dbHelper.insertExpense(expense);
          imported++;
        } catch (_) {}
      }
      await _loadExpenses();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Importados $imported gastos desde CSV.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al importar: $e')));
      }
    }
  }

  Future<void> _importIncomesFromCSV() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      final content = String.fromCharCodes(
        file.bytes ?? await File(file.path!).readAsBytes(),
      );
      final rows = const CsvToListConverter().convert(content, eol: '\n');
      int imported = 0;
      for (int i = 1; i < rows.length; i++) {
        final row = rows[i];
        if (row.length < 5) continue;
        try {
          final nombre = row[1]?.toString() ?? '';
          final monto = double.tryParse(row[2].toString()) ?? 0.0;
          final categoria = row[3]?.toString() ?? '';
          final fecha = DateTime.tryParse(row[4].toString()) ?? DateTime.now();
          final nota = row.length > 5 ? row[5]?.toString() : null;
          if (nombre.isEmpty || monto <= 0 || categoria.isEmpty) continue;
          final income = Income(
            nombre: nombre,
            monto: monto,
            categoria: categoria,
            fecha: fecha,
            nota: (nota != null && nota.isNotEmpty) ? nota : null,
          );
          await _dbHelper.insertIncome(income);
          imported++;
        } catch (_) {}
      }
      await _loadIncomes();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Importados $imported ingresos desde CSV.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al importar: $e')));
      }
    }
  }

  Future<void> _loadCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currencyCode = prefs.getString('currency_code') ?? 'DOP';
      _currencySymbol = _currencies[_currencyCode] ?? 'RD\$';
    });
  }

  Future<void> _saveCurrency(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currency_code', code);
    setState(() {
      _currencyCode = code;
      _currencySymbol = _currencies[code] ?? 'RD\$';
    });
  }

  void _showCurrencyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seleccionar moneda'),
        content: DropdownButton<String>(
          value: _currencyCode,
          items: _currencies.keys.map((code) {
            return DropdownMenuItem(
              value: code,
              child: Text('$code  ${_currencies[code]}'),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              _saveCurrency(value);
              Navigator.of(context).pop();
            }
          },
        ),
      ),
    );
  }

  void _showThemeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seleccionar tema'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.brightness_auto),
              title: const Text('Automático (según sistema)'),
              onTap: () {
                print('Cambiando a tema automático');
                themeProvider.setThemeMode(ThemeMode.system);
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.light_mode),
              title: const Text('Claro'),
              onTap: () {
                print('Cambiando a tema claro');
                themeProvider.setThemeMode(ThemeMode.light);
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.dark_mode),
              title: const Text('Oscuro'),
              onTap: () {
                print('Cambiando a tema oscuro');
                themeProvider.setThemeMode(ThemeMode.dark);
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadCategories() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _customCategories = prefs.getStringList('custom_categories') ?? [];
    });
  }

  Future<void> _saveCategories() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('custom_categories', _customCategories);
    setState(() {});
  }

  void _showCategoriesDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Categorías personalizadas'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ..._customCategories.map(
                (cat) => ListTile(
                  title: Text(cat),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      setStateDialog(() {
                        _customCategories.remove(cat);
                      });
                      _saveCategories();
                    },
                  ),
                ),
              ),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Nueva categoría',
                  prefixIcon: Icon(Icons.add),
                ),
                onSubmitted: (value) {
                  if (value.trim().isEmpty) return;
                  setStateDialog(() {
                    if (!_customCategories.contains(value.trim()) &&
                        !_defaultCategories.contains(value.trim())) {
                      _customCategories.add(value.trim());
                    }
                  });
                  controller.clear();
                  _saveCategories();
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadIncomes() async {
    final incomes = await _dbHelper.getAllIncomes();
    final total = await _dbHelper.getTotalIncomesThisMonth();
    setState(() {
      _incomes = incomes;
      _totalIncomesThisMonth = total;
    });
  }

  Future<void> _editProfile() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const EditarNombrePage()));
    _loadUsername();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: Text('Hola, $_username 👋'),
        backgroundColor: AppColors.getPrimaryColor(context),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Botones principales siempre visibles
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _filterType == 'Ingresos'
                ? _exportIncomesToCSV
                : _exportToCSV,
            tooltip: _filterType == 'Ingresos'
                ? 'Exportar ingresos a CSV'
                : 'Exportar gastos a CSV',
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const StatsPage()),
              );
            },
            tooltip: 'Estadísticas',
          ),
          // Menú desplegable para funciones adicionales
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'Más opciones',
            onSelected: (value) {
              switch (value) {
                case 'import':
                  _filterType == 'Ingresos'
                      ? _importIncomesFromCSV()
                      : _importFromCSV();
                  break;
                case 'budget':
                  _showBudgetDialog();
                  break;
                case 'currency':
                  _showCurrencyDialog();
                  break;
                case 'theme':
                  _showThemeDialog();
                  break;
                case 'profile':
                  _editProfile();
                  break;
                case 'categories':
                  _showCategoriesDialog();
                  break;
                case 'templates':
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const TemplatesPage(),
                    ),
                  );
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'import',
                child: Row(
                  children: [
                    Icon(
                      Icons.upload_file,
                      color: AppColors.getTextPrimaryColor(context),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _filterType == 'Ingresos'
                          ? 'Importar ingresos'
                          : 'Importar gastos',
                      style: TextStyle(
                        color: AppColors.getTextPrimaryColor(context),
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'budget',
                child: Row(
                  children: [
                    Icon(
                      Icons.account_balance,
                      color: AppColors.getTextPrimaryColor(context),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Presupuesto',
                      style: TextStyle(
                        color: AppColors.getTextPrimaryColor(context),
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'currency',
                child: Row(
                  children: [
                    Icon(
                      Icons.attach_money,
                      color: AppColors.getTextPrimaryColor(context),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Moneda',
                      style: TextStyle(
                        color: AppColors.getTextPrimaryColor(context),
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'theme',
                child: Row(
                  children: [
                    Icon(
                      Icons.brightness_6,
                      color: AppColors.getTextPrimaryColor(context),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Tema',
                      style: TextStyle(
                        color: AppColors.getTextPrimaryColor(context),
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(
                      Icons.person,
                      color: AppColors.getTextPrimaryColor(context),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Editar perfil',
                      style: TextStyle(
                        color: AppColors.getTextPrimaryColor(context),
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'categories',
                child: Row(
                  children: [
                    Icon(
                      Icons.category,
                      color: AppColors.getTextPrimaryColor(context),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Categorías',
                      style: TextStyle(
                        color: AppColors.getTextPrimaryColor(context),
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'templates',
                child: Row(
                  children: [
                    Icon(
                      Icons.list,
                      color: AppColors.getTextPrimaryColor(context),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Plantillas',
                      style: TextStyle(
                        color: AppColors.getTextPrimaryColor(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Balance
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: AppColors.getPrimaryGradient(context),
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.getPrimaryColor(
                              context,
                            ).withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Ingresos',
                                      style: TextStyle(
                                        color: AppColors.getWhiteWithOpacity(
                                          0.9,
                                        ),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      NumberFormat.currency(
                                        locale: 'es_MX',
                                        symbol: _currencySymbol,
                                        name: _currencyCode,
                                      ).format(_totalIncomesThisMonth),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.getWhiteWithOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.trending_up,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Gastos',
                                      style: TextStyle(
                                        color: AppColors.getWhiteWithOpacity(
                                          0.9,
                                        ),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      NumberFormat.currency(
                                        locale: 'es_MX',
                                        symbol: _currencySymbol,
                                        name: _currencyCode,
                                      ).format(_totalThisMonth),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.getWhiteWithOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.trending_down,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.getWhiteWithOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.getWhiteWithOpacity(0.2),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Balance',
                                    style: TextStyle(
                                      color: AppColors.getWhiteWithOpacity(0.9),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    NumberFormat.currency(
                                      locale: 'es_MX',
                                      symbol: _currencySymbol,
                                      name: _currencyCode,
                                    ).format(
                                      _totalIncomesThisMonth - _totalThisMonth,
                                    ),
                                    style: TextStyle(
                                      color:
                                          (_totalIncomesThisMonth -
                                                  _totalThisMonth) >=
                                              0
                                          ? Colors.green[100]
                                          : Colors.red[100],
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Filtro de tipo
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        ChoiceChip(
                          label: const Text('Gastos'),
                          selected: _filterType == 'Gastos',
                          onSelected: (v) =>
                              setState(() => _filterType = 'Gastos'),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Ingresos'),
                          selected: _filterType == 'Ingresos',
                          onSelected: (v) =>
                              setState(() => _filterType = 'Ingresos'),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Ambos'),
                          selected: _filterType == 'Ambos',
                          onSelected: (v) =>
                              setState(() => _filterType = 'Ambos'),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Row(
                      children: [
                        // Búsqueda
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Buscar gasto...',
                              prefixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Filtro categoría
                        DropdownButton<String>(
                          value: _selectedCategory,
                          items: _categoriesList
                              .map(
                                (cat) => DropdownMenuItem(
                                  value: cat,
                                  child: Text(cat),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedCategory = value!;
                            });
                            _applyFilters();
                          },
                          underline: Container(),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        const SizedBox(width: 8),
                        // Botón filtros avanzados
                        IconButton(
                          icon: Icon(
                            _showAdvancedFilters
                                ? Icons.filter_list_off
                                : Icons.filter_list,
                          ),
                          onPressed: () {
                            setState(() {
                              _showAdvancedFilters = !_showAdvancedFilters;
                            });
                          },
                          tooltip: 'Filtros avanzados',
                        ),
                      ],
                    ),
                  ),
                  // Filtros avanzados
                  if (_showAdvancedFilters)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Filtros Avanzados',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  TextButton.icon(
                                    onPressed: _clearAdvancedFilters,
                                    icon: const Icon(Icons.clear, size: 16),
                                    label: const Text('Limpiar'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              // Filtros de fecha
                              Row(
                                children: [
                                  Flexible(
                                    fit: FlexFit.loose,
                                    child: InkWell(
                                      onTap: _selectStartDate,
                                      child: InputDecorator(
                                        decoration: const InputDecoration(
                                          labelText: 'Fecha inicio',
                                          prefixIcon: Icon(
                                            Icons.calendar_today,
                                          ),
                                          border: OutlineInputBorder(),
                                        ),
                                        child: Text(
                                          _getDateRangeText().split(' - ')[0],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Flexible(
                                    fit: FlexFit.loose,
                                    child: InkWell(
                                      onTap: _selectEndDate,
                                      child: InputDecorator(
                                        decoration: const InputDecoration(
                                          labelText: 'Fecha fin',
                                          prefixIcon: Icon(
                                            Icons.calendar_today,
                                          ),
                                          border: OutlineInputBorder(),
                                        ),
                                        child: Text(
                                          _getDateRangeText()
                                                      .split(' - ')
                                                      .length >
                                                  1
                                              ? _getDateRangeText().split(
                                                  ' - ',
                                                )[1]
                                              : '',
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              // Filtros de monto
                              Row(
                                children: [
                                  Flexible(
                                    fit: FlexFit.loose,
                                    child: TextField(
                                      controller: _minAmountController,
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        labelText: 'Monto mínimo',
                                        prefixIcon: const Icon(
                                          Icons.attach_money,
                                        ),
                                        border: const OutlineInputBorder(),
                                        suffixIcon: IconButton(
                                          icon: const Icon(Icons.check),
                                          onPressed: _updateAmountFilters,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Flexible(
                                    fit: FlexFit.loose,
                                    child: TextField(
                                      controller: _maxAmountController,
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        labelText: 'Monto máximo',
                                        prefixIcon: const Icon(
                                          Icons.attach_money,
                                        ),
                                        border: const OutlineInputBorder(),
                                        suffixIcon: IconButton(
                                          icon: const Icon(Icons.check),
                                          onPressed: _updateAmountFilters,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              // Búsqueda en notas
                              CheckboxListTile(
                                title: const Text('Buscar también en notas'),
                                value: _searchInNotes,
                                onChanged: (value) {
                                  setState(() {
                                    _searchInNotes = value ?? false;
                                  });
                                  _applyFilters();
                                },
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  // Lista de gastos/ingresos
                  _shouldShowEmptyState()
                      ? _buildEmptyState()
                      : _buildExpensesList(shrinkWrap: true),
                  const SizedBox(height: 100), // Espacio para FAB
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => Container(
              decoration: BoxDecoration(
                color: AppColors.getSurfaceColor(context),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.getTextSecondaryColor(context),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Agregar nuevo',
                      style: TextStyle(
                        color: AppColors.getTextPrimaryColor(context),
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.of(context).pop();
                                Navigator.of(context)
                                    .push(
                                      MaterialPageRoute(
                                        builder: (context) => AddExpensePage(
                                          categories: _categoriesList
                                              .where((c) => c != 'Todas')
                                              .toList(),
                                        ),
                                      ),
                                    )
                                    .then((_) => _loadData());
                              },
                              icon: const Icon(Icons.remove_circle_outline),
                              label: const Text('Gasto'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.getDangerColor(
                                  context,
                                ),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.of(context).pop();
                                Navigator.of(context)
                                    .push(
                                      MaterialPageRoute(
                                        builder: (context) => AddIncomePage(
                                          categories: _categoriesList
                                              .where((c) => c != 'Todas')
                                              .toList(),
                                        ),
                                      ),
                                    )
                                    .then((_) => _loadData());
                              },
                              icon: const Icon(Icons.add_circle_outline),
                              label: const Text('Ingreso'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.getSuccessColor(
                                  context,
                                ),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          );
        },
        backgroundColor: AppColors.getPrimaryColor(context),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Agregar'),
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  bool _shouldShowEmptyState() {
    switch (_filterType) {
      case 'Ingresos':
        return _filteredIncomes.isEmpty;
      case 'Ambos':
        return _filteredExpenses.isEmpty && _filteredIncomes.isEmpty;
      default:
        return _filteredExpenses.isEmpty;
    }
  }

  Widget _buildEmptyState() {
    String message;
    String subtitle;

    switch (_filterType) {
      case 'Ingresos':
        message = 'No hay ingresos registrados';
        subtitle = 'Toca el botón + para agregar tu primer ingreso';
        break;
      case 'Ambos':
        message = 'No hay gastos ni ingresos registrados';
        subtitle = 'Toca los botones + para agregar tus primeros registros';
        break;
      default:
        message = 'No hay gastos registrados';
        subtitle = 'Toca el botón + para agregar tu primer gasto';
    }

    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long,
              size: 80,
              color: AppColors.getTextSecondaryColor(context),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.getTextSecondaryColor(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.getTextSecondaryColor(context),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpensesList({bool shrinkWrap = false}) {
    if (_filterType == 'Ingresos') {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredIncomes.length,
        shrinkWrap: shrinkWrap,
        physics: shrinkWrap ? NeverScrollableScrollPhysics() : null,
        itemBuilder: (context, index) {
          final income = _filteredIncomes[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            color: Theme.of(context).colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                backgroundColor: AppColors.getSuccessColor(context),
                child: const Icon(Icons.attach_money, color: Colors.white),
              ),
              title: Text(
                income.nombre,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    income.categoria,
                    style: TextStyle(
                      color: AppColors.getTextSecondaryColor(context),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('dd/MM/yyyy').format(income.fecha),
                    style: TextStyle(
                      color: AppColors.getTextSecondaryColor(context),
                      fontSize: 12,
                    ),
                  ),
                  if (income.nota != null && income.nota!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.note_alt,
                          size: 16,
                          color: AppColors.getWarningColor(context),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          fit: FlexFit.loose,
                          child: Text(
                            income.nota!,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: AppColors.getTextSecondaryColor(
                                    context,
                                  ),
                                  fontStyle: FontStyle.italic,
                                ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              trailing: SizedBox(
                width: 120,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      NumberFormat.currency(
                        locale: 'es_MX',
                        symbol: _currencySymbol,
                        name: _currencyCode,
                      ).format(income.monto),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.getSuccessColor(context),
                      ),
                      textAlign: TextAlign.end,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.edit,
                            size: 16,
                            color: AppColors.getTextSecondaryColor(context),
                          ),
                          onPressed: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => EditIncomePage(
                                  income: income,
                                  categories: _categoriesList
                                      .where((c) => c != 'Todas')
                                      .toList(),
                                ),
                              ),
                            );
                            _loadIncomes();
                          },
                          tooltip: 'Editar',
                          constraints: const BoxConstraints(
                            minWidth: 24,
                            minHeight: 24,
                          ),
                          padding: EdgeInsets.zero,
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.delete,
                            size: 16,
                            color: AppColors.getDangerColor(context),
                          ),
                          onPressed: () => _showDeleteIncomeDialog(income),
                          tooltip: 'Eliminar',
                          constraints: const BoxConstraints(
                            minWidth: 24,
                            minHeight: 24,
                          ),
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }

    // Para "Ambos" o solo gastos
    List<Widget> allItems = [];

    // Agregar gastos filtrados
    for (final expense in _filteredExpenses) {
      allItems.add(
        Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          color: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.getBorderColor(context).withOpacity(0.1),
                width: 1,
              ),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.getCategoryColorWithOpacity(
                    expense.categoria,
                    0.1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getCategoryIcon(expense.categoria),
                  color: AppColors.getCategoryColor(expense.categoria),
                  size: 24,
                ),
              ),
              title: Text(
                expense.nombre,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.getCategoryColorWithOpacity(
                            expense.categoria,
                            0.1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          expense.categoria,
                          style: TextStyle(
                            color: AppColors.getCategoryColor(
                              expense.categoria,
                            ),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('dd/MM/yyyy').format(expense.fecha),
                        style: TextStyle(
                          color: AppColors.getTextSecondaryColor(context),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  if (expense.recurrente != null &&
                      expense.recurrente != 'ninguna') ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.repeat,
                          size: 14,
                          color: AppColors.getInfoColor(context),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          expense.recurrenciaText,
                          style: TextStyle(
                            color: AppColors.getInfoColor(context),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (expense.nota != null && expense.nota!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.note_alt,
                          size: 16,
                          color: AppColors.getWarningColor(context),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          fit: FlexFit.loose,
                          child: Text(
                            expense.nota!,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: AppColors.getTextSecondaryColor(
                                    context,
                                  ),
                                  fontStyle: FontStyle.italic,
                                  fontSize: 12,
                                ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              trailing: SizedBox(
                width: 120,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      NumberFormat.currency(
                        locale: 'es_MX',
                        symbol: _currencySymbol,
                        name: _currencyCode,
                      ).format(expense.monto),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.getDangerColor(context),
                      ),
                      textAlign: TextAlign.end,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (expense.recurrente != null &&
                            expense.recurrente != 'ninguna')
                          IconButton(
                            icon: Icon(
                              Icons.add_circle_outline,
                              size: 16,
                              color: AppColors.getInfoColor(context),
                            ),
                            onPressed: () => _createNextRecurrence(expense),
                            tooltip: 'Crear siguiente recurrencia',
                            constraints: const BoxConstraints(
                              minWidth: 24,
                              minHeight: 24,
                            ),
                            padding: EdgeInsets.zero,
                          ),
                        IconButton(
                          icon: Icon(
                            Icons.edit,
                            size: 16,
                            color: AppColors.getTextSecondaryColor(context),
                          ),
                          onPressed: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => EditExpensePage(
                                  expense: expense,
                                  categories: _categoriesList
                                      .where((c) => c != 'Todas')
                                      .toList(),
                                ),
                              ),
                            );
                            _loadExpenses();
                          },
                          tooltip: 'Editar',
                          constraints: const BoxConstraints(
                            minWidth: 24,
                            minHeight: 24,
                          ),
                          padding: EdgeInsets.zero,
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.delete,
                            size: 16,
                            color: AppColors.getDangerColor(context),
                          ),
                          onPressed: () => _showDeleteDialog(expense),
                          tooltip: 'Eliminar',
                          constraints: const BoxConstraints(
                            minWidth: 24,
                            minHeight: 24,
                          ),
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Si el filtro es "Ambos", agregar ingresos filtrados también
    if (_filterType == 'Ambos') {
      for (final income in _filteredIncomes) {
        allItems.add(
          Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            color: Theme.of(context).colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                backgroundColor: AppColors.getSuccessColor(context),
                child: const Icon(Icons.attach_money, color: Colors.white),
              ),
              title: Text(
                income.nombre,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    income.categoria,
                    style: TextStyle(
                      color: AppColors.getTextSecondaryColor(context),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('dd/MM/yyyy').format(income.fecha),
                    style: TextStyle(
                      color: AppColors.getTextSecondaryColor(context),
                      fontSize: 12,
                    ),
                  ),
                  if (income.nota != null && income.nota!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.note_alt,
                          size: 16,
                          color: AppColors.getWarningColor(context),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          fit: FlexFit.loose,
                          child: Text(
                            income.nota!,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: AppColors.getTextSecondaryColor(
                                    context,
                                  ),
                                  fontStyle: FontStyle.italic,
                                ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              trailing: SizedBox(
                width: 120,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      NumberFormat.currency(
                        locale: 'es_MX',
                        symbol: _currencySymbol,
                        name: _currencyCode,
                      ).format(income.monto),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.getSuccessColor(context),
                      ),
                      textAlign: TextAlign.end,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.edit,
                            size: 16,
                            color: AppColors.getTextSecondaryColor(context),
                          ),
                          onPressed: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => EditIncomePage(
                                  income: income,
                                  categories: _categoriesList
                                      .where((c) => c != 'Todas')
                                      .toList(),
                                ),
                              ),
                            );
                            _loadIncomes();
                          },
                          tooltip: 'Editar',
                          constraints: const BoxConstraints(
                            minWidth: 24,
                            minHeight: 24,
                          ),
                          padding: EdgeInsets.zero,
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.delete,
                            size: 16,
                            color: AppColors.getDangerColor(context),
                          ),
                          onPressed: () => _showDeleteIncomeDialog(income),
                          tooltip: 'Eliminar',
                          constraints: const BoxConstraints(
                            minWidth: 24,
                            minHeight: 24,
                          ),
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? NeverScrollableScrollPhysics() : null,
      children: allItems,
    );
  }

  Color _getCategoryColor(String categoria) {
    return AppColors.getCategoryColor(categoria);
  }

  IconData _getCategoryIcon(String categoria) {
    switch (categoria.toLowerCase()) {
      case 'comida':
        return Icons.restaurant;
      case 'transporte':
        return Icons.directions_car;
      case 'ocio':
        return Icons.movie;
      case 'servicios':
        return Icons.home;
      case 'ropa':
        return Icons.checkroom;
      default:
        return Icons.category;
    }
  }

  void _showDeleteIncomeDialog(Income income) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Ingreso'),
        content: Text(
          '¿Estás seguro de que quieres eliminar "${income.nombre}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _dbHelper.deleteIncome(income.id!);
              _loadIncomes();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Ingreso eliminado correctamente'),
                  ),
                );
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.getDangerColor(context),
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Future<void> _createNextRecurrence(Expense expense) async {
    try {
      await _dbHelper.createNextRecurrence(expense);
      await _loadExpenses();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Siguiente ${expense.recurrenciaText.toLowerCase()} creado automáticamente',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al crear recurrencia: $e')),
        );
      }
    }
  }
}
