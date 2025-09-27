import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../models/api_models.dart' as api_models;
import '../models/api_models.dart';
import '../theme/app_theme.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/error_message.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _editCategoryController = TextEditingController();

  String _selectedType = 'expense';
  String _selectedColor = '#6B7280';
  String _selectedIcon = 'category';
  String _editingCategoryId = '';

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  bool _isAdding = false;
  bool _isEditing = false;

  final List<String> _colors = [
    '#6B7280', // Gray
    '#EF4444', // Red
    '#F59E0B', // Amber
    '#10B981', // Emerald
    '#3B82F6', // Blue
    '#8B5CF6', // Violet
    '#EC4899', // Pink
    '#F97316', // Orange
  ];

  final List<String> _icons = [
    'category',
    'shopping_cart',
    'restaurant',
    'local_gas_station',
    'home',
    'work',
    'school',
    'favorite',
    'sports',
    'medical_services',
    'flight',
    'car_rental',
    'pets',
    'child_care',
    'elderly',
    'savings',
  ];

  @override
  void dispose() {
    _categoryController.dispose();
    _editCategoryController.dispose();
    super.dispose();
  }

  Future<void> _addCategory() async {
    if (_categoryController.text.trim().isEmpty) {
      _showError('El nombre de la categoría es requerido');
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

      final success = await transactionProvider.createCategory(
        name: _categoryController.text.trim(),
        type: _selectedType,
        color: _selectedColor,
        icon: _selectedIcon,
      );

      if (success) {
        setState(() {
          _isLoading = false;
          _isAdding = false;
          _successMessage = 'Categoría agregada correctamente';
          _categoryController.clear();
          _selectedType = 'expense';
          _selectedColor = '#6B7280';
          _selectedIcon = 'category';
        });

        // Clear success message after 3 seconds
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _successMessage = null;
            });
          }
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage =
              transactionProvider.error ?? 'Error al agregar la categoría';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error al agregar la categoría: $e';
      });
    }
  }

  Future<void> _editCategory(api_models.Category category) async {
    _editCategoryController.text = category.name;
    _selectedType = category.type;
    _selectedColor = category.color;
    _selectedIcon = category.icon;
    _editingCategoryId = category.id;

    setState(() {
      _isEditing = true;
      _errorMessage = null;
      _successMessage = null;
    });
  }

  Future<void> _updateCategory() async {
    if (_editCategoryController.text.trim().isEmpty) {
      _showError('El nombre de la categoría es requerido');
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

      final success = await transactionProvider.updateCategory(
        _editingCategoryId,
        name: _editCategoryController.text.trim(),
        type: _selectedType,
        color: _selectedColor,
        icon: _selectedIcon,
      );

      if (success) {
        setState(() {
          _isLoading = false;
          _isEditing = false;
          _successMessage = 'Categoría actualizada correctamente';
          _editCategoryController.clear();
          _selectedType = 'expense';
          _selectedColor = '#6B7280';
          _selectedIcon = 'category';
          _editingCategoryId = '';
        });

        // Clear success message after 3 seconds
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _successMessage = null;
            });
          }
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage =
              transactionProvider.error ?? 'Error al actualizar la categoría';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error al actualizar la categoría: $e';
      });
    }
  }

  Future<void> _deleteCategory(String categoryId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text(
          'Eliminar Categoría',
          style: TextStyle(
            color:
                Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          '¿Estás seguro de que quieres eliminar esta categoría?',
          style: TextStyle(
            color:
                Theme.of(context).textTheme.bodyMedium?.color ??
                Colors.grey[600],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancelar',
              style: TextStyle(
                color:
                    Theme.of(context).textTheme.bodyMedium?.color ??
                    Colors.grey[600],
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
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

        final success = await transactionProvider.deleteCategory(categoryId);

        if (success) {
          setState(() {
            _isLoading = false;
            _successMessage = 'Categoría eliminada correctamente';
          });

          // Clear success message after 3 seconds
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) {
              setState(() {
                _successMessage = null;
              });
            }
          });
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage =
                transactionProvider.error ?? 'Error al eliminar la categoría';
          });
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error al eliminar la categoría: $e';
        });
      }
    }
  }

  void _cancelEditing() {
    setState(() {
      _isAdding = false;
      _isEditing = false;
      _categoryController.clear();
      _editCategoryController.clear();
      _selectedType = 'expense';
      _selectedColor = '#6B7280';
      _selectedIcon = 'category';
      _editingCategoryId = '';
      _errorMessage = null;
      _successMessage = null;
    });
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
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Categorías',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            Text(
              'Gestiona tus categorías de transacciones',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.8),
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_isAdding || _isEditing)
            Container(
              margin: const EdgeInsets.only(right: 16),
              child: TextButton(
                onPressed: _isLoading ? null : _cancelEditing,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Cancelar'),
              ),
            )
          else ...[
            Container(
              margin: const EdgeInsets.only(right: 16),
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _isAdding = true;
                    _clearMessages();
                  });
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Agregar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Theme.of(context).primaryColor,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        message: _isAdding
            ? 'Agregando categoría...'
            : _isEditing
            ? 'Actualizando categoría...'
            : 'Eliminando categoría...',
        child: Column(
          children: [
            // Success message
            if (_successMessage != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _successMessage!,
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _clearMessages,
                      icon: Icon(Icons.close, color: Colors.green, size: 18),
                    ),
                  ],
                ),
              ),

            // Error message
            if (_errorMessage != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error, color: Colors.red, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _clearMessages,
                      icon: Icon(Icons.close, color: Colors.red, size: 18),
                    ),
                  ],
                ),
              ),

            // Add/Edit Form
            if (_isAdding || _isEditing)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
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
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.getPrimaryColor(
                              context,
                            ).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _isAdding ? Icons.add_circle : Icons.edit,
                            color: Theme.of(context).primaryColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _isAdding
                              ? 'Agregar Nueva Categoría'
                              : 'Editar Categoría',
                          style: TextStyle(
                            color:
                                Theme.of(context).textTheme.bodyLarge?.color ??
                                Colors.black87,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Category Name
                    TextFormField(
                      controller: _isAdding
                          ? _categoryController
                          : _editCategoryController,
                      decoration: InputDecoration(
                        labelText: 'Nombre de la Categoría',
                        hintText: 'Ej: Comida, Transporte, etc.',
                        prefixIcon: Icon(
                          Icons.category,
                          color: Theme.of(context).primaryColor,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Theme.of(context).dividerColor,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Theme.of(context).dividerColor,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Theme.of(context).primaryColor,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: Theme.of(context).scaffoldBackgroundColor,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Category Type
                    DropdownButtonFormField<String>(
                      value: _selectedType,
                      decoration: InputDecoration(
                        labelText: 'Tipo de Categoría',
                        prefixIcon: Icon(
                          Icons.type_specimen,
                          color: Theme.of(context).primaryColor,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Theme.of(context).dividerColor,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Theme.of(context).dividerColor,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Theme.of(context).primaryColor,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: Theme.of(context).scaffoldBackgroundColor,
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'expense',
                          child: Text('Gasto'),
                        ),
                        DropdownMenuItem(
                          value: 'income',
                          child: Text('Ingreso'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedType = value ?? 'expense';
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Color Selection
                    Text(
                      'Color',
                      style: TextStyle(
                        color:
                            Theme.of(context).textTheme.bodyLarge?.color ??
                            Colors.black87,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _colors.map((color) {
                        final isSelected = _selectedColor == color;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedColor = color;
                            });
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Color(
                                int.parse(color.substring(1), radix: 16) +
                                    0xFF000000,
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? Theme.of(context).primaryColor
                                    : Colors.transparent,
                                width: 3,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 20,
                                  )
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Icon Selection
                    Text(
                      'Icono',
                      style: TextStyle(
                        color:
                            Theme.of(context).textTheme.bodyLarge?.color ??
                            Colors.black87,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _icons.map((icon) {
                        final isSelected = _selectedIcon == icon;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedIcon = icon;
                            });
                          },
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Theme.of(context).primaryColor
                                  : Theme.of(
                                      context,
                                    ).dividerColor.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? Theme.of(context).primaryColor
                                    : Theme.of(context).dividerColor,
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              _getIconData(icon),
                              color: isSelected
                                  ? Colors.white
                                  : Theme.of(
                                          context,
                                        ).textTheme.bodyMedium?.color ??
                                        Colors.grey[600],
                              size: 24,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isLoading ? null : _cancelEditing,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.getTextSecondaryColor(
                                context,
                              ),
                              side: BorderSide(
                                color: Theme.of(context).dividerColor,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('Cancelar'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading
                                ? null
                                : _isAdding
                                ? _addCategory
                                : _updateCategory,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.getPrimaryColor(
                                context,
                              ),
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
                                : Text(_isAdding ? 'Agregar' : 'Actualizar'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            // Categories List
            Expanded(
              child: Consumer<TransactionProvider>(
                builder: (context, transactionProvider, child) {
                  if (transactionProvider.isLoading) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).primaryColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Cargando categorías...',
                            style: TextStyle(
                              color:
                                  Theme.of(
                                    context,
                                  ).textTheme.bodyMedium?.color ??
                                  Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (transactionProvider.error != null) {
                    return ErrorMessage(
                      message: transactionProvider.getErrorMessage(),
                      onRetry: () => transactionProvider.loadData(),
                    );
                  }

                  final categories = transactionProvider.categories;

                  if (categories.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.category_outlined,
                            size: 64,
                            color:
                                Theme.of(context).textTheme.bodyMedium?.color ??
                                Colors.grey[600],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No hay categorías',
                            style: TextStyle(
                              color:
                                  Theme.of(
                                    context,
                                  ).textTheme.bodyLarge?.color ??
                                  Colors.black87,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Agrega tu primera categoría para comenzar',
                            style: TextStyle(
                              color:
                                  Theme.of(
                                    context,
                                  ).textTheme.bodyMedium?.color ??
                                  Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Separar categorías por tipo
                  final incomeCategories = categories
                      .where((cat) => cat.type == 'income')
                      .toList();
                  final expenseCategories = categories
                      .where((cat) => cat.type == 'expense')
                      .toList();

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Categorías de Gastos
                        if (expenseCategories.isNotEmpty) ...[
                          _buildCategorySection(
                            context,
                            'Gastos',
                            Icons.trending_down,
                            (Theme.of(context).textTheme.bodyMedium?.color ??
                                Colors.grey[600])!,
                            expenseCategories,
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Categorías de Ingresos
                        if (incomeCategories.isNotEmpty) ...[
                          _buildCategorySection(
                            context,
                            'Ingresos',
                            Icons.trending_up,
                            (Theme.of(context).textTheme.bodyMedium?.color ??
                                Colors.grey[600])!,
                            incomeCategories,
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'shopping_cart':
        return Icons.shopping_cart;
      case 'restaurant':
        return Icons.restaurant;
      case 'local_gas_station':
        return Icons.local_gas_station;
      case 'home':
        return Icons.home;
      case 'work':
        return Icons.work;
      case 'school':
        return Icons.school;
      case 'favorite':
        return Icons.favorite;
      case 'sports':
        return Icons.sports;
      case 'medical_services':
        return Icons.medical_services;
      case 'flight':
        return Icons.flight;
      case 'car_rental':
        return Icons.car_rental;
      case 'pets':
        return Icons.pets;
      case 'child_care':
        return Icons.child_care;
      case 'elderly':
        return Icons.elderly;
      case 'savings':
        return Icons.savings;
      default:
        return Icons.category;
    }
  }

  Widget _buildCategorySection(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    List<Category> categories,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header de la sección
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3), width: 1),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${categories.length}',
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Lista de categorías
        ...categories.map((category) => _buildCategoryCard(context, category)),
      ],
    );
  }

  Widget _buildCategoryCard(BuildContext context, Category category) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icono de la categoría
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Color(
                int.parse(category.color.substring(1), radix: 16) + 0xFF000000,
              ).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _getIconData(category.icon),
              color: Color(
                int.parse(category.color.substring(1), radix: 16) + 0xFF000000,
              ),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),

          // Información de la categoría
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.name,
                  style: TextStyle(
                    color:
                        Theme.of(context).textTheme.bodyLarge?.color ??
                        Colors.black87,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  category.type == 'income' ? 'Ingreso' : 'Gasto',
                  style: TextStyle(
                    color:
                        Theme.of(context).textTheme.bodyMedium?.color ??
                        Colors.grey[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Botones de acción
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () => _editCategory(category),
                icon: Icon(
                  Icons.edit_outlined,
                  color: Theme.of(context).primaryColor,
                  size: 18,
                ),
                tooltip: 'Editar',
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
              ),
              IconButton(
                onPressed: () => _deleteCategory(category.id),
                icon: Icon(Icons.delete_outline, color: Colors.red, size: 18),
                tooltip: 'Eliminar',
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
