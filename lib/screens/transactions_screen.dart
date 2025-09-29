import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import '../models/api_models.dart';
import '../widgets/filter_chips.dart';
import 'transaction_form_screen.dart';
import 'edit_transaction_screen.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  String? _selectedTypeFilter;
  String? _searchQuery;
  DateTime? _startDate;
  DateTime? _endDate;
  String? _errorMessage;
  String? _successMessage;

  final List<FilterOption> _typeFilters = [
    FilterOption(value: 'all', label: 'Todas'),
    FilterOption(value: 'income', label: 'Ingresos'),
    FilterOption(value: 'expense', label: 'Gastos'),
    FilterOption(value: 'transfer', label: 'Transferencias'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transacciones'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _showFilterDialog,
            icon: const Icon(Icons.filter_list),
          ),
        ],
      ),
      body: Consumer<TransactionProvider>(
        builder: (context, transactionProvider, child) {
          final transactions = _filterTransactions(
            transactionProvider.transactions,
          );

          return Column(
            children: [
              // Search and Quick Filters
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    SearchFilter(
                      query: _searchQuery,
                      onChanged: (query) {
                        setState(() {
                          _searchQuery = query;
                        });
                      },
                      hintText: 'Buscar transacciones...',
                    ),
                    const SizedBox(height: 12),
                    FilterChips(
                      options: _typeFilters,
                      selectedValue: _selectedTypeFilter,
                      onChanged: (value) {
                        setState(() {
                          _selectedTypeFilter = value;
                        });
                      },
                    ),
                    if (_startDate != null || _endDate != null) ...[
                      const SizedBox(height: 12),
                      DateRangeFilter(
                        startDate: _startDate,
                        endDate: _endDate,
                        onChanged: (start, end) {
                          setState(() {
                            _startDate = start;
                            _endDate = end;
                          });
                        },
                      ),
                    ],
                  ],
                ),
              ),

              // Error and Success Messages
              if (_errorMessage != null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    border: Border.all(color: Colors.red[200] ?? Colors.red),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red[600],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red[600]),
                        ),
                      ),
                      IconButton(
                        onPressed: () => setState(() => _errorMessage = null),
                        icon: Icon(
                          Icons.close,
                          color: Colors.red[600],
                          size: 16,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 24,
                          minHeight: 24,
                        ),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),

              if (_successMessage != null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    border: Border.all(
                      color: Colors.green[200] ?? Colors.green,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        color: Colors.green[600],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _successMessage!,
                          style: TextStyle(color: Colors.green[600]),
                        ),
                      ),
                      IconButton(
                        onPressed: () => setState(() => _successMessage = null),
                        icon: Icon(
                          Icons.close,
                          color: Colors.green[600],
                          size: 16,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 24,
                          minHeight: 24,
                        ),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),

              // Transactions List
              Expanded(
                child: transactions.isEmpty
                    ? _buildEmptyState()
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
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "transactions_fab",
        onPressed: () => _navigateToAddTransaction(),
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No hay transacciones',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Agrega tu primera transacción',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _navigateToAddTransaction(),
            icon: const Icon(Icons.add),
            label: const Text('Agregar Transacción'),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(Transaction transaction) {
    final isIncome = transaction.type == 'income';
    final isTransfer = transaction.transferType == 'transfer';
    final color = isIncome
        ? Colors.green
        : (isTransfer ? Colors.blue : Colors.red);
    final icon = isIncome
        ? Icons.trending_up
        : (isTransfer ? Icons.swap_horiz : Icons.trending_down);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _navigateToEditTransaction(transaction),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icono y tipo
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 12),

                // Información de la transacción
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
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat(
                          'dd/MM/yyyy • HH:mm',
                        ).format(transaction.date),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      Builder(
                        builder: (context) {
                          final category = transaction.category;
                          if (category == null) return const SizedBox.shrink();
                          return Column(
                            children: [
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Color(
                                    int.parse(
                                      category.color.replaceFirst('#', '0xFF'),
                                    ),
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  category.name,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Color(
                                      int.parse(
                                        category.color.replaceFirst(
                                          '#',
                                          '0xFF',
                                        ),
                                      ),
                                    ),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // Monto y botones de acción
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${isIncome ? '+' : '-'}${NumberFormat.currency(symbol: '\$').format(transaction.amount)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    Text(
                      _getTypeLabel(transaction.type, transaction.transferType),
                      style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () =>
                              _navigateToEditTransaction(transaction),
                          icon: Icon(
                            Icons.edit_outlined,
                            color: Theme.of(context).primaryColor,
                            size: 18,
                          ),
                          tooltip: 'Editar',
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          padding: EdgeInsets.zero,
                        ),
                        IconButton(
                          onPressed: () => _deleteTransaction(transaction.id),
                          icon: Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                            size: 18,
                          ),
                          tooltip: 'Eliminar',
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          padding: EdgeInsets.zero,
                        ),
                      ],
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

  List<Transaction> _filterTransactions(List<Transaction> transactions) {
    var filtered = transactions;

    // Filter by type
    if (_selectedTypeFilter != null && _selectedTypeFilter != 'all') {
      if (_selectedTypeFilter == 'transfer') {
        filtered = filtered.where((t) => t.transferType == 'transfer').toList();
      } else {
        filtered = filtered
            .where((t) => t.type == _selectedTypeFilter)
            .toList();
      }
    }

    // Filter by search query
    if (_searchQuery != null && _searchQuery!.isNotEmpty) {
      final query = _searchQuery!.toLowerCase();
      filtered = filtered.where((t) {
        final category = t.category;
        return t.description.toLowerCase().contains(query) ||
            (category != null && category.name.toLowerCase().contains(query));
      }).toList();
    }

    // Filter by date range
    if (_startDate != null) {
      filtered = filtered
          .where(
            (t) =>
                t.date.isAfter(_startDate!) ||
                t.date.isAtSameMomentAs(_startDate!),
          )
          .toList();
    }
    if (_endDate != null) {
      filtered = filtered
          .where((t) => t.date.isBefore(_endDate!.add(const Duration(days: 1))))
          .toList();
    }

    // Sort by date (newest first)
    filtered.sort((a, b) => b.date.compareTo(a.date));

    return filtered;
  }

  String _getTypeLabel(String type, String? transferType) {
    if (transferType == 'transfer') return 'Transferencia';
    switch (type) {
      case 'income':
        return 'Ingreso';
      case 'expense':
        return 'Gasto';
      default:
        return type;
    }
  }

  void _navigateToAddTransaction() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TransactionFormScreen()),
    );
  }

  void _navigateToEditTransaction(Transaction transaction) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditTransactionScreen(transaction: transaction),
      ),
    );
  }

  Future<void> _deleteTransaction(String transactionId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Transacción'),
        content: const Text(
          '¿Estás seguro de que quieres eliminar esta transacción? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _errorMessage = null;
        _successMessage = null;
      });

      try {
        final transactionProvider = Provider.of<TransactionProvider>(
          context,
          listen: false,
        );

        final success = await transactionProvider.deleteTransaction(
          transactionId,
        );

        if (success) {
          setState(() {
            _successMessage = 'Transacción eliminada correctamente';
          });

          // Clear success message after 3 seconds
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) {
              setState(() {
                _successMessage = null;
              });
            }
          });
        } else {
          setState(() {
            _errorMessage =
                transactionProvider.error ?? 'Error al eliminar la transacción';
          });
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'Error al eliminar la transacción: $e';
        });
      }
    }
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filtros',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text('Tipo de transacción'),
            const SizedBox(height: 8),
            FilterChips(
              options: _typeFilters,
              selectedValue: _selectedTypeFilter,
              onChanged: (value) {
                setState(() {
                  _selectedTypeFilter = value;
                });
              },
            ),
            const SizedBox(height: 20),
            const Text('Rango de fechas'),
            const SizedBox(height: 8),
            DateRangeFilter(
              startDate: _startDate,
              endDate: _endDate,
              onChanged: (start, end) {
                setState(() {
                  _startDate = start;
                  _endDate = end;
                });
              },
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _selectedTypeFilter = null;
                        _startDate = null;
                        _endDate = null;
                      });
                      Navigator.pop(context);
                    },
                    child: const Text('Limpiar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Aplicar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
