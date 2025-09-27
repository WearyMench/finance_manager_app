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

      final transferData = {
        'toAccount': _selectedToAccount!.id,
        'amount': amount,
        'description':
            'Transferencia de ${widget.fromAccount.name} a ${_selectedToAccount!.name}',
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

  @override
  Widget build(BuildContext context) {
    final availableAccounts = widget.accounts
        .where((account) => account.id != widget.fromAccount.id)
        .toList();

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
                if (amount > widget.fromAccount.balance) {
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
                return DropdownMenuItem<Account>(
                  value: account,
                  child: Text(
                    '${account.name} - ${account.formattedBalance}',
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
