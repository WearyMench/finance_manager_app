import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/income.dart';
import '../db/database_helper.dart';

class EditIncomePage extends StatefulWidget {
  final Income income;
  final List<String> categories;
  const EditIncomePage({
    super.key,
    required this.income,
    required this.categories,
  });

  @override
  State<EditIncomePage> createState() => _EditIncomePageState();
}

class _EditIncomePageState extends State<EditIncomePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final DatabaseHelper _dbHelper = DatabaseHelper();

  late List<String> _categories;
  String _selectedCategory = '';
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _categories = widget.categories;
    _loadIncomeData();
  }

  void _loadIncomeData() {
    _nameController.text = widget.income.nombre;
    _amountController.text = widget.income.monto.toString();
    _selectedCategory = widget.income.categoria;
    _selectedDate = widget.income.fecha;
    _noteController.text = widget.income.nota ?? '';
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

  Future<void> _updateIncome() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
    });
    try {
      final amount = double.parse(_amountController.text.replaceAll(',', '.'));
      final updatedIncome = widget.income.copyWith(
        nombre: _nameController.text.trim(),
        monto: amount,
        categoria: _selectedCategory,
        fecha: _selectedDate,
        nota: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
      );
      await _dbHelper.updateIncome(updatedIncome);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ingreso actualizado correctamente')),
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
        title: const Text('Editar Ingreso'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
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
                labelText: 'Nombre del ingreso',
                hintText: 'Ej: Sueldo, venta, regalo',
                prefixIcon: const Icon(Icons.attach_money),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Por favor ingresa el nombre del ingreso';
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
                prefixIcon: const Icon(Icons.monetization_on),
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
                  child: Text(category),
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
                hintText: 'Ej: Pago extra, bono, etc.',
                prefixIcon: const Icon(Icons.note_alt),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _updateIncome,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
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
                      'Actualizar Ingreso',
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
