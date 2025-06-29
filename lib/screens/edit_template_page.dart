import 'package:flutter/material.dart';
import '../models/expense_template.dart';
import '../db/database_helper.dart';

class EditTemplatePage extends StatefulWidget {
  final ExpenseTemplate template;
  const EditTemplatePage({super.key, required this.template});

  @override
  State<EditTemplatePage> createState() => _EditTemplatePageState();
}

class _EditTemplatePageState extends State<EditTemplatePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final DatabaseHelper _dbHelper = DatabaseHelper();

  late List<String> _categories;
  String _selectedCategory = '';
  bool _isLoading = false;
  String _selectedRecurrence = 'ninguna';
  bool _isFavorite = false;
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
    _loadCategories();
    _loadTemplateData();
  }

  Future<void> _loadCategories() async {
    _categories = [
      'Comida',
      'Transporte',
      'Ocio',
      'Servicios',
      'Ropa',
      'Otros',
    ];
  }

  void _loadTemplateData() {
    _nameController.text = widget.template.nombre;
    _amountController.text = widget.template.monto.toString();
    _selectedCategory = widget.template.categoria;
    _selectedRecurrence = widget.template.recurrente ?? 'ninguna';
    _isFavorite = widget.template.favorito;
    _noteController.text = widget.template.nota ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _updateTemplate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final amount = double.parse(_amountController.text.replaceAll(',', '.'));
      final updatedTemplate = widget.template.copyWith(
        nombre: _nameController.text.trim(),
        monto: amount,
        categoria: _selectedCategory,
        nota: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        recurrente: _selectedRecurrence,
        favorito: _isFavorite,
      );

      await _dbHelper.updateExpenseTemplate(updatedTemplate);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Plantilla actualizada correctamente')),
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
        title: const Text('Editar Plantilla'),
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
                labelText: 'Nombre de la plantilla',
                hintText: 'Ej: Almuerzo en restaurante',
                prefixIcon: const Icon(Icons.edit),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Por favor ingresa el nombre de la plantilla';
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
            const SizedBox(height: 16),

            // Checkbox Favorito
            CheckboxListTile(
              title: const Text('Marcar como favorita'),
              subtitle: const Text(
                'Aparecerá en la parte superior de la lista',
              ),
              value: _isFavorite,
              onChanged: (value) {
                setState(() {
                  _isFavorite = value ?? false;
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: Colors.amber,
            ),
            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: _isLoading ? null : _updateTemplate,
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
                      'Actualizar Plantilla',
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
