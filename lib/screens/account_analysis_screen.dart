import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class AccountAnalysisScreen extends StatefulWidget {
  final String accountId;
  final String accountName;

  const AccountAnalysisScreen({
    super.key,
    required this.accountId,
    required this.accountName,
  });

  @override
  State<AccountAnalysisScreen> createState() => _AccountAnalysisScreenState();
}

class _AccountAnalysisScreenState extends State<AccountAnalysisScreen> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _analysis;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAnalysis();
  }

  Future<void> _loadAnalysis() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _apiService.getAccountAnalysis(widget.accountId);

      if (response.success && response.data != null) {
        setState(() {
          _analysis = response.data as Map<String, dynamic>;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error al cargar análisis: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Análisis - ${widget.accountName}'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(onPressed: _loadAnalysis, icon: const Icon(Icons.refresh)),
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
                    onPressed: _loadAnalysis,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            )
          : _analysis == null
          ? const Center(child: Text('No hay datos disponibles'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAccountInfo(),
                  const SizedBox(height: 24),
                  _buildSummaryCards(),
                  const SizedBox(height: 24),
                  _buildTopCategories(),
                  const SizedBox(height: 24),
                  _buildRecentTransactions(),
                ],
              ),
            ),
    );
  }

  Widget _buildAccountInfo() {
    final account = _analysis!['account'] as Map<String, dynamic>? ?? {};
    final balance = account['balance'] ?? 0.0;
    final creditLimit = account['creditLimit'];
    final availableCredit = account['availableCredit'];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  _getTypeIcon(account['type'] ?? ''),
                  size: 32,
                  color: _getTypeColor(account['type'] ?? ''),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        account['name'] ?? '',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _getTypeDisplayName(account['type'] ?? ''),
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                ),
                Text(
                  NumberFormat.currency(symbol: '\$').format(balance),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (creditLimit != null) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Límite de Crédito',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          NumberFormat.currency(
                            symbol: '\$',
                          ).format(creditLimit),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (availableCredit != null)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Crédito Disponible',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            NumberFormat.currency(
                              symbol: '\$',
                            ).format(availableCredit),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: availableCredit > 0
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    final summary = _analysis!['summary'] as Map<String, dynamic>? ?? {};

    final totalIncome = (summary['totalIncome'] as num?)?.toDouble() ?? 0.0;
    final totalExpenses = (summary['totalExpenses'] as num?)?.toDouble() ?? 0.0;
    final totalTransfersIn =
        (summary['totalTransfersIn'] as num?)?.toDouble() ?? 0.0;
    final totalTransfersOut =
        (summary['totalTransfersOut'] as num?)?.toDouble() ?? 0.0;
    final transactionCount = summary['transactionCount'] as int? ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Resumen de Actividad',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Ingresos',
                NumberFormat.currency(symbol: '\$').format(totalIncome),
                Icons.trending_up,
                Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'Gastos',
                NumberFormat.currency(symbol: '\$').format(totalExpenses),
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
              child: _buildSummaryCard(
                'Transferencias Entrada',
                NumberFormat.currency(symbol: '\$').format(totalTransfersIn),
                Icons.arrow_downward,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'Transferencias Salida',
                NumberFormat.currency(symbol: '\$').format(totalTransfersOut),
                Icons.arrow_upward,
                Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildSummaryCard(
          'Total Transacciones',
          transactionCount.toString(),
          Icons.receipt,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildTopCategories() {
    final topCategories = _analysis!['topCategories'] as List<dynamic>? ?? [];

    if (topCategories.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Categorías Principales',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: topCategories.map((category) {
              final categoryData = category as Map<String, dynamic>;
              final name = categoryData['name'] ?? '';
              final amount = categoryData['amount'] ?? 0.0;
              final count = categoryData['count'] ?? 0;
              final color = categoryData['color'] ?? '#6B7280';

              return ListTile(
                leading: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Color(int.parse(color.replaceFirst('#', '0xFF'))),
                    shape: BoxShape.circle,
                  ),
                ),
                title: Text(name),
                subtitle: Text('$count transacción${count != 1 ? 'es' : ''}'),
                trailing: Text(
                  NumberFormat.currency(symbol: '\$').format(amount),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentTransactions() {
    final recentTransactions =
        _analysis!['recentTransactions'] as List<dynamic>? ?? [];

    if (recentTransactions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Transacciones Recientes',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: recentTransactions.map((transaction) {
              final transactionData = transaction as Map<String, dynamic>;
              final type = transactionData['type'] ?? '';
              final amount = transactionData['amount'] ?? 0.0;
              final description = transactionData['description'] ?? '';
              final date = transactionData['date'] != null
                  ? DateTime.tryParse(transactionData['date'].toString())
                  : null;

              return ListTile(
                leading: Icon(
                  type == 'income' ? Icons.trending_up : Icons.trending_down,
                  color: type == 'income' ? Colors.green : Colors.red,
                ),
                title: Text(description),
                subtitle: date != null
                    ? Text(DateFormat('dd/MM/yyyy').format(date))
                    : null,
                trailing: Text(
                  '${type == 'income' ? '+' : '-'}${NumberFormat.currency(symbol: '\$').format(amount)}',
                  style: TextStyle(
                    color: type == 'income' ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
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
}
