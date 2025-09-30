import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/account.dart';
import '../models/transfer_category.dart';
import '../services/api_service.dart';

class TransferScreen extends StatefulWidget {
  final Account fromAccount;
  final List<Account> accounts;
  final VoidCallback onTransferComplete;

  const TransferScreen({
    Key? key,
    required this.fromAccount,
    required this.accounts,
    required this.onTransferComplete,
  }) : super(key: key);

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _apiService = ApiService();

  Account? _selectedToAccount;
  String? _selectedTransferCategoryId;
  List<TransferCategory> _transferCategories = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadTransferCategories();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadTransferCategories() async {
    try {
      final response = await _apiService.getTransferCategories();
      if (response.success && response.data != null) {
        setState(() {
          _transferCategories = (response.data as List)
              .map((item) => TransferCategory.fromMap(item))
              .toList();
        });
      }
    } catch (e) {
      // Silently fail - categories are optional
    }
  }

  Future<void> _processTransfer() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedToAccount == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final amount = double.parse(_amountController.text);

      // Crear descripción apropiada según el tipo de transferencia
      String description;
      if (_selectedToAccount!.type == 'credit') {
        description =
            'Pago de tarjeta de crédito ${_selectedToAccount!.name} desde ${widget.fromAccount.name}';
      } else {
        description =
            'Transferencia de ${widget.fromAccount.name} a ${_selectedToAccount!.name}';
      }

      final transferData = {
        'toAccount': _selectedToAccount!.id,
        'amount': amount,
        'description': description,
      };

      if (_selectedTransferCategoryId != null) {
        transferData['transferCategoryId'] = _selectedTransferCategoryId;
      }

      final response = await _apiService.transferMoney(
        widget.fromAccount.id!,
        transferData,
      );

      if (response.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Transferencia exitosa: \$${amount.toStringAsFixed(2)}',
              ),
              backgroundColor: Colors.green,
            ),
          );
          widget.onTransferComplete();
          Navigator.of(context).pop();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message ?? 'Error al transferir'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al transferir: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showPaymentDialog() {
    // Filtrar cuentas que permiten transferencias (excluir tarjetas de crédito)
    final transferableAccounts = widget.accounts
        .where((account) => account.type != 'credit')
        .toList();

    if (transferableAccounts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No tienes cuentas disponibles para pagar (excluyendo tarjetas de crédito)',
          ),
        ),
      );
      return;
    }

    Account? selectedFromAccount;
    final amountController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.payment, color: Colors.green[600]),
              const SizedBox(width: 8),
              const Text('Pagar Tarjeta'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Información de la tarjeta
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.credit_card,
                      color: Colors.orange[600],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.fromAccount.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Text(
                      widget.fromAccount.formattedBalance,
                      style: TextStyle(
                        color: widget.fromAccount.balance < 0
                            ? Colors.red[600]
                            : Colors.green[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Selección de cuenta origen
              DropdownButtonFormField<Account>(
                value: selectedFromAccount,
                decoration: const InputDecoration(
                  labelText: 'Cuenta de pago *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.account_balance_wallet),
                ),
                items: transferableAccounts.map((account) {
                  return DropdownMenuItem<Account>(
                    value: account,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(account.typeIcon, size: 20),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            '${account.name} • ${account.formattedBalance}',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedFromAccount = value;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Campo de monto
              TextFormField(
                controller: amountController,
                decoration: const InputDecoration(
                  labelText: 'Monto a pagar *',
                  hintText: '0.00',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                  prefixText: '\$ ',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed:
                  selectedFromAccount != null &&
                      amountController.text.isNotEmpty &&
                      double.tryParse(amountController.text) != null &&
                      double.parse(amountController.text) > 0
                  ? () {
                      Navigator.of(context).pop(); // Cerrar diálogo primero
                      _processPayment(
                        selectedFromAccount!,
                        amountController.text,
                      );
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
              ),
              child: const Text('Pagar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processPayment(Account fromAccount, String amountText) async {
    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa un monto válido'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (fromAccount.balance < amount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Saldo insuficiente. Disponible: \$${fromAccount.formattedBalance}',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Mostrar loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Procesando pago...'),
          ],
        ),
      ),
    );

    try {
      final transferData = {
        'toAccount': widget.fromAccount.id,
        'amount': amount,
        'description':
            'Pago de tarjeta de crédito ${widget.fromAccount.name} desde ${fromAccount.name}',
      };

      final response = await _apiService.transferMoney(
        fromAccount.id!,
        transferData,
      );

      // Cerrar loading
      Navigator.of(context).pop();

      if (response.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Pago exitoso: \$${amount.toStringAsFixed(2)}'),
              backgroundColor: Colors.green,
            ),
          );
          widget.onTransferComplete();
          Navigator.of(context).pop();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message ?? 'Error al procesar pago'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Cerrar loading
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al procesar pago: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filtrar cuentas disponibles
    // - Si la cuenta origen es tarjeta de crédito: no permitir transferencias
    // - Si la cuenta origen es normal: permitir transferir a cualquier cuenta (incluyendo tarjetas de crédito para pagar deuda)
    final availableAccounts = widget.accounts
        .where((account) => account.id != widget.fromAccount.id)
        .toList();

    // Si la cuenta origen es una tarjeta de crédito, mostrar diálogo de pago directo
    if (widget.fromAccount.type == 'credit') {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Pagar Tarjeta de Crédito',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
          ),
          backgroundColor: Colors.green[600],
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.payment, size: 64, color: Colors.green[400]),
              const SizedBox(height: 24),
              Text(
                'Pagar ${widget.fromAccount.name}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Selecciona una cuenta para pagar tu tarjeta de crédito',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _showPaymentDialog,
                  icon: const Icon(Icons.account_balance_wallet),
                  label: const Text('Seleccionar Cuenta de Pago'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Transferir Dinero',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton.icon(
              onPressed: _processTransfer,
              icon: const Icon(Icons.send),
              label: const Text('Transferir'),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Cuenta origen
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      widget.fromAccount.typeIcon,
                      size: 24,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cuenta origen',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.7),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.fromAccount.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Saldo: ${widget.fromAccount.formattedBalance}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Monto
            TextFormField(
              controller: _amountController,
              decoration: InputDecoration(
                labelText: 'Monto a transferir *',
                hintText: '0.00',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.attach_money),
                prefixText: '\$ ',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'El monto es requerido';
                }
                final amount = double.tryParse(value);
                if (amount == null || amount <= 0) {
                  return 'Ingresa un monto válido';
                }
                // Solo validar saldo suficiente si la cuenta origen no es tarjeta de crédito
                if (widget.fromAccount.type != 'credit' &&
                    amount > widget.fromAccount.balance) {
                  return 'Saldo insuficiente';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Cuenta destino
            DropdownButtonFormField<Account>(
              value: _selectedToAccount,
              decoration: InputDecoration(
                labelText: 'Cuenta destino *',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.account_balance_wallet),
              ),
              items: availableAccounts.map((account) {
                String displayText;
                if (account.type == 'credit') {
                  displayText =
                      '${account.name} - Deuda: ${account.formattedBalance}';
                } else {
                  displayText = '${account.name} - ${account.formattedBalance}';
                }

                return DropdownMenuItem<Account>(
                  value: account,
                  child: Text(
                    displayText,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedToAccount = value;
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Selecciona una cuenta destino';
                }
                return null;
              },
            ),

            // Información adicional si se selecciona tarjeta de crédito
            if (_selectedToAccount?.type == 'credit') ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[600], size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pago de tarjeta de crédito',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.blue[800],
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Este pago reducirá la deuda de tu tarjeta y aumentará el crédito disponible.',
                            style: TextStyle(
                              color: Colors.blue[700],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),

            // Categoría de transferencia (opcional)
            if (_transferCategories.isNotEmpty) ...[
              DropdownButtonFormField<String>(
                value: _selectedTransferCategoryId,
                decoration: InputDecoration(
                  labelText: 'Categoría de transferencia',
                  hintText: 'Selecciona una categoría (opcional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.category),
                ),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('Sin categoría'),
                  ),
                  ..._transferCategories.map((category) {
                    return DropdownMenuItem<String>(
                      value: category.id,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: Color(
                                int.parse(
                                  category.color.replaceFirst('#', '0xFF'),
                                ),
                              ),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Text(
                              category.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedTransferCategoryId = value;
                  });
                },
              ),
              const SizedBox(height: 24),
            ],
            const SizedBox(height: 8),

            // Botón transferir
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _processTransfer,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send),
                label: Text(
                  _isLoading ? 'Transferiendo...' : 'Realizar Transferencia',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
