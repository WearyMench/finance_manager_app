import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import '../models/api_models.dart' as api_models;
import '../theme/app_theme.dart';
import '../widgets/loading_overlay.dart';

class TransactionFormScreen extends StatefulWidget {
  final String type; // 'income' or 'expense'
  final api_models.Transaction? transaction; // For editing

  const TransactionFormScreen({
    super.key,
    required this.type,
    this.transaction,
  });

  @override
  State<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends State<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _selectedCategoryId;
  String _selectedPaymentMethod = 'cash';
  DateTime _selectedDate = DateTime.now();

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  final List<String> _paymentMethods = ['cash', 'transfer', 'debit', 'credit'];

  final Map<String, String> _paymentMethodLabels = {
    'cash': 'Efectivo',
    'transfer': 'Transferencia',
    'debit': 'Débito',
    'credit': 'Crédito',
  };

  @override
  void initState() {
    super.initState();
    if (widget.transaction != null) {
      _amountController.text = widget.transaction!.amount.toString();
      _descriptionController.text = widget.transaction!.description;
      _selectedCategoryId = widget.transaction!.category.id;
      _selectedPaymentMethod = widget.transaction!.paymentMethod;
      _selectedDate = widget.transaction!.date;
    }
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

      bool success;
      if (widget.transaction != null) {
        // Editing existing transaction
        success = await transactionProvider.updateTransaction(
          widget.transaction!.id,
          type: widget.type,
          amount: amount,
          description: description,
          category: _selectedCategoryId!,
          paymentMethod: _selectedPaymentMethod,
          date: _selectedDate,
        );
      } else {
        // Creating new transaction
        success = await transactionProvider.createTransaction(
          type: widget.type,
          amount: amount,
          description: description,
          category: _selectedCategoryId!,
          paymentMethod: _selectedPaymentMethod,
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

  @override
  Widget build(BuildContext context) {
    final isIncome = widget.type == 'income';
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
                              .where((cat) => cat.type == widget.type)
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
                          child: _isLoading
                              ? SizedBox(
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
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      isEditing ? Icons.save : Icons.add,
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
