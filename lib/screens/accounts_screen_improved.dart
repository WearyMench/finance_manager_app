import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/account.dart';
import '../services/api_service.dart';
import 'account_form_screen.dart';
import 'transfer_screen.dart';

class AccountsScreenImproved extends StatefulWidget {
  const AccountsScreenImproved({super.key});

  @override
  State<AccountsScreenImproved> createState() => _AccountsScreenImprovedState();
}

class _AccountsScreenImprovedState extends State<AccountsScreenImproved> {
  final ApiService _apiService = ApiService();
  List<Account> _accounts = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
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

          // Lista de cuentas
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final account = _accounts[index];
              return _buildAccountCard(account);
            }, childCount: _accounts.length),
          ),

          // Espacio para el FAB
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  Widget _buildAccountCard(Account account) {
    final isCredit = account.type == 'credit';
    final availableCredit = isCredit ? (account.availableCredit ?? 0) : 0.0;
    final creditUsage =
        isCredit && account.creditLimit != null && account.creditLimit! > 0
        ? (account.balance < 0 ? account.balance.abs() : 0) /
              account.creditLimit!
        : 0.0;
    final typeColor = _getTypeColor(account.type);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _navigateToEditAccount(account),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Header con icono, nombre y acciones
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: typeColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: typeColor.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        _getTypeIcon(account.type),
                        color: typeColor,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  account.name,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color:
                                        Theme.of(
                                          context,
                                        ).textTheme.bodyLarge?.color ??
                                        Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (account.isDefault)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[600],
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.blue.withValues(
                                          alpha: 0.3,
                                        ),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Text(
                                    'Principal',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                _getTypeIcon(account.type),
                                size: 16,
                                color: typeColor,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                account.typeDisplay,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: typeColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        _buildActionButton(
                          icon: isCredit ? Icons.payment : Icons.swap_horiz,
                          color: isCredit ? Colors.green : Colors.blue,
                          onTap: () => _navigateToTransfer(account),
                          tooltip: isCredit ? 'Pagar tarjeta' : 'Transferir',
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
                                  Icon(
                                    Icons.delete,
                                    size: 18,
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

                const SizedBox(height: 20),

                // Balance principal
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).dividerColor.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Balance Actual',
                              style: TextStyle(
                                fontSize: 12,
                                color:
                                    Theme.of(
                                      context,
                                    ).textTheme.bodyMedium?.color ??
                                    Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              NumberFormat.currency(
                                symbol: '\$',
                              ).format(account.balance),
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: account.balance >= 0
                                    ? Colors.green[700]
                                    : Colors.red[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isCredit) ...[
                        Container(
                          width: 1,
                          height: 40,
                          color: Theme.of(
                            context,
                          ).dividerColor.withValues(alpha: 0.2),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Disponible',
                                style: TextStyle(
                                  fontSize: 12,
                                  color:
                                      Theme.of(
                                        context,
                                      ).textTheme.bodyMedium?.color ??
                                      Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                NumberFormat.currency(
                                  symbol: '\$',
                                ).format(availableCredit),
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: availableCredit > 0
                                      ? Colors.blue[700]
                                      : Colors.red[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Barra de progreso para crédito
                if (isCredit) ...[
                  const SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Uso de Crédito',
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  Theme.of(
                                    context,
                                  ).textTheme.bodyMedium?.color ??
                                  Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${(creditUsage * 100).toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 12,
                              color: creditUsage > 0.8
                                  ? Colors.red[600]
                                  : creditUsage > 0.6
                                  ? Colors.orange[600]
                                  : Colors.green[600],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).dividerColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: creditUsage.clamp(0.0, 1.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: creditUsage > 0.8
                                  ? Colors.red[400]
                                  : creditUsage > 0.6
                                  ? Colors.orange[400]
                                  : Colors.green[400],
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
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

    // For credit cards, balance represents debt (negative values)
    // We want to show how much credit is being used
    final totalCreditUsed = creditAccounts.fold<double>(
      0,
      (sum, account) => sum + (account.balance < 0 ? account.balance.abs() : 0),
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

          const SizedBox(height: 16),

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
