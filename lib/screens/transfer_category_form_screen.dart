import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/transfer_category.dart';
import '../services/api_service.dart';
import '../models/api_models.dart';

class TransferCategoryFormScreen extends StatefulWidget {
  final TransferCategory? category;

  const TransferCategoryFormScreen({super.key, this.category});

  @override
  State<TransferCategoryFormScreen> createState() =>
      _TransferCategoryFormScreenState();
}

class _TransferCategoryFormScreenState
    extends State<TransferCategoryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _colorController = TextEditingController();
  final ApiService _apiService = ApiService();

  String _selectedIcon = 'exchange';
  bool _isLoading = false;

  final List<Map<String, dynamic>> _availableIcons = [
    {'name': 'exchange', 'icon': Icons.swap_horiz, 'label': 'Intercambio'},
    {
      'name': 'credit-card',
      'icon': Icons.credit_card,
      'label': 'Tarjeta de Crédito',
    },
    {'name': 'piggy-bank', 'icon': Icons.savings, 'label': 'Ahorro'},
    {'name': 'trending-up', 'icon': Icons.trending_up, 'label': 'Inversión'},
    {'name': 'shopping-cart', 'icon': Icons.shopping_cart, 'label': 'Compras'},
    {'name': 'alert-circle', 'icon': Icons.warning, 'label': 'Emergencia'},
    {'name': 'refresh-cw', 'icon': Icons.refresh, 'label': 'Reembolso'},
    {'name': 'home', 'icon': Icons.home, 'label': 'Hogar'},
    {'name': 'car', 'icon': Icons.directions_car, 'label': 'Transporte'},
    {'name': 'restaurant', 'icon': Icons.restaurant, 'label': 'Comida'},
    {'name': 'medical', 'icon': Icons.medical_services, 'label': 'Salud'},
    {'name': 'school', 'icon': Icons.school, 'label': 'Educación'},
  ];

  final List<String> _predefinedColors = [
    '#EF4444', // Red
    '#F59E0B', // Orange
    '#F59E0B', // Yellow
    '#10B981', // Green
    '#06B6D4', // Cyan
    '#3B82F6', // Blue
    '#8B5CF6', // Purple
    '#EC4899', // Pink
    '#6B7280', // Gray
    '#374151', // Dark Gray
  ];

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      _nameController.text = widget.category!.name;
      _descriptionController.text = widget.category!.description ?? '';
      _colorController.text = widget.category!.color;
      _selectedIcon = widget.category!.icon;
    } else {
      _colorController.text = '#6B7280';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  Future<void> _saveCategory() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final categoryData = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        'color': _colorController.text.trim(),
        'icon': _selectedIcon,
        'isActive': true,
      };

      ApiResponse response;
      if (widget.category != null) {
        response = await _apiService.updateTransferCategory(
          widget.category!.id!,
          categoryData,
        );
      } else {
        response = await _apiService.createTransferCategory(categoryData);
      }

      if (response.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.category != null
                    ? 'Categoría actualizada exitosamente'
                    : 'Categoría creada exitosamente',
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${response.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar categoría: $e'),
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
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.category != null ? 'Editar Categoría' : 'Nueva Categoría',
        ),
        backgroundColor: Theme.of(context).primaryColor,
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
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Name field
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Nombre *',
                hintText: 'Ej: Pago de Deudas',
                prefixIcon: const Icon(Icons.label),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'El nombre es requerido';
                }
                if (value.trim().length < 2) {
                  return 'El nombre debe tener al menos 2 caracteres';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Description field
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Descripción',
                hintText: 'Descripción opcional de la categoría',
                prefixIcon: const Icon(Icons.description),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // Icon selection
            Text(
              'Icono',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1,
              ),
              itemCount: _availableIcons.length,
              itemBuilder: (context, index) {
                final iconData = _availableIcons[index];
                final isSelected = _selectedIcon == iconData['name'];

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedIcon = iconData['name'];
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).primaryColor.withOpacity(0.1)
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).primaryColor
                            : Colors.grey[300]!,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          iconData['icon'] as IconData,
                          color: isSelected
                              ? Theme.of(context).primaryColor
                              : Colors.grey[600],
                          size: 24,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          iconData['label'] as String,
                          style: TextStyle(
                            fontSize: 10,
                            color: isSelected
                                ? Theme.of(context).primaryColor
                                : Colors.grey[600],
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Color selection
            Text(
              'Color',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _predefinedColors.map((color) {
                final isSelected = _colorController.text == color;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _colorController.text = color;
                    });
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Color(int.parse(color.replaceFirst('#', '0xFF'))),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? Colors.black : Colors.grey[300]!,
                        width: isSelected ? 3 : 1,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 20)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Custom color input
            TextFormField(
              controller: _colorController,
              decoration: InputDecoration(
                labelText: 'Color personalizado',
                hintText: '#6B7280',
                prefixIcon: const Icon(Icons.palette),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[#0-9A-Fa-f]')),
                LengthLimitingTextInputFormatter(7),
              ],
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'El color es requerido';
                }
                if (!RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(value.trim())) {
                  return 'Formato de color inválido (ej: #6B7280)';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),

            // Save button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveCategory,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
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
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text(
                        widget.category != null ? 'Actualizar' : 'Crear',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
