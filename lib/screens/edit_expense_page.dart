import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../db/database_helper.dart';

class EditExpensePage extends StatefulWidget {
  final Expense expense;
  final List<String> categories;

  const EditExpensePage({
    super.key,
    required this.expense,
    required this.categories,
  });

  @override
  State<EditExpensePage> createState() => _EditExpensePageState();
}

class _EditExpensePageState extends State<EditExpensePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final DatabaseHelper _dbHelper = DatabaseHelper();

  late List<String> _categories;
  String _selectedCategory = '';
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  String _selectedRecurrence = 'ninguna';
  final List<String> _recurrenceOptions = [
    'ninguna',
    'semanal',
    'quincenal',
    'mensual',
    'anual',
  ];

  @override
  void initState() {
    super.initState();
    _categories = widget.categories;
    _loadExpenseData();
  }

  void _loadExpenseData() {
    _nameController.text = widget.expense.nombre;
    _amountController.text = widget.expense.monto.toString();
    _selectedCategory = widget.expense.categoria;
    _selectedDate = widget.expense.fecha;
    _noteController.text = widget.expense.nota ?? '';
    _selectedRecurrence = widget.expense.recurrente ?? 'ninguna';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _updateExpense() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final amount = double.parse(_amountController.text.replaceAll(',', '.'));
      final updatedExpense = widget.expense.copyWith(
        nombre: _nameController.text.trim(),
        monto: amount,
        categoria: _selectedCategory,
        fecha: _selectedDate,
        nota: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        recurrente: _selectedRecurrence,
      );
      await _dbHelper.updateExpense(updatedExpense);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gasto actualizado correctamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al actualizar: $e')));
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
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text('Editar Gasto'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Campo Nombre
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Nombre del gasto',
                hintText: 'Ej: Almuerzo en restaurante',
                prefixIcon: const Icon(Icons.receipt),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Por favor ingresa el nombre del gasto';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Campo Monto
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Monto',
                hintText: '0.00',
                prefixIcon: const Icon(Icons.attach_money),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Por favor ingresa el monto';
                }
                final amount = double.tryParse(value.replaceAll(',', '.'));
                if (amount == null || amount <= 0) {
                  return 'Por favor ingresa un monto válido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Selector de Categoría
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: InputDecoration(
                labelText: 'Categoría',
                prefixIcon: const Icon(Icons.category),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
              items: _categories.map((String category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Row(
                    children: [
                      Icon(
                        _getCategoryIcon(category),
                        color: _getCategoryColor(category),
                      ),
                      const SizedBox(width: 8),
                      Text(category),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedCategory = newValue!;
                });
              },
            ),
            const SizedBox(height: 16),

            // Selector de Fecha
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
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Campo Nota
            TextFormField(
              controller: _noteController,
              decoration: InputDecoration(
                labelText: 'Nota (opcional)',
                hintText: 'Ej: Pago con tarjeta, descuento aplicado, etc.',
                prefixIcon: const Icon(Icons.note_alt),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            // Selector de Recurrencia
            DropdownButtonFormField<String>(
              value: _selectedRecurrence,
              decoration: InputDecoration(
                labelText: 'Recurrencia',
                prefixIcon: const Icon(Icons.repeat),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
              items: _recurrenceOptions.map((String option) {
                String displayText;
                switch (option) {
                  case 'ninguna':
                    displayText = 'No recurrente';
                    break;
                  case 'semanal':
                    displayText = 'Cada semana';
                    break;
                  case 'quincenal':
                    displayText = 'Cada 15 días';
                    break;
                  case 'mensual':
                    displayText = 'Cada mes';
                    break;
                  case 'anual':
                    displayText = 'Cada año';
                    break;
                  default:
                    displayText = option;
                }
                return DropdownMenuItem<String>(
                  value: option,
                  child: Text(displayText),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedRecurrence = newValue!;
                });
              },
            ),
            const SizedBox(height: 32),

            // Botón Actualizar
            ElevatedButton(
              onPressed: _isLoading ? null : _updateExpense,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Actualizar Gasto',
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

  Color _getCategoryColor(String categoria) {
    switch (categoria.toLowerCase()) {
      case 'comida':
        return Colors.orange;
      case 'transporte':
        return Colors.blue;
      case 'ocio':
        return Colors.purple;
      case 'servicios':
        return Colors.green;
      case 'ropa':
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String categoria) {
    switch (categoria.toLowerCase()) {
      case 'comida':
        return Icons.restaurant;
      case 'transporte':
        return Icons.directions_car;
      case 'ocio':
        return Icons.movie;
      case 'servicios':
        return Icons.home;
      case 'ropa':
        return Icons.checkroom;
      default:
        return Icons.category;
    }
  }
}
