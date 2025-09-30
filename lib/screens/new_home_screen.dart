import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import '../models/account.dart';
import '../models/api_models.dart';
import '../services/api_service.dart';
import '../widgets/dashboard_cards.dart';
import '../widgets/budget_alert_widget.dart';
import '../widgets/session_status_widget.dart';
import 'transaction_form_screen.dart';
import 'accounts_screen_improved.dart';
import 'account_reports_screen.dart';
import 'transfer_screen.dart';
import 'budgets_screen.dart';

class NewHomeScreen extends StatefulWidget {
  const NewHomeScreen({super.key});

  @override
  State<NewHomeScreen> createState() => _NewHomeScreenState();
}

class _NewHomeScreenState extends State<NewHomeScreen> {
  final ApiService _apiService = ApiService();
  List<Account> _accounts = [];
  List<Transaction> _recentTransactions = [];
  bool _isLoading = true;
  String? _error;

  // Filter states (for future use)
  // String? _selectedTypeFilter;
  // String? _searchQuery;
  // DateTime? _startDate;
  // DateTime? _endDate;

  @override
  void initState() {
    super.initState();

    // Cargar datos de forma asíncrona para evitar problemas de desmontaje
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadData();
        // Also load data in TransactionProvider
        Provider.of<TransactionProvider>(context, listen: false).loadData();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  Future<void> _loadData() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load accounts
      final accountsResponse = await _apiService.getAccounts();

      if (!mounted) {
        return;
      }

      if (accountsResponse.success && accountsResponse.data != null) {
        _accounts = (accountsResponse.data as List)
            .map((item) => Account.fromMap(item))
            .toList();
      }

      // Load recent transactions from TransactionProvider
      final transactionProvider = Provider.of<TransactionProvider>(
        context,
        listen: false,
      );

      await transactionProvider.loadData(forceReload: true);

      if (!mounted) {
        return;
      }

      _recentTransactions = transactionProvider.transactions.take(5).toList();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error al cargar datos: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget bodyWidget;
    if (_isLoading) {
      bodyWidget = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      bodyWidget = _buildErrorState();
    } else {
      bodyWidget = _buildDashboard();
    }

    return Scaffold(body: bodyWidget);
  }

  Widget _buildErrorState() {
    return Center(
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
          ElevatedButton(onPressed: _loadData, child: const Text('Reintentar')),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    return Consumer<TransactionProvider>(
      builder: (context, transactionProvider, child) {
        final totalBalance = _accounts.fold(
          0.0,
          (sum, account) => sum + account.balance,
        );
        final monthlyIncome = transactionProvider.totalIncome;
        final monthlyExpenses = transactionProvider.totalExpenses;

        return RefreshIndicator(
          onRefresh: _loadData,
          child: CustomScrollView(
            slivers: [
              // App Bar
              SliverAppBar(
                expandedHeight: 100,
                floating: true,
                pinned: true,
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                flexibleSpace: FlexibleSpaceBar(
                  title: const Text('Mi Finanzas'),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Theme.of(context).primaryColor,
                          Theme.of(context).primaryColor.withValues(alpha: 0.8),
                        ],
                      ),
                    ),
                  ),
                ),
                actions: [
                  const SessionStatusWidget(),
                  IconButton(
                    onPressed: _loadData,
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),

              // Balance Card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: BalanceCard(
                    totalBalance: totalBalance,
                    monthlyIncome: monthlyIncome,
                    monthlyExpenses: monthlyExpenses,
                    onTap: () => _navigateToReports(),
                  ),
                ),
              ),

              // Quick Actions
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Acciones Rápidas',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: QuickActionCard(
                              icon: Icons.add,
                              title: 'Agregar',
                              subtitle: 'Transacción',
                              color: Colors.green,
                              onTap: () => _navigateToAddTransaction(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: QuickActionCard(
                              icon: Icons.swap_horiz,
                              title: 'Transferir',
                              subtitle: 'Dinero',
                              color: Colors.blue,
                              onTap: () => _navigateToTransfer(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: QuickActionCard(
                              icon: Icons.account_balance_wallet,
                              title: 'Cuentas',
                              subtitle: 'Gestionar',
                              color: Colors.orange,
                              onTap: () => _navigateToAccounts(),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Budget Alerts
              SliverToBoxAdapter(
                child: BudgetAlertWidget(
                  budgets: transactionProvider.budgets,
                  onViewBudgets: () => _navigateToBudgets(),
                ),
              ),

              // Accounts Summary
              if (_accounts.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Mis Cuentas',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextButton(
                              onPressed: () => _navigateToAccounts(),
                              child: const Text('Ver todas'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ..._accounts
                            .take(3)
                            .map(
                              (account) => AccountSummaryCard(
                                accountName: account.name,
                                balance: account.balance,
                                accountType: account.type,
                                icon: _getTypeIcon(account.type),
                                color: _getTypeColor(account.type),
                                onTap: () => _navigateToAccountDetails(account),
                              ),
                            ),
                      ],
                    ),
                  ),
                ),
              ],

              // Recent Transactions
              if (_recentTransactions.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Transacciones Recientes',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextButton(
                              onPressed: () => _navigateToTransactions(),
                              child: const Text('Ver todas'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final transaction = _recentTransactions[index];
                    return _buildTransactionItem(transaction);
                  }, childCount: _recentTransactions.length),
                ),
              ],

              // Empty state
              if (_accounts.isEmpty && _recentTransactions.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(
                          Icons.account_balance_wallet_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '¡Bienvenido!',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Comienza agregando una cuenta o tu primera transacción',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => _navigateToAddTransaction(),
                          icon: const Icon(Icons.add),
                          label: const Text('Agregar Transacción'),
                        ),
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

  Widget _buildTransactionItem(Transaction transaction) {
    final isIncome = transaction.type == 'income';
    final color = isIncome ? Colors.green : Colors.red;
    final icon = isIncome ? Icons.trending_up : Icons.trending_down;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('dd/MM/yyyy').format(transaction.date),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Text(
            '${isIncome ? '+' : '-'}${NumberFormat.currency(symbol: '\$').format(transaction.amount)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // Navigation methods
  void _navigateToAddTransaction() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TransactionFormScreen()),
    );
  }

  void _navigateToTransfer() {
    if (_accounts.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Necesitas al menos 2 cuentas para transferir'),
        ),
      );
      return;
    }

    // Mostrar diálogo para seleccionar cuenta origen
    _showAccountSelectionDialog();
  }

  void _showAccountSelectionDialog() {
    // Filtrar cuentas que permiten transferencias (excluir tarjetas de crédito)
    final transferableAccounts = _accounts
        .where((account) => account.type != 'credit')
        .toList();

    if (transferableAccounts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No tienes cuentas disponibles para transferir (excluyendo tarjetas de crédito)',
          ),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seleccionar Cuenta Origen'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: transferableAccounts.map((account) {
            return ListTile(
              leading: Icon(
                account.typeIcon,
                color: Theme.of(context).primaryColor,
              ),
              title: Text(account.name),
              subtitle: Text(
                '${account.typeDisplay} • ${account.formattedBalance}',
              ),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TransferScreen(
                      fromAccount: account,
                      accounts: _accounts,
                      onTransferComplete: () => _loadData(),
                    ),
                  ),
                );
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  void _navigateToAccounts() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AccountsScreenImproved()),
    );
  }

  void _navigateToAccountDetails(Account account) {
    // TODO: Implement account details screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Detalles de ${account.name} - Próximamente'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _navigateToTransactions() {
    // Navigate to transactions list - using bottom navigation
    // This is handled by the main screen navigation
  }

  void _navigateToReports() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AccountReportsScreen()),
    );
  }

  void _navigateToBudgets() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const BudgetsScreen()),
    );
  }

  // Helper methods
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
}
