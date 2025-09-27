import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import '../models/api_models.dart' as api_models;
import '../theme/app_theme.dart';
import '../widgets/error_message.dart';
import '../widgets/stats_card.dart';
import '../widgets/category_chart.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriod = 'month';
  DateTime _selectedDate = DateTime.now();

  final List<String> _periods = ['week', 'month', 'year'];
  final Map<String, String> _periodLabels = {
    'week': 'Semana',
    'month': 'Mes',
    'year': 'Año',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Map<String, double> _getTransactionsByCategory(
    List<api_models.Transaction> transactions,
  ) {
    final Map<String, double> categoryTotals = {};

    for (final transaction in transactions) {
      final category = transaction.category.name;
      categoryTotals[category] =
          (categoryTotals[category] ?? 0) + transaction.amount;
    }

    return categoryTotals;
  }

  List<api_models.Transaction> _filterTransactionsByPeriod(
    List<api_models.Transaction> transactions,
    String period,
    DateTime date,
  ) {
    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate = now;

    switch (period) {
      case 'week':
        startDate = date.subtract(Duration(days: date.weekday - 1));
        endDate = startDate.add(const Duration(days: 6));
        break;
      case 'month':
        startDate = DateTime(date.year, date.month, 1);
        endDate = DateTime(date.year, date.month + 1, 0);
        break;
      case 'year':
        startDate = DateTime(date.year, 1, 1);
        endDate = DateTime(date.year, 12, 31);
        break;
      default:
        startDate = DateTime(date.year, date.month, 1);
        endDate = DateTime(date.year, date.month + 1, 0);
    }

    return transactions.where((transaction) {
      return transaction.date.isAfter(
            startDate.subtract(const Duration(days: 1)),
          ) &&
          transaction.date.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppTheme.getBackgroundColor(context),
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Estadísticas',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              Text(
                'Análisis de tus finanzas',
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
            Container(
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: PopupMenuButton<String>(
                icon: const Icon(Icons.calendar_today, size: 20),
                onSelected: (value) {
                  setState(() {
                    _selectedPeriod = value;
                  });
                },
                itemBuilder: (context) => _periods.map((period) {
                  return PopupMenuItem(
                    value: period,
                    child: Row(
                      children: [
                        Icon(
                          period == 'week'
                              ? Icons.view_week
                              : period == 'month'
                              ? Icons.calendar_month
                              : Icons.calendar_today,
                          size: 16,
                          color: AppTheme.getPrimaryColor(context),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _periodLabels[period]!,
                          style: TextStyle(
                            color: AppTheme.getTextPrimaryColor(context),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withOpacity(0.7),
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            tabs: const [
              Tab(
                icon: Icon(Icons.dashboard_rounded, size: 20),
                text: 'Resumen',
              ),
              Tab(
                icon: Icon(Icons.trending_down_rounded, size: 20),
                text: 'Gastos',
              ),
              Tab(
                icon: Icon(Icons.trending_up_rounded, size: 20),
                text: 'Ingresos',
              ),
            ],
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.getPrimaryColor(context).withOpacity(0.05),
                Colors.transparent,
              ],
            ),
          ),
          child: TabBarView(
            children: [
              _buildSummaryTab(),
              _buildExpensesTab(),
              _buildIncomesTab(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryTab() {
    return Consumer<TransactionProvider>(
      builder: (context, transactionProvider, child) {
        if (transactionProvider.isLoading) {
          return Center(
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
                  'Cargando estadísticas...',
                  style: TextStyle(
                    color: AppTheme.getTextSecondaryColor(context),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        if (transactionProvider.error != null) {
          return ErrorMessage(
            message: transactionProvider.getErrorMessage(),
            onRetry: () => transactionProvider.loadData(),
          );
        }

        final allTransactions = transactionProvider.transactions;
        final filteredTransactions = _filterTransactionsByPeriod(
          allTransactions,
          _selectedPeriod,
          _selectedDate,
        );

        final expenses = filteredTransactions
            .where((t) => t.type == 'expense')
            .toList();
        final incomes = filteredTransactions
            .where((t) => t.type == 'income')
            .toList();

        final totalExpenses = expenses.fold(0.0, (sum, t) => sum + t.amount);
        final totalIncomes = incomes.fold(0.0, (sum, t) => sum + t.amount);
        final balance = totalIncomes - totalExpenses;

        final expensesByCategory = _getTransactionsByCategory(expenses);
        final incomesByCategory = _getTransactionsByCategory(incomes);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Tarjeta de resumen general
              StatsOverviewCard(
                title: 'Resumen ${_periodLabels[_selectedPeriod]}',
                totalIncome: totalIncomes,
                totalExpenses: totalExpenses,
                balance: balance,
                currencySymbol: 'RD\$',
                currencyCode: 'DOP',
                period: DateFormat('MMMM yyyy').format(_selectedDate),
              ),
              const SizedBox(height: 24),

              // Tarjetas de estadísticas individuales
              Row(
                children: [
                  Expanded(
                    child: StatsCard(
                      title: 'Ingresos',
                      amount: totalIncomes,
                      currencySymbol: 'RD\$',
                      currencyCode: 'DOP',
                      icon: Icons.trending_up_rounded,
                      iconColor: AppTheme.getSuccessColor(context),
                      backgroundColor: AppTheme.getSuccessColor(
                        context,
                      ).withOpacity(0.1),
                      isPositive: true,
                      subtitle: '${incomes.length} transacciones',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: StatsCard(
                      title: 'Gastos',
                      amount: totalExpenses,
                      currencySymbol: 'RD\$',
                      currencyCode: 'DOP',
                      icon: Icons.trending_down_rounded,
                      iconColor: AppTheme.getErrorColor(context),
                      backgroundColor: AppTheme.getErrorColor(
                        context,
                      ).withOpacity(0.1),
                      isPositive: false,
                      subtitle: '${expenses.length} transacciones',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Gráfico de gastos por categoría
              if (expensesByCategory.isNotEmpty)
                CategoryChart(
                  categoryData: expensesByCategory,
                  title: 'Gastos por Categoría',
                  currencySymbol: 'RD\$',
                  currencyCode: 'DOP',
                  primaryColor: AppTheme.getErrorColor(context),
                ),
              const SizedBox(height: 24),

              // Gráfico de ingresos por categoría
              if (incomesByCategory.isNotEmpty)
                CategoryChart(
                  categoryData: incomesByCategory,
                  title: 'Ingresos por Categoría',
                  currencySymbol: 'RD\$',
                  currencyCode: 'DOP',
                  primaryColor: AppTheme.getSuccessColor(context),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExpensesTab() {
    return Consumer<TransactionProvider>(
      builder: (context, transactionProvider, child) {
        if (transactionProvider.isLoading) {
          return Center(
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
                  'Cargando gastos...',
                  style: TextStyle(
                    color: AppTheme.getTextSecondaryColor(context),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        final allTransactions = transactionProvider.transactions;
        final expenses = _filterTransactionsByPeriod(
          allTransactions.where((t) => t.type == 'expense').toList(),
          _selectedPeriod,
          _selectedDate,
        );

        final totalExpenses = expenses.fold(0.0, (sum, t) => sum + t.amount);
        final expensesByCategory = _getTransactionsByCategory(expenses);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              StatsCard(
                title: 'Total Gastado',
                amount: totalExpenses,
                currencySymbol: 'RD\$',
                currencyCode: 'DOP',
                icon: Icons.trending_down_rounded,
                iconColor: AppTheme.getErrorColor(context),
                backgroundColor: AppTheme.getErrorColor(
                  context,
                ).withOpacity(0.1),
                isPositive: false,
                subtitle: '${expenses.length} transacciones',
              ),
              const SizedBox(height: 24),
              CategoryList(
                categoryData: expensesByCategory,
                title: 'Gastos por Categoría',
                currencySymbol: 'RD\$',
                currencyCode: 'DOP',
                primaryColor: AppTheme.getErrorColor(context),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildIncomesTab() {
    return Consumer<TransactionProvider>(
      builder: (context, transactionProvider, child) {
        if (transactionProvider.isLoading) {
          return Center(
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
                  'Cargando ingresos...',
                  style: TextStyle(
                    color: AppTheme.getTextSecondaryColor(context),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        final allTransactions = transactionProvider.transactions;
        final incomes = _filterTransactionsByPeriod(
          allTransactions.where((t) => t.type == 'income').toList(),
          _selectedPeriod,
          _selectedDate,
        );

        final totalIncomes = incomes.fold(0.0, (sum, t) => sum + t.amount);
        final incomesByCategory = _getTransactionsByCategory(incomes);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              StatsCard(
                title: 'Total Ingresado',
                amount: totalIncomes,
                currencySymbol: 'RD\$',
                currencyCode: 'DOP',
                icon: Icons.trending_up_rounded,
                iconColor: AppTheme.getSuccessColor(context),
                backgroundColor: AppTheme.getSuccessColor(
                  context,
                ).withOpacity(0.1),
                isPositive: true,
                subtitle: '${incomes.length} transacciones',
              ),
              const SizedBox(height: 24),
              CategoryList(
                categoryData: incomesByCategory,
                title: 'Ingresos por Categoría',
                currencySymbol: 'RD\$',
                currencyCode: 'DOP',
                primaryColor: AppTheme.getSuccessColor(context),
              ),
            ],
          ),
        );
      },
    );
  }
}
