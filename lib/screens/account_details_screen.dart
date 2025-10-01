import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/account.dart';
import '../services/api_service.dart';
import 'account_form_screen.dart';
import 'transfer_screen.dart';
import 'account_analysis_screen.dart';

class AccountDetailsScreen extends StatefulWidget {
  final Account account;

  const AccountDetailsScreen({super.key, required this.account});

  @override
  State<AccountDetailsScreen> createState() => _AccountDetailsScreenState();
}

class _AccountDetailsScreenState extends State<AccountDetailsScreen> {
  final ApiService _apiService = ApiService();
  Account? _updatedAccount;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Cargar datos de forma asíncrona para evitar problemas de desmontaje
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadAccountDetails();
      }
    });
  }

  Future<void> _loadAccountDetails() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _apiService.getAccount(widget.account.id!);

      if (!mounted) return;

      if (response.success && response.data != null) {
        setState(() {
          _updatedAccount = Account.fromMap(
            response.data as Map<String, dynamic>,
          );
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response.message ?? 'Error al cargar detalles de la cuenta';
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
    final account = _updatedAccount ?? widget.account;

    return Scaffold(
      appBar: AppBar(
        title: Text(account.name),
        actions: [
          IconButton(
            onPressed: _loadAccountDetails,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  _navigateToEditAccount(account);
                  break;
                case 'transfer':
                  _navigateToTransfer(account);
                  break;
                case 'analysis':
                  _navigateToAnalysis(account);
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
                value: 'transfer',
                child: Row(
                  children: [
                    Icon(Icons.swap_horiz, size: 18),
                    SizedBox(width: 8),
                    Text('Transferir'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'analysis',
                child: Row(
                  children: [
                    Icon(Icons.analytics, size: 18),
                    SizedBox(width: 8),
                    Text('Análisis'),
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildErrorState()
          : _buildAccountDetails(account),
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
            onPressed: _loadAccountDetails,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountDetails(Account account) {
    final isCredit = account.type == 'credit';
    final availableCredit = isCredit ? (account.availableCredit ?? 0) : 0.0;
    final creditUsage =
        isCredit && account.creditLimit != null && account.creditLimit! > 0
        ? (account.balance > 0 ? account.balance : 0) / account.creditLimit!
        : 0.0;

    return RefreshIndicator(
      onRefresh: _loadAccountDetails,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Información principal de la cuenta
            _buildAccountInfoCard(
              account,
              isCredit,
              availableCredit,
              creditUsage,
            ),

            const SizedBox(height: 20),

            // Acciones rápidas compactas
            _buildCompactQuickActions(account),

            const SizedBox(height: 20),

            // Información de la cuenta compacta
            _buildCompactAccountInfo(account),

            const SizedBox(height: 20),

            // Barra de progreso para crédito (solo si es tarjeta de crédito)
            if (isCredit) ...[
              _buildCreditUsageCard(creditUsage),
              const SizedBox(height: 20),
            ],

            // Botón para análisis detallado
            _buildAnalysisButton(account),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountInfoCard(
    Account account,
    bool isCredit,
    double availableCredit,
    double creditUsage,
  ) {
    final typeColor = _getTypeColor(account.type);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con icono y nombre
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: typeColor.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Icon(
                  _getTypeIcon(account.type),
                  color: typeColor,
                  size: 24,
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
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(
                                context,
                              ).textTheme.bodyLarge?.color,
                            ),
                          ),
                        ),
                        if (account.isDefault)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue[600],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Principal',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getTypeDisplayName(account.type),
                      style: TextStyle(
                        fontSize: 14,
                        color: typeColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
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
                color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
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
                              Theme.of(context).textTheme.bodyMedium?.color ??
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
                                Theme.of(context).textTheme.bodyMedium?.color ??
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
                            fontSize: 18,
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

          // Información adicional para tarjetas de crédito
          if (isCredit) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    'Límite de Crédito',
                    NumberFormat.currency(
                      symbol: '\$',
                    ).format(account.creditLimit ?? 0),
                    Colors.grey[600]!,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInfoItem(
                    'Uso de Crédito',
                    '${(creditUsage * 100).toStringAsFixed(1)}%',
                    creditUsage > 0.8
                        ? Colors.red[600]!
                        : creditUsage > 0.6
                        ? Colors.orange[600]!
                        : Colors.green[600]!,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color:
                Theme.of(context).textTheme.bodyMedium?.color ??
                Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildCompactQuickActions(Account account) {
    return Container(
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
          Expanded(
            child: _buildCompactActionButton(
              icon: Icons.edit,
              title: 'Editar',
              color: Colors.blue,
              onTap: () => _navigateToEditAccount(account),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildCompactActionButton(
              icon: account.type == 'credit' ? Icons.payment : Icons.swap_horiz,
              title: account.type == 'credit' ? 'Pagar' : 'Transferir',
              color: account.type == 'credit' ? Colors.green : Colors.orange,
              onTap: () => _navigateToTransfer(account),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildCompactActionButton(
              icon: Icons.analytics,
              title: 'Análisis',
              color: Colors.purple,
              onTap: () => _navigateToAnalysis(account),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactActionButton({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactAccountInfo(Account account) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Theme.of(context).primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Información de la Cuenta',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildCompactInfoRow('Tipo', _getTypeDisplayName(account.type)),
          _buildCompactInfoRow('Moneda', account.currency),
          if (account.bankName != null && account.bankName!.isNotEmpty)
            _buildCompactInfoRow('Banco', account.bankName!),
          if (account.accountNumber != null &&
              account.accountNumber!.isNotEmpty)
            _buildCompactInfoRow('Número', account.accountNumber!),
          _buildCompactInfoRow(
            'Creada',
            DateFormat('dd/MM/yyyy').format(account.createdAt),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreditUsageCard(double creditUsage) {
    final usageColor = creditUsage > 0.8
        ? Colors.red[600]!
        : creditUsage > 0.6
        ? Colors.orange[600]!
        : Colors.green[600]!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.credit_card, color: usageColor, size: 18),
              const SizedBox(width: 8),
              Text(
                'Uso de Crédito',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              const Spacer(),
              Text(
                '${(creditUsage * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: usageColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: creditUsage.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: usageColor,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            creditUsage > 0.8
                ? 'Uso alto - considera reducir gastos'
                : creditUsage > 0.6
                ? 'Uso moderado de crédito'
                : 'Uso bajo de crédito',
            style: TextStyle(
              fontSize: 11,
              color: usageColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisButton(Account account) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToAnalysis(account),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.analytics,
                    color: Colors.purple,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Análisis Detallado',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      Text(
                        'Ver estadísticas y tendencias',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Navigation methods
  void _navigateToEditAccount(Account account) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AccountFormScreen(
          account: account,
          onSaved: (updatedAccount) {
            setState(() {
              _updatedAccount = updatedAccount;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Cuenta actualizada correctamente'),
                backgroundColor: Colors.green,
              ),
            );
          },
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
          accounts: [account], // Solo pasamos la cuenta actual por ahora
          onTransferComplete: () {
            _loadAccountDetails();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Transferencia completada'),
                backgroundColor: Colors.green,
              ),
            );
          },
        ),
      ),
    );
  }

  void _navigateToAnalysis(Account account) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AccountAnalysisScreen(
          accountId: account.id!,
          accountName: account.name,
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
          '¿Estás seguro de que quieres eliminar la cuenta "${account.name}"? Esta acción no se puede deshacer.',
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
          Navigator.pop(
            context,
            true,
          ); // Retorna true para indicar que se eliminó
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
  String _getTypeDisplayName(String type) {
    switch (type) {
      case 'cash':
        return 'Efectivo';
      case 'bank':
        return 'Cuenta Bancaria';
      case 'credit':
        return 'Tarjeta de Crédito';
      case 'savings':
        return 'Cuenta de Ahorros';
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
}
