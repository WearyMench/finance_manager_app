import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/income.dart';
import '../db/database_helper.dart';
import '../utils/app_colors.dart';

class AddIncomePage extends StatefulWidget {
  final List<String> categories;
  const AddIncomePage({super.key, required this.categories});

  @override
  State<AddIncomePage> createState() => _AddIncomePageState();
}

class _AddIncomePageState extends State<AddIncomePage> {
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
    _selectedCategory = _categories.isNotEmpty ? _categories.first : '';
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

  Future<void> _saveIncome() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
    });
    try {
      final amount = double.parse(_amountController.text.replaceAll(',', '.'));
      final income = Income(
        nombre: _nameController.text.trim(),
        monto: amount,
        categoria: _selectedCategory,
        fecha: _selectedDate,
        nota: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
      );
      await _dbHelper.insertIncome(income);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ingreso guardado correctamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
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
      backgroundColor: AppColors.getBackgroundColor(context),
      appBar: AppBar(
        title: const Text('Agregar Ingreso'),
        backgroundColor: AppColors.getSuccessColor(context),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.getSuccessColor(context).withOpacity(0.1),
              Colors.transparent,
            ],
          ),
        ),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Campo Nombre
              Card(
                elevation: 2,
                color: AppColors.getCardColor(context),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nombre del ingreso',
                        style: TextStyle(
                          color: AppColors.getTextPrimaryColor(context),
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          hintText: 'Ej: Sueldo, venta, regalo',
                          prefixIcon: Icon(
                            Icons.attach_money,
                            color: AppColors.getTextSecondaryColor(context),
                          ),
                          filled: true,
                          fillColor: AppColors.getInputBackgroundColor(context),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: AppColors.getInputBorderColor(context),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: AppColors.getInputBorderColor(context),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: AppColors.getSuccessColor(context),
                              width: 2,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Por favor ingresa el nombre del ingreso';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Campo Monto
              Card(
                elevation: 2,
                color: AppColors.getCardColor(context),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Monto',
                        style: TextStyle(
                          color: AppColors.getTextPrimaryColor(context),
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: '0.00',
                          prefixIcon: Icon(
                            Icons.monetization_on,
                            color: AppColors.getTextSecondaryColor(context),
                          ),
                          filled: true,
                          fillColor: AppColors.getInputBackgroundColor(context),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: AppColors.getInputBorderColor(context),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: AppColors.getInputBorderColor(context),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: AppColors.getSuccessColor(context),
                              width: 2,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Por favor ingresa el monto';
                          }
                          final amount = double.tryParse(
                            value.replaceAll(',', '.'),
                          );
                          if (amount == null || amount <= 0) {
                            return 'Por favor ingresa un monto válido';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Selector de Categoría
              Card(
                elevation: 2,
                color: AppColors.getCardColor(context),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Categoría',
                        style: TextStyle(
                          color: AppColors.getTextPrimaryColor(context),
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: InputDecoration(
                          prefixIcon: Icon(
                            Icons.category,
                            color: AppColors.getTextSecondaryColor(context),
                          ),
                          filled: true,
                          fillColor: AppColors.getInputBackgroundColor(context),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: AppColors.getInputBorderColor(context),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: AppColors.getInputBorderColor(context),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: AppColors.getSuccessColor(context),
                              width: 2,
                            ),
                          ),
                        ),
                        items: _categories.map((String category) {
                          return DropdownMenuItem<String>(
                            value: category,
                            child: Text(
                              category,
                              style: TextStyle(
                                color: AppColors.getTextPrimaryColor(context),
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedCategory = newValue!;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Selector de Fecha
              Card(
                elevation: 2,
                color: AppColors.getCardColor(context),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fecha',
                        style: TextStyle(
                          color: AppColors.getTextPrimaryColor(context),
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: _selectDate,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.getInputBackgroundColor(context),
                            border: Border.all(
                              color: AppColors.getInputBorderColor(context),
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                color: AppColors.getTextSecondaryColor(context),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                DateFormat('dd/MM/yyyy').format(_selectedDate),
                                style: TextStyle(
                                  color: AppColors.getTextPrimaryColor(context),
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Campo Nota
              Card(
                elevation: 2,
                color: AppColors.getCardColor(context),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nota (opcional)',
                        style: TextStyle(
                          color: AppColors.getTextPrimaryColor(context),
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _noteController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Agrega una nota o descripción...',
                          filled: true,
                          fillColor: AppColors.getInputBackgroundColor(context),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: AppColors.getInputBorderColor(context),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: AppColors.getInputBorderColor(context),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: AppColors.getSuccessColor(context),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Botón de guardar
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: AppColors.getSuccessGradient(context),
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.getSuccessColor(
                        context,
                      ).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveIncome,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    elevation: 0,
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
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          'Guardar Ingreso',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
