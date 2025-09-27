import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import '../models/api_models.dart' as api_models;
import '../utils/app_colors.dart';

class EditTransactionScreen extends StatefulWidget {
  final api_models.Transaction transaction;

  const EditTransactionScreen({super.key, required this.transaction});

  @override
  State<EditTransactionScreen> createState() => _EditTransactionScreenState();
}

class _EditTransactionScreenState extends State<EditTransactionScreen> {
  late final TextEditingController _descriptionController;
  late final TextEditingController _amountController;
  late final TextEditingController _categoryController;
  late final TextEditingController _paymentMethodController;

  String _selectedType = 'expense';
  DateTime _selectedDate = DateTime.now();
  String? _errorMessage;
  bool _isLoading = false;

  final List<String> _defaultCategories = [
    'Comida',
    'Transporte',
    'Ocio',
    'Servicios',
    'Ropa',
    'Salud',
    'Educación',
    'Otros',
  ];

  final List<String> _paymentMethods = [
    'Efectivo',
    'Tarjeta de Débito',
    'Tarjeta de Crédito',
    'Transferencia',
    'Cheque',
    'Otro',
  ];

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(
      text: widget.transaction.description,
    );
    _amountController = TextEditingController(
      text: widget.transaction.amount.toString(),
    );
    _categoryController = TextEditingController(
      text: widget.transaction.category.name,
    );
    _paymentMethodController = TextEditingController(
      text: widget.transaction.paymentMethod,
    );
    _selectedType = widget.transaction.type;
    _selectedDate = widget.transaction.date;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _categoryController.dispose();
    _paymentMethodController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveTransaction() async {
    if (!_validateForm()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final transactionProvider = Provider.of<TransactionProvider>(
        context,
        listen: false,
      );

      final success = await transactionProvider.updateTransaction(
        widget.transaction.id,
        type: _selectedType,
        amount: double.parse(_amountController.text),
        description: _descriptionController.text.trim(),
        category: _categoryController.text.trim(),
        paymentMethod: _paymentMethodController.text.trim(),
        date: _selectedDate,
      );

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Transacción actualizada correctamente'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true);
        }
      } else {
        setState(() {
          _errorMessage =
              transactionProvider.error ?? 'Error al actualizar la transacción';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error de conexión: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  bool _validateForm() {
    if (_descriptionController.text.trim().isEmpty) {
      _showError('La descripción es requerida');
      return false;
    }

    if (_amountController.text.trim().isEmpty) {
      _showError('El monto es requerido');
      return false;
    }

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      _showError('El monto debe ser un número válido mayor a 0');
      return false;
    }

    if (_categoryController.text.trim().isEmpty) {
      _showError('La categoría es requerida');
      return false;
    }

    if (_paymentMethodController.text.trim().isEmpty) {
      _showError('El método de pago es requerido');
      return false;
    }

    return true;
  }

  void _showError(String message) {
    setState(() {
      _errorMessage = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: Text(
          'Editar ${_selectedType == 'income' ? 'Ingreso' : 'Gasto'}',
        ),
        backgroundColor: AppColors.getPrimaryColor(context),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveTransaction,
              child: const Text(
                'Guardar',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Error message
            if (_errorMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.getDangerColor(context).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.getDangerColor(context).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: AppColors.getDangerColor(context),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: AppColors.getDangerColor(context),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Type selection
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tipo de Transacción',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('Gasto'),
                            value: 'expense',
                            groupValue: _selectedType,
                            onChanged: (value) {
                              setState(() {
                                _selectedType = value!;
                              });
                            },
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('Ingreso'),
                            value: 'income',
                            groupValue: _selectedType,
                            onChanged: (value) {
                              setState(() {
                                _selectedType = value!;
                              });
                            },
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Descripción',
                prefixIcon: const Icon(Icons.description),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
              textCapitalization: TextCapitalization.sentences,
            ),

            const SizedBox(height: 16),

            // Amount
            TextFormField(
              controller: _amountController,
              decoration: InputDecoration(
                labelText: 'Monto',
                prefixIcon: const Icon(Icons.attach_money),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),

            const SizedBox(height: 16),

            // Category
            TextFormField(
              controller: _categoryController,
              decoration: InputDecoration(
                labelText: 'Categoría',
                prefixIcon: const Icon(Icons.category),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                suffixIcon: PopupMenuButton<String>(
                  icon: const Icon(Icons.arrow_drop_down),
                  onSelected: (value) {
                    _categoryController.text = value;
                  },
                  itemBuilder: (context) => _defaultCategories.map((category) {
                    return PopupMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                ),
              ),
              textCapitalization: TextCapitalization.words,
            ),

            const SizedBox(height: 16),

            // Payment Method
            TextFormField(
              controller: _paymentMethodController,
              decoration: InputDecoration(
                labelText: 'Método de Pago',
                prefixIcon: const Icon(Icons.payment),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                suffixIcon: PopupMenuButton<String>(
                  icon: const Icon(Icons.arrow_drop_down),
                  onSelected: (value) {
                    _paymentMethodController.text = value;
                  },
                  itemBuilder: (context) => _paymentMethods.map((method) {
                    return PopupMenuItem(value: method, child: Text(method));
                  }).toList(),
                ),
              ),
              textCapitalization: TextCapitalization.words,
            ),

            const SizedBox(height: 16),

            // Date
            InkWell(
              onTap: _selectDate,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Fecha',
                  prefixIcon: const Icon(Icons.calendar_today),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                ),
                child: Text(
                  DateFormat('dd/MM/yyyy').format(_selectedDate),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Save button
            ElevatedButton(
              onPressed: _isLoading ? null : _saveTransaction,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.getPrimaryColor(context),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Actualizar Transacción',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
