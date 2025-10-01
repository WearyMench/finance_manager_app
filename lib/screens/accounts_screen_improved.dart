import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/account.dart';
import '../services/api_service.dart';
import '../providers/transaction_provider.dart';
import 'account_form_screen.dart';
import 'transfer_screen.dart';
import 'account_details_screen.dart';

class AccountsScreenImproved extends StatefulWidget {
  const AccountsScreenImproved({super.key});

  @override
  State<AccountsScreenImproved> createState() => _AccountsScreenImprovedState();
}

class _AccountsScreenImprovedState extends State<AccountsScreenImproved> {
  final ApiService _apiService = ApiService();
  List<Account> _accounts = [];
  List<Account> _filteredAccounts = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  String _selectedFilter = 'all';
  String _sortBy = 'name';
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    _loadAccounts();

    // Configurar callback para recargar cuentas cuando cambien las transacciones
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final transactionProvider = Provider.of<TransactionProvider>(
        context,
        listen: false,
      );
      transactionProvider.setAccountDataChangedCallback(() {
        if (mounted) {
          _loadAccounts();
        }
      });
    });
  }

  Future<void> _loadAccounts() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _apiService.getAccounts();
      if (!mounted) return;

      if (response.success && response.data != null) {
        setState(() {
          _accounts = (response.data as List)
              .map((item) => Account.fromMap(item))
              .toList();
          _isLoading = false;
        });
        _applyFilters();
      } else {
        setState(() {
          _error = response.message ?? 'Error al cargar cuentas';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = 'Error de conexión: $e';
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    List<Account> filtered = List.from(_accounts);

    // Aplicar filtro de búsqueda
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (account) =>
                account.name.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                account.typeDisplay.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ),
          )
          .toList();
    }

    // Aplicar filtro de tipo
    if (_selectedFilter != 'all') {
      filtered = filtered
          .where((account) => account.type == _selectedFilter)
          .toList();
    }

    // Aplicar ordenamiento
    filtered.sort((a, b) {
      int comparison = 0;
      switch (_sortBy) {
        case 'name':
          comparison = a.name.compareTo(b.name);
          break;
        case 'balance':
          comparison = a.balance.compareTo(b.balance);
          break;
        case 'type':
          comparison = a.type.compareTo(b.type);
          break;
        case 'created':
          comparison = a.createdAt.compareTo(b.createdAt);
          break;
      }
      return _sortAscending ? comparison : -comparison;
    });

    setState(() {
      _filteredAccounts = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Cuentas'),
        actions: [
          IconButton(
            onPressed: _loadAccounts,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Column(
            children: [
              // Barra de búsqueda
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                    _applyFilters();
                  },
                  decoration: InputDecoration(
                    hintText: 'Buscar cuentas...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              setState(() {
                                _searchQuery = '';
                              });
                              _applyFilters();
                            },
                            icon: const Icon(Icons.clear),
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                  ),
                ),
              ),
              // Filtros y ordenamiento
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    // Filtro por tipo
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedFilter,
                        decoration: InputDecoration(
                          labelText: 'Tipo',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('Todos')),
                          DropdownMenuItem(
                            value: 'cash',
                            child: Text('Efectivo'),
                          ),
                          DropdownMenuItem(value: 'bank', child: Text('Banco')),
                          DropdownMenuItem(
                            value: 'credit',
                            child: Text('Crédito'),
                          ),
                          DropdownMenuItem(
                            value: 'savings',
                            child: Text('Ahorros'),
                          ),
                          DropdownMenuItem(
                            value: 'investment',
                            child: Text('Inversión'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedFilter = value!;
                          });
                          _applyFilters();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Ordenamiento
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _sortBy,
                        decoration: InputDecoration(
                          labelText: 'Ordenar',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'name',
                            child: Text('Nombre'),
                          ),
                          DropdownMenuItem(
                            value: 'balance',
                            child: Text('Balance'),
                          ),
                          DropdownMenuItem(value: 'type', child: Text('Tipo')),
                          DropdownMenuItem(
                            value: 'created',
                            child: Text('Fecha'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _sortBy = value!;
                          });
                          _applyFilters();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Botón de orden
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _sortAscending = !_sortAscending;
                        });
                        _applyFilters();
                      },
                      icon: Icon(
                        _sortAscending
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                      ),
                      tooltip: _sortAscending ? 'Ascendente' : 'Descendente',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildErrorState()
          : _accounts.isEmpty
          ? _buildEmptyState()
          : _buildAccountsList(),
      floatingActionButton: FloatingActionButton(
        heroTag: "accounts_fab",
        onPressed: _navigateToAddAccount,
        child: const Icon(Icons.add),
      ),
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
          ElevatedButton(
            onPressed: _loadAccounts,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No tienes cuentas',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Agrega tu primera cuenta para comenzar',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _navigateToAddAccount,
            icon: const Icon(Icons.add),
            label: const Text('Agregar Cuenta'),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountsList() {
    return RefreshIndicator(
      onRefresh: _loadAccounts,
      child: CustomScrollView(
        slivers: [
          // Resumen compacto
          SliverToBoxAdapter(child: _buildCompactSummary()),

          // Contador de resultados
          if (_searchQuery.isNotEmpty || _selectedFilter != 'all')
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Text(
                  '${_filteredAccounts.length} cuenta${_filteredAccounts.length != 1 ? 's' : ''} encontrada${_filteredAccounts.length != 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

          // Lista de cuentas
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final account = _filteredAccounts[index];
              return _buildCompactAccountCard(account);
            }, childCount: _filteredAccounts.length),
          ),

          // Espacio para el FAB
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
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
        return Colors.indigo;
      default:
        return Theme.of(context).primaryColor;
    }
  }

  // Navigation methods
  void _navigateToAddAccount() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AccountFormScreen(onSaved: (_) => _loadAccounts()),
      ),
    );
  }

  void _navigateToEditAccount(Account account) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AccountFormScreen(
          account: account,
          onSaved: (_) => _loadAccounts(),
        ),
      ),
    );
  }

  void _navigateToTransfer(Account account) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TransferScreen(
          fromAccount: account,
          accounts: _accounts,
          onTransferComplete: () => _loadAccounts(),
        ),
      ),
    );
  }

  void _navigateToAccountDetails(Account account) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AccountDetailsScreen(account: account),
      ),
    );
  }

  void _showDeleteConfirmation(Account account) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Cuenta'),
        content: Text(
          '¿Estás seguro de que quieres eliminar la cuenta "${account.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteAccount(account);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount(Account account) async {
    try {
      final response = await _apiService.deleteAccount(account.id!);
      if (mounted) {
        if (response.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Cuenta "${account.name}" eliminada'),
              backgroundColor: Colors.green,
            ),
          );
          _loadAccounts();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message ?? 'Error al eliminar cuenta'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error de conexión: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Helper methods
  Widget _buildCompactSummary() {
    // Calculate total balance excluding credit cards (they represent debt, not assets)
    final totalBalance = _accounts.fold<double>(
      0,
      (sum, account) => account.type == 'credit' ? sum : sum + account.balance,
    );

    final creditAccounts = _accounts.where((a) => a.type == 'credit').toList();
    final totalCreditLimit = creditAccounts.fold<double>(
      0,
      (sum, account) => sum + (account.creditLimit ?? 0),
    );

    // For credit cards, balance represents debt (positive values)
    // We want to show how much credit is being used
    final totalCreditUsed = creditAccounts.fold<double>(
      0,
      (sum, account) => sum + (account.balance > 0 ? account.balance : 0),
    );

    final creditUtilization = totalCreditLimit > 0
        ? (totalCreditUsed / totalCreditLimit) * 100
        : 0.0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          // Balance total en la parte superior
          Row(
            children: [
              Icon(
                Icons.account_balance_wallet,
                color: Theme.of(context).primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Balance Total',
                style: TextStyle(
                  color:
                      Theme.of(context).textTheme.bodyLarge?.color ??
                      Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                NumberFormat.currency(symbol: '\$').format(totalBalance),
                style: TextStyle(
                  color: totalBalance >= 0 ? Colors.green : Colors.red,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Estadísticas en una fila
          Row(
            children: [
              Expanded(
                child: _buildCompactStat(
                  'Cuentas',
                  _accounts.length.toString(),
                  Icons.account_balance_wallet_outlined,
                  Theme.of(context).primaryColor,
                ),
              ),
              Container(
                width: 1,
                height: 30,
                color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
              ),
              Expanded(
                child: _buildCompactStat(
                  'Crédito',
                  '${creditUtilization.toStringAsFixed(0)}%',
                  Icons.credit_card,
                  creditUtilization > 80
                      ? Colors.red
                      : creditUtilization > 60
                      ? Colors.orange
                      : Colors.green,
                ),
              ),
              Container(
                width: 1,
                height: 30,
                color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
              ),
              Expanded(
                child: _buildCompactStat(
                  'Efectivo',
                  _accounts.where((a) => a.type == 'cash').length.toString(),
                  Icons.account_balance_wallet,
                  Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactAccountCard(Account account) {
    final isCredit = account.type == 'credit';
    final availableCredit = isCredit ? (account.availableCredit ?? 0) : 0.0;
    final typeColor = _getTypeColor(account.type);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _navigateToAccountDetails(account),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icono de tipo
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: typeColor.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    _getTypeIcon(account.type),
                    color: typeColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),

                // Información de la cuenta
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              account.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (account.isDefault)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue[600],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Principal',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        account.typeDisplay,
                        style: TextStyle(
                          fontSize: 12,
                          color: typeColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Balance y acciones
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      NumberFormat.currency(
                        symbol: '\$',
                      ).format(account.balance),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: account.balance >= 0
                            ? Colors.green[700]
                            : Colors.red[700],
                      ),
                    ),
                    if (isCredit && availableCredit > 0)
                      Text(
                        'Disponible: ${NumberFormat.currency(symbol: '\$').format(availableCredit)}',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildCompactActionButton(
                          icon: isCredit ? Icons.payment : Icons.swap_horiz,
                          color: isCredit ? Colors.green : Colors.blue,
                          onTap: () => _navigateToTransfer(account),
                          tooltip: isCredit ? 'Pagar' : 'Transferir',
                        ),
                        const SizedBox(width: 8),
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            switch (value) {
                              case 'edit':
                                _navigateToEditAccount(account);
                                break;
                              case 'delete':
                                _showDeleteConfirmation(account);
                                break;
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, size: 16),
                                  SizedBox(width: 8),
                                  Text('Editar'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.delete,
                                    size: 16,
                                    color: Colors.red,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Eliminar',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ],
                              ),
                            ),
                          ],
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

  Widget _buildCompactActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
      ),
    );
  }

  Widget _buildCompactStat(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          title,
          style: TextStyle(
            color:
                Theme.of(context).textTheme.bodyMedium?.color ??
                Colors.grey[600],
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
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
}
