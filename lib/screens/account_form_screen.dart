import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/account.dart';
import '../services/api_service.dart';
import '../models/api_models.dart' as api_models;

class AccountFormScreen extends StatefulWidget {
  final Account? account;
  final Function(Account) onSaved;

  const AccountFormScreen({Key? key, this.account, required this.onSaved})
    : super(key: key);

  @override
  State<AccountFormScreen> createState() => _AccountFormScreenState();
}

class _AccountFormScreenState extends State<AccountFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _balanceController = TextEditingController();
  final _creditLimitController = TextEditingController();
  final _initialDebtController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _accountNumberController = TextEditingController();

  String _selectedType = 'cash';
  String _selectedCurrency = 'USD';
  bool _isDefault = false;
  bool _isLoading = false;

  final List<Map<String, dynamic>> _accountTypes = [
    {
      'value': 'cash',
      'label': 'Efectivo',
      'icon': Icons.account_balance_wallet,
    },
    {
      'value': 'bank',
      'label': 'Cuenta Bancaria',
      'icon': Icons.account_balance,
    },
    {
      'value': 'credit',
      'label': 'Tarjeta de Crédito',
      'icon': Icons.credit_card,
    },
    {'value': 'savings', 'label': 'Cuenta de Ahorros', 'icon': Icons.savings},
    {'value': 'investment', 'label': 'Inversión', 'icon': Icons.trending_up},
  ];

  final List<Map<String, String>> _currencies = [
    {'value': 'USD', 'label': 'USD - Dólar Americano'},
    {'value': 'EUR', 'label': 'EUR - Euro'},
    {'value': 'MXN', 'label': 'MXN - Peso Mexicano'},
    {'value': 'COP', 'label': 'COP - Peso Colombiano'},
    {'value': 'DOP', 'label': 'DOP - Peso Dominicano'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.account != null) {
      _nameController.text = widget.account!.name;
      _descriptionController.text = widget.account!.description ?? '';
      _balanceController.text = widget.account!.balance.toString();
      _creditLimitController.text =
          widget.account!.creditLimit?.toString() ?? '';
      _bankNameController.text = widget.account!.bankName ?? '';
      _accountNumberController.text = widget.account!.accountNumber ?? '';
      _selectedType = widget.account!.type;
      _selectedCurrency = widget.account!.currency;
      _isDefault = widget.account!.isDefault;
    } else {
      _balanceController.text = '0.00';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _balanceController.dispose();
    _creditLimitController.dispose();
    _initialDebtController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();
    super.dispose();
  }

  Future<void> _saveAccount() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Calculate balance for credit cards
      double balance = double.parse(_balanceController.text);
      if (_selectedType == 'credit' && _initialDebtController.text.isNotEmpty) {
        // For credit cards, balance represents debt (positive values)
        // If user enters initial debt, use it as positive balance
        final initialDebt = double.parse(_initialDebtController.text);
        balance = initialDebt; // Positive balance = debt
      }

      final accountData = {
        'name': _nameController.text.trim(),
        'type': _selectedType,
        'balance': balance,
        'currency': _selectedCurrency,
        'description': _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        'isDefault': _isDefault,
      };

      // Add type-specific fields
      if (_selectedType == 'credit') {
        accountData['creditLimit'] = double.parse(_creditLimitController.text);
      }

      if (_selectedType == 'bank') {
        if (_bankNameController.text.trim().isNotEmpty) {
          accountData['bankName'] = _bankNameController.text.trim();
        }
        if (_accountNumberController.text.trim().isNotEmpty) {
          accountData['accountNumber'] = _accountNumberController.text.trim();
        }
      }

      api_models.ApiResponse response;
      if (widget.account != null) {
        response = await _apiService.updateAccount(
          widget.account!.id!,
          accountData,
        );
      } else {
        response = await _apiService.createAccount(accountData);
      }

      if (response.success && response.data != null) {
        final savedAccount = Account.fromMap(
          response.data as Map<String, dynamic>,
        );
        widget.onSaved(savedAccount);

        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.account == null
                    ? 'Cuenta creada exitosamente'
                    : 'Cuenta actualizada exitosamente',
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message ?? 'Error al guardar cuenta'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al guardar cuenta: $e')));
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
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.account == null ? 'Nueva Cuenta' : 'Editar Cuenta',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
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
              onPressed: _saveAccount,
              icon: const Icon(Icons.save),
              label: const Text('Guardar'),
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
            // Nombre de la cuenta
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Nombre de la cuenta *',
                hintText: 'Ej: Mi Cuenta Principal',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.label),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'El nombre es requerido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Tipo de cuenta
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: InputDecoration(
                labelText: 'Tipo de cuenta *',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: _accountTypes.map((type) {
                return DropdownMenuItem<String>(
                  value: type['value'],
                  child: Row(
                    children: [
                      Icon(
                        type['icon'],
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        type['label'],
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedType = value!;
                });
              },
            ),
            const SizedBox(height: 16),

            // Saldo inicial / Deuda inicial
            if (_selectedType == 'credit') ...[
              // Para tarjetas de crédito: mostrar campo de deuda inicial
              TextFormField(
                controller: _initialDebtController,
                decoration: InputDecoration(
                  labelText: 'Deuda inicial (opcional)',
                  hintText: '0.00',
                  helperText:
                      'Si ya tienes deuda en esta tarjeta, ingrésala aquí',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixText: '\$ ',
                  prefixIcon: const Icon(Icons.credit_card),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    final amount = double.tryParse(value);
                    if (amount == null || amount < 0) {
                      return 'Ingresa un monto válido (mayor o igual a 0)';
                    }
                    // Validar que la deuda inicial no exceda el límite de crédito
                    if (_creditLimitController.text.isNotEmpty) {
                      final creditLimit = double.tryParse(
                        _creditLimitController.text,
                      );
                      if (creditLimit != null && amount > creditLimit) {
                        return 'La deuda inicial no puede exceder el límite de crédito';
                      }
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[600], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Si dejas este campo vacío, la tarjeta empezará sin deuda (balance = 0)',
                        style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Para otras cuentas: saldo inicial normal
              TextFormField(
                controller: _balanceController,
                decoration: InputDecoration(
                  labelText: 'Saldo inicial *',
                  hintText: '0.00',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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
                    return 'El saldo es requerido';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null) {
                    return 'Ingresa un monto válido';
                  }
                  return null;
                },
              ),
            ],
            const SizedBox(height: 16),

            // Moneda
            DropdownButtonFormField<String>(
              value: _selectedCurrency,
              decoration: InputDecoration(
                labelText: 'Moneda *',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.currency_exchange),
              ),
              items: _currencies.map((currency) {
                return DropdownMenuItem<String>(
                  value: currency['value'],
                  child: Text(currency['label']!),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCurrency = value!;
                });
              },
            ),
            const SizedBox(height: 16),

            // Límite de crédito (solo para tarjetas de crédito)
            if (_selectedType == 'credit') ...[
              TextFormField(
                controller: _creditLimitController,
                decoration: InputDecoration(
                  labelText: 'Límite de crédito *',
                  hintText: '5000.00',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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
                    return 'El límite de crédito es requerido';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Ingresa un límite válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
            ],

            // Información bancaria (solo para cuentas bancarias)
            if (_selectedType == 'bank') ...[
              TextFormField(
                controller: _bankNameController,
                decoration: InputDecoration(
                  labelText: 'Nombre del banco',
                  hintText: 'Ej: Banco Santander',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.account_balance),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _accountNumberController,
                decoration: InputDecoration(
                  labelText: 'Número de cuenta',
                  hintText: 'Ej: 1234567890',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.numbers),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
            ],

            // Descripción
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Descripción (opcional)',
                hintText: 'Información adicional sobre la cuenta',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.description),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Cuenta principal
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
              ),
              child: CheckboxListTile(
                title: const Text(
                  'Marcar como cuenta principal',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Esta será la cuenta predeterminada para nuevas transacciones',
                  style: TextStyle(fontSize: 13),
                ),
                value: _isDefault,
                onChanged: (value) {
                  setState(() {
                    _isDefault = value ?? false;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                activeColor: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 32),

            // Botón guardar
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _saveAccount,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(widget.account == null ? Icons.add : Icons.save),
                label: Text(
                  _isLoading
                      ? 'Guardando...'
                      : widget.account == null
                      ? 'Crear Cuenta'
                      : 'Actualizar Cuenta',
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
