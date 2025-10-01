import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../models/api_models.dart' as api_models;
import '../models/account.dart';
import '../services/api_service.dart';
import '../widgets/category_chart.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _apiService = ApiService();
  List<Account> _accounts = [];
  bool _isLoadingAccounts = false;
  String? _accountsError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    // Load data when the page is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final transactionProvider = Provider.of<TransactionProvider>(
      context,
      listen: false,
    );
    await transactionProvider.loadData();
    await _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    if (!mounted) return;

    setState(() {
      _isLoadingAccounts = true;
      _accountsError = null;
    });

    try {
      final response = await _apiService.getAccounts();
      if (!mounted) return;

      if (response.success && response.data != null) {
        setState(() {
          _accounts = (response.data as List)
              .map((item) => Account.fromMap(item))
              .toList();
          _isLoadingAccounts = false;
        });
      } else {
        setState(() {
          _accountsError = response.message ?? 'Error al cargar cuentas';
          _isLoadingAccounts = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _accountsError = 'Error de conexión: $e';
        _isLoadingAccounts = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Análisis Financiero'),
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withOpacity(0.7),
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            tabs: const [
              Tab(
                icon: Icon(Icons.dashboard_rounded, size: 18),
                text: 'Resumen',
              ),
              Tab(
                icon: Icon(Icons.account_balance_wallet, size: 18),
                text: 'Por Cuenta',
              ),
              Tab(icon: Icon(Icons.category, size: 18), text: 'Por Categoría'),
              Tab(
                icon: Icon(Icons.trending_up, size: 18),
                text: 'Proyecciones',
              ),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildSummaryTab(),
            _buildAccountAnalysisTab(),
            _buildCategoryAnalysisTab(),
            _buildProjectionsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryTab() {
    return Consumer<TransactionProvider>(
      builder: (context, transactionProvider, child) {
        if (transactionProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (transactionProvider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  transactionProvider.getErrorMessage(),
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => transactionProvider.loadData(),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }

        final totalIncome = transactionProvider.totalIncome;
        final totalExpenses = transactionProvider.totalExpenses;
        final balance = totalIncome - totalExpenses;
        final incomes = transactionProvider.incomeTransactions;
        final expenses = transactionProvider.expenseTransactions;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Resumen general mejorado
              _buildEnhancedSummaryCard(
                totalIncome,
                totalExpenses,
                balance,
                incomes,
                expenses,
              ),
              const SizedBox(height: 24),

              // Análisis de tendencias mensuales
              _buildMonthlyTrendsAnalysis(incomes, expenses),
              const SizedBox(height: 24),

              // Top categorías de gastos
              if (expenses.isNotEmpty)
                _buildTopCategoriesCard(expenses, 'Gastos', Colors.red),
              const SizedBox(height: 24),

              // Top categorías de ingresos
              if (incomes.isNotEmpty)
                _buildTopCategoriesCard(incomes, 'Ingresos', Colors.green),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAccountAnalysisTab() {
    return Consumer<TransactionProvider>(
      builder: (context, transactionProvider, child) {
        if (_isLoadingAccounts || transactionProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (_accountsError != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  _accountsError!,
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _loadAccounts(),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }

        if (_accounts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.account_balance_wallet,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No hay cuentas',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Agrega tu primera cuenta',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        final transactions = transactionProvider.transactions;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Resumen general de cuentas
              _buildAccountsSummary(_accounts),
              const SizedBox(height: 24),

              // Análisis de actividad por cuenta
              _buildAccountActivityAnalysis(_accounts, transactions),
              const SizedBox(height: 24),

              // Análisis de ingresos vs gastos por cuenta
              _buildIncomeVsExpensesAnalysis(_accounts, transactions),
              const SizedBox(height: 24),

              // Análisis de movimientos recientes por cuenta
              _buildRecentActivityAnalysis(_accounts, transactions),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryAnalysisTab() {
    return Consumer<TransactionProvider>(
      builder: (context, transactionProvider, child) {
        if (transactionProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (transactionProvider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  transactionProvider.getErrorMessage(),
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => transactionProvider.loadData(),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }

        final incomeTransactions = transactionProvider.incomeTransactions;
        final expenseTransactions = transactionProvider.expenseTransactions;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Top categorías de gastos
              if (expenseTransactions.isNotEmpty)
                _buildTopCategoriesCard(
                  expenseTransactions,
                  'Gastos',
                  Colors.red,
                ),
              const SizedBox(height: 24),

              // Top categorías de ingresos
              if (incomeTransactions.isNotEmpty)
                _buildTopCategoriesCard(
                  incomeTransactions,
                  'Ingresos',
                  Colors.green,
                ),
              const SizedBox(height: 24),

              // Categorías más activas
              _buildMostActiveCategoriesCard(
                incomeTransactions,
                expenseTransactions,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProjectionsTab() {
    return Consumer<TransactionProvider>(
      builder: (context, transactionProvider, child) {
        if (transactionProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (transactionProvider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  transactionProvider.getErrorMessage(),
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => transactionProvider.loadData(),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }

        final incomes = transactionProvider.incomeTransactions;
        final expenses = transactionProvider.expenseTransactions;

        // Calcular proyecciones
        final avgMonthlyIncome = _calculateAverageMonthly(incomes);
        final avgMonthlyExpenses = _calculateAverageMonthly(expenses);
        final projectedBalance = avgMonthlyIncome - avgMonthlyExpenses;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Proyección de balance
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.trending_up,
                            color: Theme.of(context).primaryColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Proyección de Balance',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildProjectionCard(
                              'Ingresos Promedio',
                              avgMonthlyIncome,
                              Icons.trending_up,
                              Colors.green,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildProjectionCard(
                              'Gastos Promedio',
                              avgMonthlyExpenses,
                              Icons.trending_down,
                              Colors.red,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: projectedBalance >= 0
                              ? Colors.green.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: projectedBalance >= 0
                                ? Colors.green
                                : Colors.red,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              projectedBalance >= 0
                                  ? Icons.savings
                                  : Icons.warning,
                              color: projectedBalance >= 0
                                  ? Colors.green
                                  : Colors.red,
                              size: 32,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Balance Proyectado',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                    'RD\$${projectedBalance.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: projectedBalance >= 0
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  ),
                                  Text(
                                    projectedBalance >= 0
                                        ? 'Tendencia positiva'
                                        : 'Revisar gastos',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: projectedBalance >= 0
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Análisis de tendencias
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Análisis de Tendencias',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildTrendAnalysis('Ingresos', incomes, Colors.green),
                      const SizedBox(height: 12),
                      _buildTrendAnalysis('Gastos', expenses, Colors.red),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Map<String, double> _getCategoryData(
    List<api_models.Transaction> transactions,
  ) {
    final Map<String, double> categoryData = {};
    for (final transaction in transactions) {
      final categoryName = transaction.category.name;
      categoryData[categoryName] =
          (categoryData[categoryName] ?? 0) + transaction.amount;
    }
    return categoryData;
  }

  double _calculateAverageMonthly(List<api_models.Transaction> transactions) {
    if (transactions.isEmpty) return 0.0;

    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    final monthlyTransactions = transactions.where((t) {
      return t.date.isAfter(startOfMonth.subtract(const Duration(days: 1))) &&
          t.date.isBefore(endOfMonth.add(const Duration(days: 1)));
    }).toList();

    if (monthlyTransactions.isEmpty) return 0.0;

    final total = monthlyTransactions.fold(0.0, (sum, t) => sum + t.amount);
    return total;
  }

  Widget _buildProjectionCard(
    String title,
    double amount,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'RD\$${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendAnalysis(
    String title,
    List<api_models.Transaction> transactions,
    Color color,
  ) {
    final total = transactions.fold(0.0, (sum, t) => sum + t.amount);
    final count = transactions.length;
    final avg = count > 0 ? total / count : 0.0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.trending_up, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                Text(
                  'Total: RD\$${total.toStringAsFixed(2)} | Promedio: RD\$${avg.toStringAsFixed(2)} | Transacciones: $count',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountsSummary(List<Account> accounts) {
    final totalBalance = accounts.fold(
      0.0,
      (sum, account) => sum + account.balance,
    );
    final totalCreditLimit = accounts
        .where((account) => account.creditLimit != null)
        .fold(0.0, (sum, account) => sum + (account.creditLimit ?? 0));
    final availableCredit = accounts
        .where((account) => account.availableCredit != null)
        .fold(0.0, (sum, account) => sum + (account.availableCredit ?? 0));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumen de Cuentas',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'Balance Total',
                    totalBalance,
                    Icons.account_balance,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSummaryItem(
                    'Límite de Crédito',
                    totalCreditLimit,
                    Icons.credit_card,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'Crédito Disponible',
                    availableCredit,
                    Icons.savings,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSummaryItem(
                    'Total de Cuentas',
                    accounts.length.toDouble(),
                    Icons.account_balance_wallet,
                    Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
    String title,
    double value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'RD\$${value.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountActivityAnalysis(
    List<Account> accounts,
    List<api_models.Transaction> transactions,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Actividad por Cuenta',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Resumen de movimientos en el último mes',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ...accounts.map((account) {
              final now = DateTime.now();
              final lastMonth = DateTime(now.year, now.month - 1, 1);
              final thisMonth = DateTime(now.year, now.month, 1);

              final accountTransactions = transactions
                  .where(
                    (t) =>
                        t.account?.id == account.id ||
                        t.toAccount?.id == account.id,
                  )
                  .toList();

              final thisMonthTransactions = accountTransactions
                  .where(
                    (t) => t.date.isAfter(
                      thisMonth.subtract(const Duration(days: 1)),
                    ),
                  )
                  .toList();

              final income = thisMonthTransactions
                  .where(
                    (t) => t.type == 'income' && t.account?.id == account.id,
                  )
                  .fold(0.0, (sum, t) => sum + t.amount);

              final expenses = thisMonthTransactions
                  .where(
                    (t) => t.type == 'expense' && t.account?.id == account.id,
                  )
                  .fold(0.0, (sum, t) => sum + t.amount);

              final transfers = thisMonthTransactions
                  .where((t) => t.type == 'transfer')
                  .length;

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _getAccountTypeColor(
                          account.type,
                        ).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getAccountTypeIcon(account.type),
                        color: _getAccountTypeColor(account.type),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            account.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${thisMonthTransactions.length} movimientos este mes',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (income > 0)
                          Text(
                            '+RD\$${income.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.green,
                            ),
                          ),
                        if (expenses > 0)
                          Text(
                            '-RD\$${expenses.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.red,
                            ),
                          ),
                        if (transfers > 0)
                          Text(
                            '$transfers transferencias',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[500],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildIncomeVsExpensesAnalysis(
    List<Account> accounts,
    List<api_models.Transaction> transactions,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ingresos vs Gastos por Cuenta',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Comparación de este mes',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ...accounts.map((account) {
              final now = DateTime.now();
              final thisMonth = DateTime(now.year, now.month, 1);

              final thisMonthTransactions = transactions.where((t) {
                return (t.account?.id == account.id ||
                        t.toAccount?.id == account.id) &&
                    t.date.isAfter(thisMonth.subtract(const Duration(days: 1)));
              }).toList();

              final income = thisMonthTransactions
                  .where(
                    (t) => t.type == 'income' && t.account?.id == account.id,
                  )
                  .fold(0.0, (sum, t) => sum + t.amount);

              final expenses = thisMonthTransactions
                  .where(
                    (t) => t.type == 'expense' && t.account?.id == account.id,
                  )
                  .fold(0.0, (sum, t) => sum + t.amount);

              final balance = income - expenses;

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: _getAccountTypeColor(
                              account.type,
                            ).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            _getAccountTypeIcon(account.type),
                            color: _getAccountTypeColor(account.type),
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          account.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: balance >= 0
                                ? Colors.green.withOpacity(0.1)
                                : Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            balance >= 0 ? 'Positivo' : 'Negativo',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: balance >= 0 ? Colors.green : Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildSimpleStatItem(
                            'Ingresos',
                            income,
                            Colors.green,
                            Icons.trending_up,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildSimpleStatItem(
                            'Gastos',
                            expenses,
                            Colors.red,
                            Icons.trending_down,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildSimpleStatItem(
                            'Balance',
                            balance,
                            balance >= 0 ? Colors.green : Colors.red,
                            Icons.account_balance,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivityAnalysis(
    List<Account> accounts,
    List<api_models.Transaction> transactions,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Movimientos Recientes por Cuenta',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Últimas transacciones de cada cuenta',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ...accounts.map((account) {
              final accountTransactions = transactions
                  .where(
                    (t) =>
                        t.account?.id == account.id ||
                        t.toAccount?.id == account.id,
                  )
                  .toList();

              if (accountTransactions.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _getAccountTypeColor(
                            account.type,
                          ).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          _getAccountTypeIcon(account.type),
                          color: _getAccountTypeColor(account.type),
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        account.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Sin movimientos',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                );
              }

              // Ordenar por fecha descendente y tomar las últimas 3
              final recentTransactions = accountTransactions
                ..sort((a, b) => b.date.compareTo(a.date));
              final lastThree = recentTransactions.take(3).toList();

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: _getAccountTypeColor(
                              account.type,
                            ).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            _getAccountTypeIcon(account.type),
                            color: _getAccountTypeColor(account.type),
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          account.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${accountTransactions.length} total',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...lastThree.map((transaction) {
                      final isIncome = transaction.type == 'income';
                      final isExpense = transaction.type == 'expense';
                      final isTransfer = transaction.type == 'transfer';

                      String description = transaction.description;
                      if (isTransfer) {
                        description = 'Transferencia';
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Icon(
                              isIncome
                                  ? Icons.trending_up
                                  : isExpense
                                  ? Icons.trending_down
                                  : Icons.swap_horiz,
                              size: 12,
                              color: isIncome
                                  ? Colors.green
                                  : isExpense
                                  ? Colors.red
                                  : Colors.blue,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                description,
                                style: const TextStyle(fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '${isIncome
                                  ? '+'
                                  : isExpense
                                  ? '-'
                                  : ''}RD\$${transaction.amount.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isIncome
                                    ? Colors.green
                                    : isExpense
                                    ? Colors.red
                                    : Colors.blue,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleStatItem(
    String title,
    double amount,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'RD\$${amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountStat(
    String label,
    double value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            'RD\$${value.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getAccountTypeColor(String type) {
    switch (type) {
      case 'checking':
        return Colors.blue;
      case 'savings':
        return Colors.green;
      case 'credit':
        return Colors.orange;
      case 'investment':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getAccountTypeIcon(String type) {
    switch (type) {
      case 'checking':
        return Icons.account_balance;
      case 'savings':
        return Icons.savings;
      case 'credit':
        return Icons.credit_card;
      case 'investment':
        return Icons.trending_up;
      default:
        return Icons.account_balance_wallet;
    }
  }

  String _getAccountTypeName(String type) {
    switch (type) {
      case 'checking':
        return 'Cuenta Corriente';
      case 'savings':
        return 'Cuenta de Ahorros';
      case 'credit':
        return 'Tarjeta de Crédito';
      case 'investment':
        return 'Inversión';
      default:
        return 'Cuenta';
    }
  }

  // Métodos mejorados para el tab Resumen
  Widget _buildEnhancedSummaryCard(
    double totalIncome,
    double totalExpenses,
    double balance,
    List<api_models.Transaction> incomes,
    List<api_models.Transaction> expenses,
  ) {
    final now = DateTime.now();
    final thisMonth = DateTime(now.year, now.month, 1);
    final lastMonth = DateTime(now.year, now.month - 1, 1);

    // Calcular datos del mes actual
    final thisMonthIncomes = incomes
        .where(
          (t) => t.date.isAfter(thisMonth.subtract(const Duration(days: 1))),
        )
        .toList();
    final thisMonthExpenses = expenses
        .where(
          (t) => t.date.isAfter(thisMonth.subtract(const Duration(days: 1))),
        )
        .toList();

    // Calcular datos del mes anterior
    final lastMonthIncomes = incomes
        .where(
          (t) =>
              t.date.isAfter(lastMonth.subtract(const Duration(days: 1))) &&
              t.date.isBefore(thisMonth),
        )
        .toList();
    final lastMonthExpenses = expenses
        .where(
          (t) =>
              t.date.isAfter(lastMonth.subtract(const Duration(days: 1))) &&
              t.date.isBefore(thisMonth),
        )
        .toList();

    final thisMonthIncome = thisMonthIncomes.fold(
      0.0,
      (sum, t) => sum + t.amount,
    );
    final thisMonthExpense = thisMonthExpenses.fold(
      0.0,
      (sum, t) => sum + t.amount,
    );
    final lastMonthIncome = lastMonthIncomes.fold(
      0.0,
      (sum, t) => sum + t.amount,
    );
    final lastMonthExpense = lastMonthExpenses.fold(
      0.0,
      (sum, t) => sum + t.amount,
    );

    final incomeChange = lastMonthIncome > 0
        ? ((thisMonthIncome - lastMonthIncome) / lastMonthIncome) * 100
        : 0.0;
    final expenseChange = lastMonthExpense > 0
        ? ((thisMonthExpense - lastMonthExpense) / lastMonthExpense) * 100
        : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.dashboard,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Resumen Financiero',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${now.month}/${now.year}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Métricas principales
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Ingresos',
                    thisMonthIncome,
                    incomeChange,
                    Icons.trending_up,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    'Gastos',
                    thisMonthExpense,
                    expenseChange,
                    Icons.trending_down,
                    Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Balance
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: balance >= 0
                    ? Colors.green.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: balance >= 0 ? Colors.green : Colors.red,
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'Balance del Mes',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'RD\$${balance.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: balance >= 0 ? Colors.green : Colors.red,
                    ),
                  ),
                  Text(
                    balance >= 0 ? 'Tendencia positiva' : 'Revisar gastos',
                    style: TextStyle(
                      fontSize: 12,
                      color: balance >= 0 ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    String title,
    double amount,
    double change,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'RD\$${amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          if (change != 0)
            Text(
              '${change > 0 ? '+' : ''}${change.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 10,
                color: change > 0 ? Colors.green : Colors.red,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMonthlyTrendsAnalysis(
    List<api_models.Transaction> incomes,
    List<api_models.Transaction> expenses,
  ) {
    final now = DateTime.now();
    final months = <String, Map<String, double>>{};

    // Analizar últimos 6 meses
    for (int i = 0; i < 6; i++) {
      final month = DateTime(now.year, now.month - i, 1);
      final monthStart = month;
      final monthEnd = DateTime(month.year, month.month + 1, 0);

      final monthIncomes = incomes
          .where(
            (t) =>
                t.date.isAfter(monthStart.subtract(const Duration(days: 1))) &&
                t.date.isBefore(monthEnd.add(const Duration(days: 1))),
          )
          .toList();

      final monthExpenses = expenses
          .where(
            (t) =>
                t.date.isAfter(monthStart.subtract(const Duration(days: 1))) &&
                t.date.isBefore(monthEnd.add(const Duration(days: 1))),
          )
          .toList();

      final incomeTotal = monthIncomes.fold(0.0, (sum, t) => sum + t.amount);
      final expenseTotal = monthExpenses.fold(0.0, (sum, t) => sum + t.amount);

      months['${month.month}/${month.year}'] = {
        'income': incomeTotal,
        'expense': expenseTotal,
        'balance': incomeTotal - expenseTotal,
      };
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tendencias de los Últimos 6 Meses',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...months.entries.map((entry) {
              final data = entry.value;
              final balance = data['balance']!;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        entry.key,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'RD\$${data['income']!.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.end,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'RD\$${data['expense']!.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.end,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'RD\$${balance.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: balance >= 0 ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTopCategoriesCard(
    List<api_models.Transaction> transactions,
    String title,
    Color color,
  ) {
    final categoryData = _getCategoryData(transactions);
    final sortedCategories = categoryData.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topCategories = sortedCategories.take(5).toList();
    final total = categoryData.values.fold(0.0, (sum, value) => sum + value);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  color == Colors.red ? Icons.trending_down : Icons.trending_up,
                  color: color,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Top 5 $title',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  'RD\$${total.toStringAsFixed(0)} total',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...topCategories.asMap().entries.map((entry) {
              final index = entry.key;
              final category = entry.value;
              final percentage = (category.value / total) * 100;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: Text(
                        category.key,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'RD\$${category.value.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                        textAlign: TextAlign.end,
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        '${percentage.toStringAsFixed(0)}%',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // Métodos mejorados para el tab Por Categoría
  Widget _buildCategoryComparisonCard(
    List<api_models.Transaction> incomes,
    List<api_models.Transaction> expenses,
  ) {
    final incomeCategories = _getCategoryData(incomes);
    final expenseCategories = _getCategoryData(expenses);
    final allCategories = {...incomeCategories.keys, ...expenseCategories.keys};

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Comparación de Categorías',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Ingresos vs Gastos por categoría',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ...allCategories.map((category) {
              final income = incomeCategories[category] ?? 0.0;
              final expense = expenseCategories[category] ?? 0.0;
              final net = income - expense;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: net >= 0
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: net >= 0
                          ? Colors.green.withOpacity(0.3)
                          : Colors.red.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildCategoryComparisonItem(
                              'Ingresos',
                              income,
                              Colors.green,
                              Icons.trending_up,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildCategoryComparisonItem(
                              'Gastos',
                              expense,
                              Colors.red,
                              Icons.trending_down,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildCategoryComparisonItem(
                              'Neto',
                              net,
                              net >= 0 ? Colors.green : Colors.red,
                              Icons.account_balance,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryComparisonItem(
    String label,
    double amount,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            'RD\$${amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedCategoryAnalysis(
    List<api_models.Transaction> transactions,
    String title,
    Color color,
  ) {
    final categoryData = _getCategoryData(transactions);
    final sortedCategories = categoryData.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final total = categoryData.values.fold(0.0, (sum, value) => sum + value);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  color == Colors.red ? Icons.trending_down : Icons.trending_up,
                  color: color,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Análisis Detallado de $title',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  '${transactions.length} transacciones',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...sortedCategories.map((entry) {
              final percentage = (entry.value / total) * 100;
              final categoryTransactions = transactions
                  .where((t) => t.category.name == entry.key)
                  .toList();

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              entry.key,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'RD\$${entry.value.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${categoryTransactions.length} transacciones',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                          Text(
                            '${percentage.toStringAsFixed(1)}% del total',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: percentage / 100,
                        backgroundColor: color.withOpacity(0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildMostActiveCategoriesCard(
    List<api_models.Transaction> incomes,
    List<api_models.Transaction> expenses,
  ) {
    final allTransactions = [...incomes, ...expenses];
    final categoryActivity = <String, int>{};

    for (final transaction in allTransactions) {
      final category = transaction.category.name;
      categoryActivity[category] = (categoryActivity[category] ?? 0) + 1;
    }

    final sortedActivity = categoryActivity.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topActive = sortedActivity.take(5).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Categorías Más Activas',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Categorías con más transacciones',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ...topActive.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          '${entry.value}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        entry.key,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      '${entry.value} transacciones',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// Widget para mostrar resumen general
class StatsOverviewCard extends StatelessWidget {
  final String title;
  final double totalIncome;
  final double totalExpenses;
  final double balance;
  final String currencySymbol;
  final String currencyCode;
  final Color primaryColor;

  const StatsOverviewCard({
    super.key,
    required this.title,
    required this.totalIncome,
    required this.totalExpenses,
    required this.balance,
    required this.currencySymbol,
    required this.currencyCode,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Ingresos',
                    totalIncome,
                    Icons.trending_up,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatItem(
                    'Gastos',
                    totalExpenses,
                    Icons.trending_down,
                    Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Balance',
                    balance,
                    Icons.account_balance,
                    balance >= 0 ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatItem(
                    'Moneda',
                    0,
                    Icons.attach_money,
                    primaryColor,
                    isCurrency: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String title,
    double value,
    IconData icon,
    Color color, {
    bool isCurrency = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isCurrency
                ? currencyCode
                : '$currencySymbol${value.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// Widget para mostrar lista de categorías
class CategoryList extends StatelessWidget {
  final Map<String, double> categoryData;
  final String title;
  final String currencySymbol;
  final String currencyCode;
  final Color primaryColor;

  const CategoryList({
    super.key,
    required this.categoryData,
    required this.title,
    required this.currencySymbol,
    required this.currencyCode,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    if (categoryData.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Text(
              'No hay datos disponibles',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ),
        ),
      );
    }

    final sortedCategories = categoryData.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...sortedCategories.map(
              (entry) => _buildCategoryItem(entry.key, entry.value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryItem(String category, double amount) {
    final percentage =
        categoryData.values.fold(0.0, (sum, value) => sum + value) > 0
        ? (amount /
                  categoryData.values.fold(0.0, (sum, value) => sum + value)) *
              100
        : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              category,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '$currencySymbol${amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
              textAlign: TextAlign.end,
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '${percentage.toStringAsFixed(1)}%',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
