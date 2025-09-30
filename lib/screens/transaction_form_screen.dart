import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import '../models/api_models.dart' as api_models;
import '../models/account.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/loading_overlay.dart';

class TransactionFormScreen extends StatefulWidget {
  final String? type; // 'income' or 'expense' - optional
  final api_models.Transaction? transaction; // For editing

  const TransactionFormScreen({super.key, this.type, this.transaction});

  @override
  State<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends State<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _selectedCategoryId;
  String? _selectedAccountId;
  String _selectedPaymentMethod = 'cash';
  String _selectedType = 'expense'; // Default to expense
  DateTime _selectedDate = DateTime.now();

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  final List<String> _paymentMethods = ['cash', 'transfer', 'debit', 'credit'];
  List<Account> _accounts = [];
  final ApiService _apiService = ApiService();

  final Map<String, String> _paymentMethodLabels = {
    'cash': 'Efectivo',
    'transfer': 'Transferencia',
    'debit': 'Débito',
    'credit': 'Crédito',
  };

  @override
  void initState() {
    super.initState();

    // Set type from widget or default to expense
    _selectedType = widget.type ?? 'expense';

    if (widget.transaction != null) {
      _amountController.text = widget.transaction!.amount.toString();
      _descriptionController.text = widget.transaction!.description;
      _selectedCategoryId = widget.transaction!.category.id;
      _selectedAccountId = widget.transaction!.account.id;
      _selectedPaymentMethod = widget.transaction!.paymentMethod;
      _selectedDate = widget.transaction!.date;
      _selectedType = widget.transaction!.type;
    }
    _loadAccounts();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCategoryId == null) {
      _showError('Por favor selecciona una categoría');
      return;
    }

    if (_selectedAccountId == null) {
      _showError('Por favor selecciona una cuenta');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final transactionProvider = Provider.of<TransactionProvider>(
        context,
        listen: false,
      );

      final amount = double.parse(_amountController.text.trim());
      final description = _descriptionController.text.trim();

      // Validate account balance for expenses
      if (_selectedType == 'expense') {
        final selectedAccount = _accounts.firstWhere(
          (account) => account.id == _selectedAccountId,
          orElse: () => throw Exception('Cuenta no encontrada'),
        );

        if (selectedAccount.type == 'credit') {
          // For credit cards, check if we have available credit
          final availableCredit = selectedAccount.availableCredit ?? 0;
          if (availableCredit < amount) {
            _showError(
              'Crédito insuficiente. Disponible: \$${availableCredit.toStringAsFixed(2)}',
            );
            setState(() {
              _isLoading = false;
            });
            return;
          }
        } else {
          // For regular accounts, check if we have sufficient balance
          if (selectedAccount.balance < amount) {
            _showError(
              'Saldo insuficiente. Disponible: \$${selectedAccount.formattedBalance}',
            );
            setState(() {
              _isLoading = false;
            });
            return;
          }
        }
      }

      bool success;
      if (widget.transaction != null) {
        // Editing existing transaction
        success = await transactionProvider.updateTransaction(
          widget.transaction!.id,
          type: _selectedType,
          amount: amount,
          description: description,
          category: _selectedCategoryId!,
          paymentMethod: _selectedPaymentMethod,
          account: _selectedAccountId!,
          date: _selectedDate,
        );
      } else {
        // Creating new transaction
        success = await transactionProvider.createTransaction(
          type: _selectedType,
          amount: amount,
          description: description,
          category: _selectedCategoryId!,
          paymentMethod: _selectedPaymentMethod,
          account: _selectedAccountId!,
          date: _selectedDate,
        );
      }

      if (success) {
        setState(() {
          _isLoading = false;
          _successMessage = widget.transaction != null
              ? 'Transacción actualizada correctamente'
              : 'Transacción agregada correctamente';
        });

        // Clear success message and navigate back after 2 seconds
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.of(context).pop();
          }
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage =
              transactionProvider.error ??
              'Error al ${widget.transaction != null ? 'actualizar' : 'agregar'} la transacción';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage =
            'Error al ${widget.transaction != null ? 'actualizar' : 'agregar'} la transacción: $e';
      });
    }
  }

  void _clearMessages() {
    setState(() {
      _errorMessage = null;
      _successMessage = null;
    });
  }

  void _showError(String message) {
    setState(() {
      _errorMessage = message;
      _successMessage = null;
    });
  }

  Future<void> _loadAccounts() async {
    try {
      final response = await _apiService.getAccounts();
      if (response.success && response.data != null) {
        setState(() {
          _accounts = (response.data as List)
              .map((account) => Account.fromMap(account))
              .toList();
        });

        // Auto-select default account if none selected
        if (_selectedAccountId == null && _accounts.isNotEmpty) {
          final defaultAccount = _accounts.firstWhere(
            (account) => account.isDefault,
            orElse: () => _accounts.first,
          );
          setState(() {
            _selectedAccountId = defaultAccount.id;
          });
        }
      }
    } catch (e) {
      // Handle error silently for now
    }
  }

  @override
  Widget build(BuildContext context) {
    final isIncome = _selectedType == 'income';
    final isEditing = widget.transaction != null;

    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEditing
                  ? 'Editar ${isIncome ? 'Ingreso' : 'Gasto'}'
                  : 'Agregar ${isIncome ? 'Ingreso' : 'Gasto'}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            Text(
              isIncome
                  ? 'Registra un nuevo ingreso'
                  : 'Registra un nuevo gasto',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.8),
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        backgroundColor: isIncome
            ? AppTheme.getSuccessColor(context)
            : AppTheme.getErrorColor(context),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: TextButton(
              onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.white.withOpacity(0.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Cancelar'),
            ),
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        message: isEditing
            ? 'Actualizando transacción...'
            : 'Agregando transacción...',
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Success message
                if (_successMessage != null)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.getSuccessColor(context).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.getSuccessColor(
                          context,
                        ).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: AppTheme.getSuccessColor(context),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _successMessage!,
                            style: TextStyle(
                              color: AppTheme.getSuccessColor(context),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _clearMessages,
                          icon: Icon(
                            Icons.close,
                            color: AppTheme.getSuccessColor(context),
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Error message
                if (_errorMessage != null)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.getErrorColor(context).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.getErrorColor(context).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error,
                          color: AppTheme.getErrorColor(context),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: AppTheme.getErrorColor(context),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _clearMessages,
                          icon: Icon(
                            Icons.close,
                            color: AppTheme.getErrorColor(context),
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Form Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.getSurfaceColor(context),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color:
                                  (isIncome
                                          ? AppTheme.getSuccessColor(context)
                                          : AppTheme.getErrorColor(context))
                                      .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              isIncome
                                  ? Icons.trending_up_rounded
                                  : Icons.trending_down_rounded,
                              color: isIncome
                                  ? AppTheme.getSuccessColor(context)
                                  : AppTheme.getErrorColor(context),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isIncome ? 'Nuevo Ingreso' : 'Nuevo Gasto',
                                  style: TextStyle(
                                    color: AppTheme.getTextPrimaryColor(
                                      context,
                                    ),
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  'Completa los datos de la transacción',
                                  style: TextStyle(
                                    color: AppTheme.getTextSecondaryColor(
                                      context,
                                    ),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Amount Field
                      TextFormField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Monto',
                          hintText: '0.00',
                          prefixIcon: Icon(
                            Icons.attach_money,
                            color: AppTheme.getPrimaryColor(context),
                          ),
                          suffixText: 'RD\$',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppTheme.getBorderColor(context),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppTheme.getBorderColor(context),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppTheme.getPrimaryColor(context),
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: AppTheme.getBackgroundColor(context),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'El monto es requerido';
                          }
                          final amount = double.tryParse(value.trim());
                          if (amount == null || amount <= 0) {
                            return 'El monto debe ser un número válido mayor a 0';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Type Selection Field (only show if not editing)
                      if (widget.transaction == null) ...[
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.getBorderColor(context),
                            ),
                          ),
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.swap_horiz,
                                      color: AppTheme.getPrimaryColor(context),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Tipo de Transacción',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.getTextPrimaryColor(
                                          context,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _selectedType = 'income';
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: _selectedType == 'income'
                                              ? AppTheme.getSuccessColor(
                                                  context,
                                                ).withOpacity(0.1)
                                              : Colors.transparent,
                                          borderRadius: const BorderRadius.only(
                                            bottomLeft: Radius.circular(12),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.trending_up,
                                              color: _selectedType == 'income'
                                                  ? AppTheme.getSuccessColor(
                                                      context,
                                                    )
                                                  : Colors.grey[600],
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Ingreso',
                                              style: TextStyle(
                                                color: _selectedType == 'income'
                                                    ? AppTheme.getSuccessColor(
                                                        context,
                                                      )
                                                    : Colors.grey[600],
                                                fontWeight:
                                                    _selectedType == 'income'
                                                    ? FontWeight.w600
                                                    : FontWeight.normal,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: 1,
                                    height: 40,
                                    color: AppTheme.getBorderColor(context),
                                  ),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _selectedType = 'expense';
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: _selectedType == 'expense'
                                              ? AppTheme.getErrorColor(
                                                  context,
                                                ).withOpacity(0.1)
                                              : Colors.transparent,
                                          borderRadius: const BorderRadius.only(
                                            bottomRight: Radius.circular(12),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.trending_down,
                                              color: _selectedType == 'expense'
                                                  ? AppTheme.getErrorColor(
                                                      context,
                                                    )
                                                  : Colors.grey[600],
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Gasto',
                                              style: TextStyle(
                                                color:
                                                    _selectedType == 'expense'
                                                    ? AppTheme.getErrorColor(
                                                        context,
                                                      )
                                                    : Colors.grey[600],
                                                fontWeight:
                                                    _selectedType == 'expense'
                                                    ? FontWeight.w600
                                                    : FontWeight.normal,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Description Field
                      TextFormField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: 'Descripción',
                          hintText: 'Ej: Compra en supermercado',
                          prefixIcon: Icon(
                            Icons.description,
                            color: AppTheme.getPrimaryColor(context),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppTheme.getBorderColor(context),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppTheme.getBorderColor(context),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppTheme.getPrimaryColor(context),
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: AppTheme.getBackgroundColor(context),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'La descripción es requerida';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Category Field
                      Consumer<TransactionProvider>(
                        builder: (context, transactionProvider, child) {
                          final categories = transactionProvider.categories
                              .where((cat) => cat.type == _selectedType)
                              .toList();

                          return DropdownButtonFormField<String>(
                            value: _selectedCategoryId,
                            decoration: InputDecoration(
                              labelText: 'Categoría',
                              prefixIcon: Icon(
                                Icons.category,
                                color: AppTheme.getPrimaryColor(context),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: AppTheme.getBorderColor(context),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: AppTheme.getBorderColor(context),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: AppTheme.getPrimaryColor(context),
                                  width: 2,
                                ),
                              ),
                              filled: true,
                              fillColor: AppTheme.getBackgroundColor(context),
                            ),
                            items: categories.map((category) {
                              return DropdownMenuItem<String>(
                                value: category.id,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: Color(
                                          int.parse(
                                                category.color.substring(1),
                                                radix: 16,
                                              ) +
                                              0xFF000000,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      category.name,
                                      style: TextStyle(
                                        color: AppTheme.getTextPrimaryColor(
                                          context,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedCategoryId = value;
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor selecciona una categoría';
                              }
                              return null;
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      // Account Field
                      DropdownButtonFormField<String>(
                        value: _selectedAccountId,
                        decoration: InputDecoration(
                          labelText: 'Cuenta *',
                          hintText: 'Selecciona cualquier cuenta disponible',
                          prefixIcon: Icon(
                            Icons.account_balance,
                            color: AppTheme.getPrimaryColor(context),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppTheme.getBorderColor(context),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppTheme.getBorderColor(context),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppTheme.getPrimaryColor(context),
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: AppTheme.getSurfaceColor(context),
                        ),
                        items: _accounts.map((account) {
                          return DropdownMenuItem<String>(
                            value: account.id,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  account.typeIcon,
                                  size: 20,
                                  color: Theme.of(context).primaryColor,
                                ),
                                const SizedBox(width: 12),
                                Flexible(
                                  child: Text(
                                    account.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (account.isDefault)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green[100],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'Principal',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.green,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedAccountId = value;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor selecciona una cuenta';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Payment Method Field
                      DropdownButtonFormField<String>(
                        value: _selectedPaymentMethod,
                        decoration: InputDecoration(
                          labelText: 'Método de Pago',
                          prefixIcon: Icon(
                            Icons.payment,
                            color: AppTheme.getPrimaryColor(context),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppTheme.getBorderColor(context),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppTheme.getBorderColor(context),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppTheme.getPrimaryColor(context),
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: AppTheme.getBackgroundColor(context),
                        ),
                        items: _paymentMethods.map((method) {
                          return DropdownMenuItem<String>(
                            value: method,
                            child: Text(
                              _paymentMethodLabels[method]!,
                              style: TextStyle(
                                color: AppTheme.getTextPrimaryColor(context),
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedPaymentMethod = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Date Field
                      InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            setState(() {
                              _selectedDate = date;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppTheme.getBorderColor(context),
                            ),
                            borderRadius: BorderRadius.circular(12),
                            color: AppTheme.getBackgroundColor(context),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                color: AppTheme.getPrimaryColor(context),
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Fecha: ${DateFormat('dd/MM/yyyy').format(_selectedDate)}',
                                style: TextStyle(
                                  color: AppTheme.getTextPrimaryColor(context),
                                  fontSize: 16,
                                ),
                              ),
                              const Spacer(),
                              Icon(
                                Icons.arrow_drop_down,
                                color: AppTheme.getTextSecondaryColor(context),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _saveTransaction,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isIncome
                                ? AppTheme.getSuccessColor(context)
                                : AppTheme.getErrorColor(context),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: _isLoading
                                ? SizedBox(
                                    key: const ValueKey('loading'),
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : Row(
                                    key: const ValueKey('button'),
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        isEditing
                                            ? Icons.save_rounded
                                            : Icons.add_rounded,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        isEditing
                                            ? 'Actualizar'
                                            : 'Agregar ${isIncome ? 'Ingreso' : 'Gasto'}',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
