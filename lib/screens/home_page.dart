import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/transaction_provider.dart';
import '../models/api_models.dart';
import '../models/account.dart';
import '../services/api_service.dart';
import 'transaction_form_screen.dart';
import 'edit_transaction_screen.dart';
import 'profile_screen.dart';
import 'categories_screen.dart';
import 'budgets_screen.dart';
import 'accounts_screen.dart';
import 'transfer_categories_screen.dart';
import 'account_reports_screen.dart';
import 'stats_page.dart';
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import '../utils/web_csv_download.dart'
    if (dart.library.html) '../utils/web_csv_download_web.dart';
import '../widgets/balance_cards.dart';
import '../widgets/account_cards.dart';
import '../widgets/transaction_filters.dart';
import '../theme/app_theme.dart';
import '../providers/theme_provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Transaction> _filteredTransactions = [];
  List<Account> _accounts = [];
  String _username = '';
  bool _isLoading = true;
  String _currencyCode = 'USD';
  String _currencySymbol = '\$';
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
  List<String> _categories = [];
  List<String> get _categoriesList => ['Todas', ..._categories];

  String _filterType = 'Ambos'; // 'Gastos', 'Ingresos', 'Ambos'

  // Paginación
  int _currentPage = 1;
  static const int _itemsPerPage = 15;
  int get _totalPages => (_filteredTransactions.length / _itemsPerPage).ceil();
  List<Transaction> get _paginatedTransactions {
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(
      0,
      _filteredTransactions.length,
    );
    return _filteredTransactions.sublist(startIndex, endIndex);
  }

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
    _searchController.addListener(_applyFilters);
    _loadBudget();
    _loadCategories();

    // Load data asynchronously to avoid blocking UI
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _minAmountController.dispose();
    _maxAmountController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _loadUsername();
      _loadCurrencyFromProfile();
      await _loadAccounts();

      // Load data from TransactionProvider
      final transactionProvider = Provider.of<TransactionProvider>(
        context,
        listen: false,
      );
      await transactionProvider.loadData();

      // Apply initial filters after loading data
      _applyFilters();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadUsername() async {
    if (!mounted) return;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (mounted) {
      setState(() {
        _username = authProvider.user?.name ?? 'Usuario';
      });
    }
  }

  Future<void> _loadAccounts() async {
    try {
      final apiService = ApiService();
      final response = await apiService.getAccounts();
      if (response.success && response.data != null) {
        try {
          final accountsList = response.data as List;
          final accounts = accountsList
              .map(
                (account) => Account.fromMap(account as Map<String, dynamic>),
              )
              .toList();

          setState(() {
            _accounts = accounts;
          });
        } catch (e) {
          // Handle error silently for now
        }
      }
    } catch (e) {
      // Handle error silently for now
    }
  }

  Future<void> _loadBudget() async {
    // This method is kept for future use when budget data is needed
    // Currently budgets are managed in the BudgetsScreen
  }

  void _showBudgetsDialog() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => const BudgetsScreen()))
        .then((_) {
          // Refresh budget data after returning from budgets screen
          _loadBudget();
        });
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.getErrorColor(context),
            ),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.logout();
    }
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: AppTheme.getBackgroundColor(context),
      child: Column(
        children: [
          // Header
          Container(
            height: 200,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.getPrimaryColor(context),
                  AppTheme.getPrimaryColor(context).withOpacity(0.8),
                ],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.person_rounded,
                            size: 32,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _username.isNotEmpty ? _username : 'Usuario',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Gestor de Gastos',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Menu Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                // Gestión de Datos
                _buildDrawerSection(
                  title: 'Gestión de Datos',
                  items: [
                    _buildDrawerItem(
                      icon: Icons.category_rounded,
                      title: 'Categorías',
                      subtitle: 'Gestionar categorías',
                      onTap: () {
                        Navigator.pop(context);
                        _showCategoriesDialog();
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.account_balance_wallet_rounded,
                      title: 'Presupuestos',
                      subtitle: 'Controlar gastos',
                      onTap: () {
                        Navigator.pop(context);
                        _showBudgetsDialog();
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.account_balance_rounded,
                      title: 'Cuentas',
                      subtitle: 'Gestionar balances',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AccountsScreen(),
                          ),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.swap_horiz_rounded,
                      title: 'Categorías de Transferencias',
                      subtitle: 'Gestionar categorías de transferencias',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const TransferCategoriesScreen(),
                          ),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.analytics_rounded,
                      title: 'Reportes de Cuentas',
                      subtitle: 'Análisis y proyecciones',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AccountReportsScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Configuración
                _buildDrawerSection(
                  title: 'Configuración',
                  items: [
                    _buildDrawerItem(
                      icon: Icons.person_rounded,
                      title: 'Mi Perfil',
                      subtitle: 'Editar información',
                      onTap: () {
                        Navigator.pop(context);
                        _editProfile();
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.brightness_6_rounded,
                      title: 'Cambiar Tema',
                      subtitle: 'Personalizar apariencia',
                      onTap: () {
                        Navigator.pop(context);
                        _showThemeDialog();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Sesión
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildDrawerItem(
                    icon: Icons.logout_rounded,
                    title: 'Cerrar Sesión',
                    subtitle: 'Salir de la aplicación',
                    onTap: () {
                      Navigator.pop(context);
                      _logout();
                    },
                    isDanger: true,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerSection({
    required String title,
    required List<Widget> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Text(
            title,
            style: TextStyle(
              color: AppTheme.getTextSecondaryColor(context),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        ...items,
      ],
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    bool isDanger = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isDanger
                ? AppTheme.getErrorColor(context).withOpacity(0.1)
                : AppTheme.getPrimaryColor(context).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: isDanger
                ? AppTheme.getErrorColor(context)
                : AppTheme.getPrimaryColor(context),
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isDanger
                ? AppTheme.getErrorColor(context)
                : AppTheme.getTextPrimaryColor(context),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: TextStyle(
                  color: isDanger
                      ? AppTheme.getErrorColor(context).withOpacity(0.7)
                      : AppTheme.getTextSecondaryColor(context),
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              )
            : null,
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _applyFilters() {
    String search = _searchController.text.toLowerCase();
    String category = _selectedCategory;

    final transactionProvider = Provider.of<TransactionProvider>(
      context,
      listen: false,
    );
    List<Transaction> allTransactions = transactionProvider.transactions;

    _filteredTransactions = allTransactions.where((transaction) {
      // Filtro de búsqueda
      final matchesSearch = transaction.description.toLowerCase().contains(
        search,
      );

      // Filtro de categoría
      final matchesCategory =
          category == 'Todas' || transaction.category.name == category;

      // Filtro de tipo
      final matchesType =
          _filterType == 'Ambos' ||
          (_filterType == 'Gastos' && transaction.type == 'expense') ||
          (_filterType == 'Ingresos' && transaction.type == 'income');

      // Filtro de fecha
      final matchesDate =
          (_startDate == null ||
              transaction.date.isAfter(
                _startDate!.subtract(const Duration(days: 1)),
              )) &&
          (_endDate == null ||
              transaction.date.isBefore(
                _endDate!.add(const Duration(days: 1)),
              ));

      // Filtro de monto
      final matchesAmount =
          (_minAmount == null || transaction.amount >= _minAmount!) &&
          (_maxAmount == null || transaction.amount <= _maxAmount!);

      return matchesSearch &&
          matchesCategory &&
          matchesType &&
          matchesDate &&
          matchesAmount;
    }).toList();

    // Reset to first page when filters change
    _currentPage = 1;

    setState(() {});
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

  Future<void> _deleteTransaction(String id) async {
    try {
      final transactionProvider = Provider.of<TransactionProvider>(
        context,
        listen: false,
      );
      final success = await transactionProvider.deleteTransaction(id);

      if (success) {
        _applyFilters();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Transacción eliminada correctamente'),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(transactionProvider.getErrorMessage()),
              backgroundColor: AppTheme.getErrorColor(context),
              action: SnackBarAction(
                label: 'Reintentar',
                textColor: Colors.white,
                onPressed: () => _deleteTransaction(id),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al eliminar: $e')));
      }
    }
  }

  void _showDeleteDialog(Transaction transaction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Eliminar ${transaction.type == 'income' ? 'Ingreso' : 'Gasto'}',
        ),
        content: Text(
          '¿Estás seguro de que quieres eliminar "${transaction.description}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteTransaction(transaction.id);
            },
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.getErrorColor(context),
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
        [
          'ID',
          'Tipo',
          'Descripción',
          'Monto',
          'Categoría',
          'Fecha',
          'Método de Pago',
        ],
      ];
      // Datos
      for (var transaction in _filteredTransactions) {
        rows.add([
          transaction.id,
          transaction.type == 'income' ? 'Ingreso' : 'Gasto',
          transaction.description,
          transaction.amount,
          transaction.category.name,
          transaction.date.toIso8601String(),
          transaction.paymentMethod,
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

  void _showThemeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Seleccionar tema',
          style: TextStyle(color: AppTheme.getTextPrimaryColor(context)),
        ),
        backgroundColor: AppTheme.getSurfaceColor(context),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                Icons.brightness_auto,
                color: AppTheme.getPrimaryColor(context),
              ),
              title: Text(
                'Automático (según sistema)',
                style: TextStyle(color: AppTheme.getTextPrimaryColor(context)),
              ),
              onTap: () {
                Provider.of<ThemeProvider>(
                  context,
                  listen: false,
                ).setThemeMode(ThemeMode.system);
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: Icon(
                Icons.light_mode,
                color: AppTheme.getPrimaryColor(context),
              ),
              title: Text(
                'Claro',
                style: TextStyle(color: AppTheme.getTextPrimaryColor(context)),
              ),
              onTap: () {
                Provider.of<ThemeProvider>(
                  context,
                  listen: false,
                ).setThemeMode(ThemeMode.light);
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: Icon(
                Icons.dark_mode,
                color: AppTheme.getPrimaryColor(context),
              ),
              title: Text(
                'Oscuro',
                style: TextStyle(color: AppTheme.getTextPrimaryColor(context)),
              ),
              onTap: () {
                Provider.of<ThemeProvider>(
                  context,
                  listen: false,
                ).setThemeMode(ThemeMode.dark);
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadCategories() async {
    final transactionProvider = Provider.of<TransactionProvider>(
      context,
      listen: false,
    );
    setState(() {
      _categories = transactionProvider.categories
          .where((c) => c.type == 'expense')
          .map((c) => c.name)
          .toList();
    });
  }

  void _showCategoriesDialog() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => const CategoriesScreen()))
        .then((_) {
          // Refresh categories after returning from categories screen
          _loadCategories();
        });
  }

  Future<void> _editProfile() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const ProfileScreen()));
    // Refresh user data after profile update
    _loadUsername();
    _loadCurrencyFromProfile();
  }

  Future<void> _loadCurrencyFromProfile() async {
    if (!mounted) return;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (mounted) {
      setState(() {
        _currencyCode = authProvider.user?.currency ?? 'USD';
        _currencySymbol = _currencies[_currencyCode] ?? '\$';
      });
    }
  }

  // Getters para los totales
  double get _totalThisMonth {
    final transactionProvider = Provider.of<TransactionProvider>(
      context,
      listen: false,
    );
    final now = DateTime.now();
    return transactionProvider.transactions
        .where(
          (t) =>
              t.type == 'expense' &&
              t.date.year == now.year &&
              t.date.month == now.month,
        )
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get _totalIncomesThisMonth {
    final transactionProvider = Provider.of<TransactionProvider>(
      context,
      listen: false,
    );
    final now = DateTime.now();
    return transactionProvider.transactions
        .where(
          (t) =>
              t.type == 'income' &&
              t.date.year == now.year &&
              t.date.month == now.month,
        )
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hola, $_username',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            Text(
              'Gestiona tus finanzas',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.8),
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.getPrimaryColor(context),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const StatsPage()),
              );
            },
            tooltip: 'Estadísticas',
          ),
          IconButton(
            icon: const Icon(Icons.download_rounded),
            onPressed: _exportToCSV,
            tooltip: 'Exportar',
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppTheme.getPrimaryColor(context),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Cargando tus datos...',
                    style: TextStyle(
                      color: AppTheme.getTextSecondaryColor(context),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Balance Cards
                  BalanceCards(
                    monthlyIncome: _totalIncomesThisMonth,
                    monthlyExpenses: _totalThisMonth,
                    monthlyBalance: _totalIncomesThisMonth - _totalThisMonth,
                    currencySymbol: _currencySymbol,
                    currencyCode: _currencyCode,
                  ),
                  // Account Cards
                  AccountCards(
                    accounts: _accounts,
                    currencySymbol: _currencySymbol,
                  ),
                  // Filtros
                  TransactionFilters(
                    selectedType: _filterType,
                    selectedCategory: _selectedCategory,
                    categories: _categoriesList,
                    onTypeChanged: (type) {
                      setState(() => _filterType = type);
                      _applyFilters();
                    },
                    onCategoryChanged: (category) {
                      setState(() => _selectedCategory = category);
                      _applyFilters();
                    },
                    onClearFilters: () {
                      setState(() {
                        _filterType = 'Ambos';
                        _selectedCategory = 'Todas';
                        _searchController.clear();
                        _startDate = null;
                        _endDate = null;
                        _minAmount = null;
                        _maxAmount = null;
                        _minAmountController.clear();
                        _maxAmountController.clear();
                        _searchInNotes = false;
                        _showAdvancedFilters = false;
                      });
                      _applyFilters();
                    },
                  ),
                  const SizedBox(height: 16),
                  // Búsqueda
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Buscar transacciones...',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: _showAdvancedFilters
                            ? IconButton(
                                icon: const Icon(Icons.filter_list_off_rounded),
                                onPressed: () {
                                  setState(() {
                                    _showAdvancedFilters = false;
                                  });
                                },
                                tooltip: 'Ocultar filtros avanzados',
                              )
                            : IconButton(
                                icon: const Icon(Icons.filter_list_rounded),
                                onPressed: () {
                                  setState(() {
                                    _showAdvancedFilters = true;
                                  });
                                },
                                tooltip: 'Filtros avanzados',
                              ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFE2E8F0),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFE2E8F0),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF6366F1),
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
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
                  // Lista de transacciones
                  _shouldShowEmptyState()
                      ? _buildEmptyState()
                      : SizedBox(
                          height:
                              MediaQuery.of(context).size.height *
                              0.5, // 50% de la pantalla
                          child: _buildExpensesList(),
                        ),

                  // Controles de paginación
                  if (!_shouldShowEmptyState() && _totalPages > 1)
                    _buildPaginationControls(),
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
                color: AppTheme.getSurfaceColor(context),
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
                        color: AppTheme.getTextSecondaryColor(context),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Agregar nuevo',
                      style: TextStyle(
                        color: AppTheme.getTextPrimaryColor(context),
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
                                        builder: (context) =>
                                            const TransactionFormScreen(
                                              type: 'expense',
                                            ),
                                      ),
                                    )
                                    .then((_) => _loadData());
                              },
                              icon: const Icon(Icons.remove_circle_outline),
                              label: const Text('Gasto'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.getErrorColor(
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
                                        builder: (context) =>
                                            const TransactionFormScreen(
                                              type: 'income',
                                            ),
                                      ),
                                    )
                                    .then((_) => _loadData());
                              },
                              icon: const Icon(Icons.add_circle_outline),
                              label: const Text('Ingreso'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.getSuccessColor(
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
        backgroundColor: AppTheme.getPrimaryColor(context),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Agregar'),
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  bool _shouldShowEmptyState() {
    return _filteredTransactions.isEmpty;
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
        message = 'No hay transacciones registradas';
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
              color: AppTheme.getTextSecondaryColor(context),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.getTextSecondaryColor(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.getTextSecondaryColor(context),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaginationControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Información de página
          Text(
            'Página $_currentPage de $_totalPages (${_filteredTransactions.length} transacciones)',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.getTextSecondaryColor(context),
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 12),

          // Controles de navegación
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Botón primera página
              IconButton(
                onPressed: _currentPage > 1 ? _firstPage : null,
                icon: const Icon(Icons.first_page),
                style: IconButton.styleFrom(
                  backgroundColor: _currentPage > 1
                      ? AppTheme.getPrimaryColor(context).withOpacity(0.1)
                      : null,
                ),
                tooltip: 'Primera página',
              ),

              // Botón anterior
              IconButton(
                onPressed: _currentPage > 1 ? _previousPage : null,
                icon: const Icon(Icons.chevron_left),
                style: IconButton.styleFrom(
                  backgroundColor: _currentPage > 1
                      ? AppTheme.getPrimaryColor(context).withOpacity(0.1)
                      : null,
                ),
                tooltip: 'Página anterior',
              ),

              // Indicador de páginas
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.getPrimaryColor(context).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$_currentPage / $_totalPages',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.getPrimaryColor(context),
                  ),
                ),
              ),

              // Botón siguiente
              IconButton(
                onPressed: _currentPage < _totalPages ? _nextPage : null,
                icon: const Icon(Icons.chevron_right),
                style: IconButton.styleFrom(
                  backgroundColor: _currentPage < _totalPages
                      ? AppTheme.getPrimaryColor(context).withOpacity(0.1)
                      : null,
                ),
                tooltip: 'Página siguiente',
              ),

              // Botón última página
              IconButton(
                onPressed: _currentPage < _totalPages ? _lastPage : null,
                icon: const Icon(Icons.last_page),
                style: IconButton.styleFrom(
                  backgroundColor: _currentPage < _totalPages
                      ? AppTheme.getPrimaryColor(context).withOpacity(0.1)
                      : null,
                ),
                tooltip: 'Última página',
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _previousPage() {
    if (_currentPage > 1) {
      setState(() {
        _currentPage--;
      });
    }
  }

  void _nextPage() {
    if (_currentPage < _totalPages) {
      setState(() {
        _currentPage++;
      });
    }
  }

  void _firstPage() {
    if (_currentPage > 1) {
      setState(() {
        _currentPage = 1;
      });
    }
  }

  void _lastPage() {
    if (_currentPage < _totalPages) {
      setState(() {
        _currentPage = _totalPages;
      });
    }
  }

  Widget _buildExpensesList({bool shrinkWrap = false}) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _paginatedTransactions.length,
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap
          ? NeverScrollableScrollPhysics()
          : const AlwaysScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final transaction = _paginatedTransactions[index];
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
              backgroundColor: transaction.type == 'income'
                  ? AppTheme.getSuccessColor(context)
                  : AppTheme.getErrorColor(context),
              child: Icon(
                transaction.type == 'income'
                    ? Icons.attach_money
                    : Icons.remove_circle,
                color: Colors.white,
              ),
            ),
            title: Text(
              transaction.description,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  transaction.category.name,
                  style: TextStyle(
                    color: AppTheme.getTextSecondaryColor(context),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('dd/MM/yyyy').format(transaction.date),
                  style: TextStyle(
                    color: AppTheme.getTextSecondaryColor(context),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Método: ${transaction.paymentMethod}',
                  style: TextStyle(
                    color: AppTheme.getTextSecondaryColor(context),
                    fontSize: 12,
                  ),
                ),
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
                    ).format(transaction.amount),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: transaction.type == 'income'
                          ? AppTheme.getSuccessColor(context)
                          : AppTheme.getErrorColor(context),
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
                          color: AppTheme.getTextSecondaryColor(context),
                        ),
                        onPressed: () async {
                          final result = await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => EditTransactionScreen(
                                transaction: transaction,
                              ),
                            ),
                          );
                          if (result == true) {
                            _loadData();
                          }
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
                          color: AppTheme.getErrorColor(context),
                        ),
                        onPressed: () => _showDeleteDialog(transaction),
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
}
