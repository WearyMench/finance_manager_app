import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/database_helper.dart';
import 'package:fl_chart/fl_chart.dart';
import '../utils/app_colors.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage>
    with SingleTickerProviderStateMixin {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  late TabController _tabController;

  // Gastos
  double _totalExpenses = 0.0;
  Map<String, double> _expensesByCategory = {};
  Map<String, double> _expensesByMonth = {};

  // Ingresos
  double _totalIncomes = 0.0;
  Map<String, double> _incomesByCategory = {};
  Map<String, double> _incomesByMonth = {};

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadStats();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Cargar datos de gastos
      final totalExpenses = await _dbHelper.getTotalExpenses();
      final expensesByCategory = await _dbHelper.getExpensesByCategory();
      final expensesByMonth = await _dbHelper.getExpensesByMonth();

      // Cargar datos de ingresos
      final totalIncomes = await _dbHelper.getTotalIncomes();
      final incomesByCategory = await _dbHelper.getIncomesByCategory();
      final incomesByMonth = await _dbHelper.getIncomesByMonth();

      setState(() {
        _totalExpenses = totalExpenses;
        _expensesByCategory = expensesByCategory;
        _expensesByMonth = expensesByMonth;
        _totalIncomes = totalIncomes;
        _incomesByCategory = incomesByCategory;
        _incomesByMonth = incomesByMonth;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar estadísticas: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Estadísticas'),
          elevation: 0,
          backgroundColor: AppColors.getPrimaryColor(context),
          foregroundColor: Colors.white,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Resumen'),
              Tab(text: 'Gastos'),
              Tab(text: 'Ingresos'),
            ],
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.getPrimaryColor(context).withOpacity(0.1),
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
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Tarjeta de resumen general
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: AppColors.getPrimaryGradient(context),
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.getPrimaryColor(context).withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.getWhiteWithOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.analytics,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Resumen del Mes',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        'Ingresos',
                        _totalIncomes,
                        AppColors.getSuccessColor(context),
                        Icons.trending_up,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSummaryCard(
                        'Gastos',
                        _totalExpenses,
                        AppColors.getDangerColor(context),
                        Icons.trending_down,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.getWhiteWithOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.getWhiteWithOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Balance Neto',
                        style: TextStyle(
                          color: AppColors.getWhiteWithOpacity(0.9),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        NumberFormat.currency(
                          locale: 'es_MX',
                          symbol: 'RD\$',
                        ).format(_totalIncomes - _totalExpenses),
                        style: const TextStyle(
                          color: Colors.white,
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
        const SizedBox(height: 24),

        // Gráfico de gastos por categoría
        if (_expensesByCategory.isNotEmpty) ...[
          Container(
            decoration: BoxDecoration(
              color: AppColors.getCardColor(context),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.getBlackWithOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.getDangerColor(
                            context,
                          ).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.pie_chart,
                          color: AppColors.getDangerColor(context),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Gastos por Categoría',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.getTextPrimaryColor(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 200,
                    child: PieChart(
                      PieChartData(
                        sections: _expensesByCategory.entries.map((entry) {
                          return PieChartSectionData(
                            value: entry.value,
                            title:
                                '${entry.key}\n${NumberFormat.currency(locale: 'es_MX', symbol: 'RD\$').format(entry.value)}',
                            color: AppColors.getCategoryColor(entry.key),
                            radius: 60,
                            titleStyle: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          );
                        }).toList(),
                        centerSpaceRadius: 40,
                        sectionsSpace: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],

        // Gráfico de ingresos por categoría
        if (_incomesByCategory.isNotEmpty) ...[
          Container(
            decoration: BoxDecoration(
              color: AppColors.getCardColor(context),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.getBlackWithOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.getSuccessColor(
                            context,
                          ).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.pie_chart,
                          color: AppColors.getSuccessColor(context),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Ingresos por Categoría',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.getTextPrimaryColor(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 200,
                    child: PieChart(
                      PieChartData(
                        sections: _incomesByCategory.entries.map((entry) {
                          return PieChartSectionData(
                            value: entry.value,
                            title:
                                '${entry.key}\n${NumberFormat.currency(locale: 'es_MX', symbol: 'RD\$').format(entry.value)}',
                            color: AppColors.getCategoryColor(entry.key),
                            radius: 60,
                            titleStyle: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          );
                        }).toList(),
                        centerSpaceRadius: 40,
                        sectionsSpace: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSummaryCard(
    String title,
    double amount,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            NumberFormat.currency(locale: 'es_MX', symbol: '\$').format(amount),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpensesTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildTotalCard(
          _totalExpenses,
          'Total Gastado',
          Colors.red,
          Icons.money_off,
        ),
        const SizedBox(height: 24),
        _buildCategoryStats(
          _expensesByCategory,
          _totalExpenses,
          'Gastos por Categoría',
          Colors.red,
        ),
      ],
    );
  }

  Widget _buildIncomesTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildTotalCard(
          _totalIncomes,
          'Total Ingresado',
          Colors.green,
          Icons.attach_money,
        ),
        const SizedBox(height: 24),
        _buildCategoryStats(
          _incomesByCategory,
          _totalIncomes,
          'Ingresos por Categoría',
          Colors.green,
        ),
      ],
    );
  }

  Widget _buildTotalCard(
    double total,
    String title,
    MaterialColor color,
    IconData icon,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [color[600]!, color[800]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 48),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              NumberFormat.currency(
                locale: 'es_MX',
                symbol: '\$',
              ).format(total),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryStats(
    Map<String, double> categoryData,
    double total,
    String title,
    Color color,
  ) {
    if (categoryData.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(
                Icons.pie_chart,
                size: 48,
                color: AppColors.getTextSecondaryColor(context),
              ),
              const SizedBox(height: 16),
              Text(
                'No hay datos para mostrar',
                style: TextStyle(
                  color: AppColors.getTextSecondaryColor(context),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Pie chart
    final List<PieChartSectionData> sections = [];
    final totalValue = total > 0 ? total : 1.0;
    int colorIndex = 0;
    final List<Color> pieColors = AppColors.getChartColors();

    categoryData.forEach((category, amount) {
      final percent = amount / totalValue * 100;
      sections.add(
        PieChartSectionData(
          color: pieColors[colorIndex % pieColors.length],
          value: amount,
          title: '${percent.toStringAsFixed(1)}%',
          radius: 60,
          titleStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
      colorIndex++;
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.getTextPrimaryColor(context),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: SizedBox(
            height: 180,
            child: Card(
              color: Theme.of(context).colorScheme.surface,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(90),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: PieChart(
                  PieChartData(
                    sections: sections,
                    centerSpaceRadius: 32,
                    sectionsSpace: 2,
                    borderData: FlBorderData(show: false),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...categoryData.entries.map((entry) {
          final category = entry.key;
          final amount = entry.value;
          final percentage = total > 0
              ? (amount / total * 100).toStringAsFixed(1)
              : '0.0';

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
                backgroundColor: AppColors.getCategoryColor(category),
                child: Icon(_getCategoryIcon(category), color: Colors.white),
              ),
              title: Text(
                category,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    '$percentage% del total',
                    style: TextStyle(
                      color: AppColors.getTextSecondaryColor(context),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    NumberFormat.currency(
                      locale: 'es_MX',
                      symbol: 'RD\$',
                    ).format(amount),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
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
      case 'sueldo':
        return Icons.work;
      case 'venta':
        return Icons.shopping_cart;
      case 'regalo':
        return Icons.card_giftcard;
      default:
        return Icons.category;
    }
  }
}
