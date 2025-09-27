import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../models/expense_template.dart';
import '../db/database_helper.dart';
import '../utils/app_colors.dart';

class AddExpensePage extends StatefulWidget {
  final List<String> categories;
  const AddExpensePage({super.key, required this.categories});

  @override
  State<AddExpensePage> createState() => _AddExpensePageState();
}

class _AddExpensePageState extends State<AddExpensePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final DatabaseHelper _dbHelper = DatabaseHelper();

  late List<String> _categories;
  String _selectedCategory = 'Alimentación';
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
  List<ExpenseTemplate> _favoriteTemplates = [];

  @override
  void initState() {
    super.initState();
    _categories = widget.categories.toSet().toList(); // Remove duplicates
    _selectedCategory = _categories.isNotEmpty ? _categories.first : '';
    _loadFavoriteTemplates();
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

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final amount = double.parse(_amountController.text.replaceAll(',', '.'));

      final expense = Expense(
        nombre: _nameController.text.trim(),
        monto: amount,
        categoria: _selectedCategory,
        fecha: _selectedDate,
        nota: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        recurrente: _selectedRecurrence,
      );

      await _dbHelper.insertExpense(expense);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gasto guardado correctamente')),
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

  Future<void> _loadFavoriteTemplates() async {
    try {
      final templates = await _dbHelper.getFavoriteExpenseTemplates();
      setState(() {
        _favoriteTemplates = templates;
      });
    } catch (e) {
      // Silenciar error si no hay plantillas
    }
  }

  void _useTemplate(ExpenseTemplate template) {
    setState(() {
      _nameController.text = template.nombre;
      _amountController.text = template.monto.toString();
      _selectedCategory = template.categoria;
      _selectedRecurrence = template.recurrente ?? 'ninguna';
      _noteController.text = template.nota ?? '';
    });
  }

  void _showTemplatesDialog() {
    if (_favoriteTemplates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No hay plantillas favoritas. Crea algunas plantillas primero.',
          ),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Usar Plantilla'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _favoriteTemplates.length,
            itemBuilder: (context, index) {
              final template = _favoriteTemplates[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getCategoryColor(template.categoria),
                  child: Icon(
                    _getCategoryIcon(template.categoria),
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                title: Text(template.nombre),
                subtitle: Text(
                  '${template.categoria} • ${NumberFormat.currency(locale: 'es_MX', symbol: '\$').format(template.monto)}',
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.of(context).pop();
                  _useTemplate(template);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agregar Gasto'),
        elevation: 0,
        backgroundColor: AppColors.getPrimaryColor(context),
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.getPrimaryColor(context).withOpacity(0.1),
              Colors.transparent,
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Botón para usar plantillas
                if (_favoriteTemplates.isNotEmpty)
                  Card(
                    elevation: 2,
                    color: AppColors.getCardColor(context),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.getInfoColor(context),
                        child: const Icon(
                          Icons.assignment,
                          color: Colors.white,
                        ),
                      ),
                      title: Text(
                        'Usar Plantilla',
                        style: TextStyle(
                          color: AppColors.getTextPrimaryColor(context),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        'Selecciona una plantilla favorita',
                        style: TextStyle(
                          color: AppColors.getTextSecondaryColor(context),
                        ),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: _showTemplatesDialog,
                    ),
                  ),
                if (_favoriteTemplates.isNotEmpty) const SizedBox(height: 16),

                // Campo de nombre
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
                          'Nombre del gasto',
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
                            hintText: 'Ej: Comida del día',
                            filled: true,
                            fillColor: AppColors.getInputBackgroundColor(
                              context,
                            ),
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
                                color: AppColors.getPrimaryColor(context),
                                width: 2,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Por favor ingresa un nombre';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Campo de monto
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
                              Icons.attach_money,
                              color: AppColors.getTextSecondaryColor(context),
                            ),
                            filled: true,
                            fillColor: AppColors.getInputBackgroundColor(
                              context,
                            ),
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
                                color: AppColors.getPrimaryColor(context),
                                width: 2,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Por favor ingresa un monto';
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

                // Campo de categoría
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
                            filled: true,
                            fillColor: AppColors.getInputBackgroundColor(
                              context,
                            ),
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
                                color: AppColors.getPrimaryColor(context),
                                width: 2,
                              ),
                            ),
                          ),
                          items: _categories.map((category) {
                            return DropdownMenuItem(
                              value: category,
                              child: Row(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: AppColors.getCategoryColor(
                                        category,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    category,
                                    style: TextStyle(
                                      color: AppColors.getTextPrimaryColor(
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
                              _selectedCategory = value!;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Campo de fecha
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
                                  color: AppColors.getTextSecondaryColor(
                                    context,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  DateFormat(
                                    'dd/MM/yyyy',
                                  ).format(_selectedDate),
                                  style: TextStyle(
                                    color: AppColors.getTextPrimaryColor(
                                      context,
                                    ),
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

                // Campo de recurrencia
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
                          'Recurrencia',
                          style: TextStyle(
                            color: AppColors.getTextPrimaryColor(context),
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: _recurrenceOptions.map((option) {
                            final isSelected = _selectedRecurrence == option;
                            return ChoiceChip(
                              label: Text(
                                option == 'ninguna' ? 'Ninguna' : option,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.getTextPrimaryColor(context),
                                ),
                              ),
                              selected: isSelected,
                              selectedColor: AppColors.getRecurrenceColor(
                                option,
                              ),
                              backgroundColor:
                                  AppColors.getInputBackgroundColor(context),
                              onSelected: (selected) {
                                setState(() {
                                  _selectedRecurrence = option;
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Campo de nota
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
                            fillColor: AppColors.getInputBackgroundColor(
                              context,
                            ),
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
                                color: AppColors.getPrimaryColor(context),
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
                      colors: AppColors.getInfoGradient(context),
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.getInfoColor(context).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveExpense,
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
                            'Guardar Gasto',
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
      ),
    );
  }

  Color _getCategoryColor(String categoria) {
    return AppColors.getCategoryColor(categoria);
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
