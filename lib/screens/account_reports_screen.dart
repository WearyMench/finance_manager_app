import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../providers/transaction_provider.dart';
import 'account_analysis_screen.dart';

class AccountReportsScreen extends StatefulWidget {
  const AccountReportsScreen({super.key});

  @override
  State<AccountReportsScreen> createState() => _AccountReportsScreenState();
}

class _AccountReportsScreenState extends State<AccountReportsScreen> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _balanceSummary;
  Map<String, dynamic>? _cashFlow;
  Map<String, dynamic>? _balanceProjection;
  bool _isLoading = true;
  String? _error;
  final int _selectedTab = 0;
  String _selectedPeriod = '30'; // 7, 30, 90, 365

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load balance summary
      final summaryResponse = await _apiService.getBalanceSummary();
      if (summaryResponse.success && summaryResponse.data != null) {
        _balanceSummary = summaryResponse.data as Map<String, dynamic>;
      }

      // Load cash flow
      final cashFlowResponse = await _apiService.getCashFlow();
      if (cashFlowResponse.success && cashFlowResponse.data != null) {
        _cashFlow = cashFlowResponse.data as Map<String, dynamic>;
      }

      // Load balance projection
      final projectionResponse = await _apiService.getBalanceProjection();
      if (projectionResponse.success && projectionResponse.data != null) {
        _balanceProjection = projectionResponse.data as Map<String, dynamic>;
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar reportes: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes Financieros'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _selectedPeriod = value;
              });
              _loadData();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: '7', child: Text('Últimos 7 días')),
              const PopupMenuItem(value: '30', child: Text('Últimos 30 días')),
              const PopupMenuItem(value: '90', child: Text('Últimos 90 días')),
              const PopupMenuItem(value: '365', child: Text('Último año')),
            ],
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_getPeriodText(_selectedPeriod)),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
          IconButton(onPressed: _loadData, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadData,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            )
          : DefaultTabController(
              length: 4,
              initialIndex: _selectedTab,
              child: Column(
                children: [
                  Container(
                    color: Theme.of(context).primaryColor,
                    child: const TabBar(
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white70,
                      indicatorColor: Colors.white,
                      isScrollable: true,
                      tabs: [
                        Tab(text: 'Resumen', icon: Icon(Icons.dashboard)),
                        Tab(
                          text: 'Transacciones',
                          icon: Icon(Icons.receipt_long),
                        ),
                        Tab(text: 'Flujo', icon: Icon(Icons.trending_up)),
                        Tab(text: 'Proyección', icon: Icon(Icons.timeline)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildBalanceSummary(),
                        _buildTransactionAnalysis(),
                        _buildCashFlow(),
                        _buildBalanceProjection(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildBalanceSummary() {
    if (_balanceSummary == null) {
      return const Center(child: Text('No hay datos disponibles'));
    }

    final totalBalance = _balanceSummary!['totalBalance'] ?? 0.0;
    final totalCreditLimit = _balanceSummary!['totalCreditLimit'] ?? 0.0;
    final availableCredit = _balanceSummary!['availableCredit'] ?? 0.0;
    final totalAccounts = _balanceSummary!['totalAccounts'] ?? 0;
    final accountsByType =
        _balanceSummary!['accountsByType'] as Map<String, dynamic>? ?? {};

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary cards
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Balance Total',
                NumberFormat.currency(symbol: '\$').format(totalBalance),
                Icons.account_balance_wallet,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'Límite de Crédito',
                NumberFormat.currency(symbol: '\$').format(totalCreditLimit),
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
              child: _buildSummaryCard(
                'Crédito Disponible',
                NumberFormat.currency(symbol: '\$').format(availableCredit),
                Icons.check_circle,
                Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'Total Cuentas',
                totalAccounts.toString(),
                Icons.account_balance,
                Colors.purple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Accounts by type
        Text(
          'Cuentas por Tipo',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ...accountsByType.entries.map((entry) {
          final type = entry.key;
          final data = entry.value as Map<String, dynamic>;
          final count = data['count'] ?? 0;
          final totalBalance = data['totalBalance'] ?? 0.0;
          final accounts = data['accounts'] as List<dynamic>? ?? [];

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ExpansionTile(
              title: Text(
                _getTypeDisplayName(type),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                '$count cuenta${count != 1 ? 's' : ''} - ${NumberFormat.currency(symbol: '\$').format(totalBalance)}',
              ),
              leading: Icon(_getTypeIcon(type), color: _getTypeColor(type)),
              children: accounts.map<Widget>((account) {
                final accountData = account as Map<String, dynamic>;
                return ListTile(
                  title: Text(accountData['name'] ?? ''),
                  subtitle: Text(
                    NumberFormat.currency(
                      symbol: '\$',
                    ).format(accountData['balance'] ?? 0.0),
                  ),
                  trailing: accountData['creditLimit'] != null
                      ? Text(
                          'Límite: ${NumberFormat.currency(symbol: '\$').format(accountData['creditLimit'])}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        )
                      : null,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AccountAnalysisScreen(
                          accountId: accountData['id'],
                          accountName: accountData['name'],
                        ),
                      ),
                    );
                  },
                );
              }).toList(),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildTransactionAnalysis() {
    return Consumer<TransactionProvider>(
      builder: (context, transactionProvider, child) {
        final transactions = transactionProvider.transactions;

        if (transactions.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No hay transacciones para analizar'),
              ],
            ),
          );
        }

        // Filtrar transacciones por período
        final now = DateTime.now();
        final days = int.parse(_selectedPeriod);
        final startDate = now.subtract(Duration(days: days));
        final periodTransactions = transactions
            .where(
              (t) =>
                  t.date.isAfter(startDate) &&
                  t.date.isBefore(now.add(const Duration(days: 1))),
            )
            .toList();

        // Calcular estadísticas
        final income = periodTransactions
            .where((t) => t.type == 'income')
            .fold(0.0, (sum, t) => sum + t.amount);
        final expenses = periodTransactions
            .where((t) => t.type == 'expense')
            .fold(0.0, (sum, t) => sum + t.amount);
        final netBalance = income - expenses;

        // Top categorías de gastos
        final expenseByCategory = <String, double>{};
        for (final transaction in periodTransactions.where(
          (t) => t.type == 'expense',
        )) {
          final categoryName = transaction.category.name;
          expenseByCategory[categoryName] =
              (expenseByCategory[categoryName] ?? 0) + transaction.amount;
        }
        final topExpenseCategories = expenseByCategory.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        // Top categorías de ingresos
        final incomeByCategory = <String, double>{};
        for (final transaction in periodTransactions.where(
          (t) => t.type == 'income',
        )) {
          final categoryName = transaction.category.name;
          incomeByCategory[categoryName] =
              (incomeByCategory[categoryName] ?? 0) + transaction.amount;
        }
        final topIncomeCategories = incomeByCategory.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Resumen de período
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.analytics,
                          size: 32,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Análisis de ${_getPeriodText(_selectedPeriod)}',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Ingresos',
                            NumberFormat.currency(symbol: '\$').format(income),
                            Icons.trending_up,
                            Colors.green,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Gastos',
                            NumberFormat.currency(
                              symbol: '\$',
                            ).format(expenses),
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
                          child: _buildStatCard(
                            'Balance Neto',
                            NumberFormat.currency(
                              symbol: '\$',
                            ).format(netBalance),
                            netBalance >= 0
                                ? Icons.trending_up
                                : Icons.trending_down,
                            netBalance >= 0 ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Top categorías de gastos
            if (topExpenseCategories.isNotEmpty) ...[
              _buildCategorySection(
                'Top Categorías de Gastos',
                Icons.shopping_cart,
                Colors.red,
                topExpenseCategories,
              ),
              const SizedBox(height: 16),
            ],

            // Top categorías de ingresos
            if (topIncomeCategories.isNotEmpty) ...[
              _buildCategorySection(
                'Top Categorías de Ingresos',
                Icons.attach_money,
                Colors.green,
                topIncomeCategories,
              ),
              const SizedBox(height: 16),
            ],

            // Resumen de transacciones
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Resumen de Transacciones',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMiniStatCard(
                            'Total Transacciones',
                            periodTransactions.length.toString(),
                            Icons.receipt,
                            Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMiniStatCard(
                            'Promedio Diario',
                            NumberFormat.currency(
                              symbol: '\$',
                            ).format(expenses / days),
                            Icons.calendar_today,
                            Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCategorySection(
    String title,
    IconData icon,
    Color color,
    List<MapEntry<String, double>> categories,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...categories.take(5).map((entry) {
              final percentage = categories.isNotEmpty
                  ? (entry.value / categories.first.value * 100)
                  : 0.0;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        entry.key,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: LinearProgressIndicator(
                        value: percentage / 100,
                        backgroundColor: color.withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      NumberFormat.currency(symbol: '\$').format(entry.value),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 14,
            ),
          ),
          Text(
            title,
            style: TextStyle(fontSize: 10, color: color),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCashFlow() {
    if (_cashFlow == null) {
      return const Center(child: Text('No hay datos disponibles'));
    }

    final flows = _cashFlow!['flows'] as List<dynamic>? ?? [];
    final totalTransfers = _cashFlow!['totalTransfers'] ?? 0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Icon(
                  Icons.swap_horiz,
                  size: 48,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(height: 8),
                Text(
                  'Total de Transferencias',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  totalTransfers.toString(),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (flows.isEmpty)
          const Center(child: Text('No hay transferencias registradas'))
        else
          ...flows.map((flow) {
            final flowData = flow as Map<String, dynamic>;
            final fromAccount = flowData['fromAccount'] as Map<String, dynamic>;
            final toAccount = flowData['toAccount'] as Map<String, dynamic>;
            final totalAmount = flowData['totalAmount'] ?? 0.0;
            final transferCount = flowData['transferCount'] ?? 0;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(
                    context,
                  ).primaryColor.withValues(alpha: 0.1),
                  child: Icon(
                    Icons.swap_horiz,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                title: Text(
                  '${fromAccount['name']} → ${toAccount['name']}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  '$transferCount transferencia${transferCount != 1 ? 's' : ''}',
                ),
                trailing: Text(
                  NumberFormat.currency(symbol: '\$').format(totalAmount),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            );
          }).toList(),
      ],
    );
  }

  Widget _buildBalanceProjection() {
    if (_balanceProjection == null) {
      return const Center(child: Text('No hay datos disponibles'));
    }

    final projections =
        _balanceProjection!['projections'] as List<dynamic>? ?? [];
    final period = _balanceProjection!['period'] as Map<String, dynamic>? ?? {};

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Icon(
                  Icons.timeline,
                  size: 48,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(height: 8),
                Text(
                  'Proyección de ${period['months'] ?? 6} meses',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  'Basado en ${period['basedOnMonths'] ?? 0} meses de datos',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...projections.map((projection) {
          final projectionData = projection as Map<String, dynamic>;
          final account = projectionData['account'] as Map<String, dynamic>;
          final monthlyProjection =
              projectionData['monthlyProjection'] as List<dynamic>? ?? [];
          final totalProjectedBalance =
              projectionData['totalProjectedBalance'] ?? 0.0;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ExpansionTile(
              title: Text(
                account['name'] ?? '',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                'Proyección: ${NumberFormat.currency(symbol: '\$').format(totalProjectedBalance)}',
              ),
              leading: Icon(
                _getTypeIcon(account['type'] ?? ''),
                color: _getTypeColor(account['type'] ?? ''),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        'Proyección Mensual',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      ...monthlyProjection.map((month) {
                        final monthData = month as Map<String, dynamic>;
                        final monthNumber = monthData['month'] ?? 0;
                        final projectedBalance =
                            monthData['projectedBalance'] ?? 0.0;
                        final netChange = monthData['netChange'] ?? 0.0;

                        return ListTile(
                          title: Text('Mes $monthNumber'),
                          subtitle: Text(
                            NumberFormat.currency(
                              symbol: '\$',
                            ).format(projectedBalance),
                          ),
                          trailing: Text(
                            '${netChange >= 0 ? '+' : ''}${NumberFormat.currency(symbol: '\$').format(netChange)}',
                            style: TextStyle(
                              color: netChange >= 0 ? Colors.green : Colors.red,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _getTypeDisplayName(String type) {
    switch (type) {
      case 'cash':
        return 'Efectivo';
      case 'bank':
        return 'Banco';
      case 'credit':
        return 'Crédito';
      case 'savings':
        return 'Ahorros';
      case 'investment':
        return 'Inversión';
      default:
        return type;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'cash':
        return Icons.account_balance_wallet;
      case 'bank':
        return Icons.account_balance;
      case 'credit':
        return Icons.credit_card;
      case 'savings':
        return Icons.savings;
      case 'investment':
        return Icons.trending_up;
      default:
        return Icons.account_balance;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'cash':
        return Colors.green;
      case 'bank':
        return Colors.blue;
      case 'credit':
        return Colors.orange;
      case 'savings':
        return Colors.purple;
      case 'investment':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  String _getPeriodText(String period) {
    switch (period) {
      case '7':
        return '7 días';
      case '30':
        return '30 días';
      case '90':
        return '90 días';
      case '365':
        return '1 año';
      default:
        return '30 días';
    }
  }
}
