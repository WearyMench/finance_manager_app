import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import '../models/account.dart';
import '../models/api_models.dart';
import '../services/api_service.dart';
import '../widgets/dashboard_cards.dart';
import 'transaction_form_screen.dart';
import 'accounts_screen_improved.dart';
import 'account_reports_screen.dart';
import 'transfer_screen.dart';

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
    _loadData();
    // Also load data in TransactionProvider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TransactionProvider>(context, listen: false).loadData();
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load accounts
      final accountsResponse = await _apiService.getAccounts();
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
      _recentTransactions = transactionProvider.transactions.take(5).toList();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar datos: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildErrorState()
          : _buildDashboard(),
    );
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
                          Theme.of(context).primaryColor.withOpacity(0.8),
                        ],
                      ),
                    ),
                  ),
                ),
                actions: [
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
          color: Theme.of(context).dividerColor.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TransferScreen(
          fromAccount: _accounts.first,
          accounts: _accounts,
          onTransferComplete: () => _loadData(),
        ),
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
