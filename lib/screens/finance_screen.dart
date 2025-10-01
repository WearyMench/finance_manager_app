import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import '../models/api_models.dart';
import '../widgets/filter_chips.dart';
import 'budgets_screen.dart';
import 'transaction_form_screen.dart';
import 'edit_transaction_screen.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Finanzas'),
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            IconButton(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              tooltip: 'Actualizar',
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withOpacity(0.7),
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            tabs: const [
              Tab(
                icon: Icon(Icons.receipt_long, size: 20),
                text: 'Transacciones',
              ),
              Tab(icon: Icon(Icons.savings, size: 20), text: 'Presupuestos'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [_buildTransactionsTab(), _buildBudgetsTab()],
        ),
        floatingActionButton: _tabController.index == 0
            ? FloatingActionButton(
                heroTag: "add_transaction_fab",
                onPressed: _navigateToAddTransaction,
                child: const Icon(Icons.add),
              )
            : null,
      ),
    );
  }

  Widget _buildTransactionsTab() {
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

        // Usar la pantalla de transacciones existente pero sin AppBar
        return const TransactionsScreenContent();
      },
    );
  }

  Widget _buildBudgetsTab() {
    return const BudgetsScreen();
  }

  void _navigateToAddTransaction() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TransactionFormScreen()),
    ).then((_) {
      // Refresh data when returning
      _loadData();
    });
  }
}

// Widget que contiene solo el contenido de la pantalla de transacciones
class TransactionsScreenContent extends StatelessWidget {
  const TransactionsScreenContent({super.key});

  @override
  Widget build(BuildContext context) {
    // Usar la pantalla de transacciones existente pero sin AppBar
    return const _TransactionsScreenBody();
  }
}

// Widget que contiene solo el body de TransactionsScreen
class _TransactionsScreenBody extends StatefulWidget {
  const _TransactionsScreenBody();

  @override
  State<_TransactionsScreenBody> createState() =>
      _TransactionsScreenBodyState();
}

class _TransactionsScreenBodyState extends State<_TransactionsScreenBody> {
  String? _selectedTypeFilter;
  String? _searchQuery;

  final List<FilterOption> _typeFilters = [
    FilterOption(value: 'all', label: 'Todas'),
    FilterOption(value: 'income', label: 'Ingresos'),
    FilterOption(value: 'expense', label: 'Gastos'),
    FilterOption(value: 'transfer', label: 'Transferencias'),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionProvider>(
      builder: (context, transactionProvider, child) {
        final transactions = _filterTransactions(
          transactionProvider.transactions,
        );

        return Column(
          children: [
            // Search and Filter Bar
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Search Bar
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Buscar transacciones...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery != null
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _searchQuery = null;
                                });
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.isEmpty ? null : value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  // Filter Chips
                  FilterChips(
                    options: _typeFilters,
                    selectedValue: _selectedTypeFilter,
                    onChanged: (value) {
                      setState(() {
                        _selectedTypeFilter = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            // Transactions List
            Expanded(
              child: transactions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No hay transacciones',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Agrega tu primera transacción',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: transactions.length,
                      itemBuilder: (context, index) {
                        final transaction = transactions[index];
                        return _buildTransactionCard(transaction);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  List<Transaction> _filterTransactions(List<Transaction> transactions) {
    var filtered = transactions;

    // Filter by type
    if (_selectedTypeFilter != null && _selectedTypeFilter != 'all') {
      filtered = filtered.where((t) => t.type == _selectedTypeFilter).toList();
    }

    // Filter by search query
    if (_searchQuery != null && _searchQuery!.isNotEmpty) {
      filtered = filtered.where((t) {
        return t.description.toLowerCase().contains(
              _searchQuery!.toLowerCase(),
            ) ||
            t.category.name.toLowerCase().contains(_searchQuery!.toLowerCase());
      }).toList();
    }

    // Sort by date (newest first)
    filtered.sort((a, b) => b.date.compareTo(a.date));

    return filtered;
  }

  Widget _buildTransactionCard(Transaction transaction) {
    final isIncome = transaction.type == 'income';
    final isExpense = transaction.type == 'expense';
    final isTransfer = transaction.type == 'transfer';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _getTransactionColor(transaction.type).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getTransactionIcon(transaction.type),
            color: _getTransactionColor(transaction.type),
            size: 20,
          ),
        ),
        title: Text(
          transaction.description,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(transaction.category.name),
            Text(
              DateFormat('dd/MM/yyyy').format(transaction.date),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isIncome
                      ? '+'
                      : isExpense
                      ? '-'
                      : ''}RD\$${transaction.amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _getTransactionColor(transaction.type),
                  ),
                ),
                if (isTransfer)
                  Text(
                    'Transferencia',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
              ],
            ),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    _navigateToEditTransaction(transaction);
                    break;
                  case 'delete':
                    _showDeleteConfirmation(transaction);
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 18),
                      SizedBox(width: 8),
                      Text('Editar'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Eliminar', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        onTap: () {
          _navigateToEditTransaction(transaction);
        },
      ),
    );
  }

  Color _getTransactionColor(String type) {
    switch (type) {
      case 'income':
        return Colors.green;
      case 'expense':
        return Colors.red;
      case 'transfer':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getTransactionIcon(String type) {
    switch (type) {
      case 'income':
        return Icons.trending_up;
      case 'expense':
        return Icons.trending_down;
      case 'transfer':
        return Icons.swap_horiz;
      default:
        return Icons.receipt;
    }
  }

  void _navigateToEditTransaction(Transaction transaction) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditTransactionScreen(transaction: transaction),
      ),
    ).then((_) {
      // Refresh data when returning
      if (mounted) {
        _loadData();
      }
    });
  }

  void _showDeleteConfirmation(Transaction transaction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Transacción'),
        content: Text(
          '¿Estás seguro de que quieres eliminar la transacción "${transaction.description}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteTransaction(transaction);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTransaction(Transaction transaction) async {
    try {
      final transactionProvider = Provider.of<TransactionProvider>(
        context,
        listen: false,
      );

      final success = await transactionProvider.deleteTransaction(
        transaction.id,
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Transacción "${transaction.description}" eliminada'),
            backgroundColor: Colors.green,
          ),
        );
        _loadData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              transactionProvider.error ?? 'Error al eliminar transacción',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error de conexión: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadData() async {
    final transactionProvider = Provider.of<TransactionProvider>(
      context,
      listen: false,
    );
    await transactionProvider.loadData();
  }
}
