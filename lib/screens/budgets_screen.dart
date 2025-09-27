import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import '../models/api_models.dart' as api_models;
import '../models/api_models.dart';
import '../theme/app_theme.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/error_message.dart';

class BudgetsScreen extends StatefulWidget {
  const BudgetsScreen({super.key});

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> {
  final TextEditingController _amountController = TextEditingController();
  String _selectedCategory = '';
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  bool _isAdding = false;
  bool _isEditing = false;
  String? _editingBudgetId;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _addBudget() async {
    if (_amountController.text.trim().isEmpty) {
      _showError('El monto del presupuesto es requerido');
      return;
    }

    if (_selectedCategory.isEmpty) {
      _showError('La categoría es requerida');
      return;
    }

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      _showError('El monto debe ser un número válido mayor a 0');
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

      // Find the category ID
      final category = transactionProvider.categories.firstWhere(
        (c) => c.name == _selectedCategory,
        orElse: () => transactionProvider.categories.first,
      );

      final success = await transactionProvider.createBudget(
        categoryId: category.id,
        amount: amount,
        period: 'monthly',
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 30)),
      );

      if (success) {
        setState(() {
          _isLoading = false;
          _isAdding = false;
          _successMessage = 'Presupuesto agregado correctamente';
          _amountController.clear();
          _selectedCategory = '';
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
              transactionProvider.error ?? 'Error al agregar el presupuesto';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error al agregar el presupuesto: $e';
      });
    }
  }

  Future<void> _editBudget(api_models.Budget budget) async {
    _amountController.text = budget.amount.toString();
    _selectedCategory = budget.category.name;
    _editingBudgetId = budget.id;

    setState(() {
      _isEditing = true;
      _errorMessage = null;
      _successMessage = null;
    });
  }

  Future<void> _updateBudget() async {
    if (_amountController.text.trim().isEmpty) {
      _showError('El monto del presupuesto es requerido');
      return;
    }

    if (_selectedCategory.isEmpty) {
      _showError('La categoría es requerida');
      return;
    }

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      _showError('El monto debe ser un número válido mayor a 0');
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

      // Find the category ID
      final category = transactionProvider.categories.firstWhere(
        (c) => c.name == _selectedCategory,
        orElse: () => transactionProvider.categories.first,
      );

      final success = await transactionProvider.updateBudget(
        _editingBudgetId!,
        categoryId: category.id,
        amount: amount,
      );

      if (success) {
        setState(() {
          _isLoading = false;
          _isEditing = false;
          _successMessage = 'Presupuesto actualizado correctamente';
          _amountController.clear();
          _selectedCategory = '';
          _editingBudgetId = null;
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
              transactionProvider.error ?? 'Error al actualizar el presupuesto';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error al actualizar el presupuesto: $e';
      });
    }
  }

  Future<void> _deleteBudget(String budgetId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.getSurfaceColor(context),
        title: Text(
          'Eliminar Presupuesto',
          style: TextStyle(
            color: AppTheme.getTextPrimaryColor(context),
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          '¿Estás seguro de que quieres eliminar este presupuesto?',
          style: TextStyle(color: AppTheme.getTextSecondaryColor(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancelar',
              style: TextStyle(color: AppTheme.getTextSecondaryColor(context)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.getErrorColor(context),
            ),
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

        final success = await transactionProvider.deleteBudget(budgetId);

        if (success) {
          setState(() {
            _isLoading = false;
            _successMessage = 'Presupuesto eliminado correctamente';
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
                transactionProvider.error ?? 'Error al eliminar el presupuesto';
          });
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error al eliminar el presupuesto: $e';
        });
      }
    }
  }

  void _cancelEditing() {
    setState(() {
      _isAdding = false;
      _isEditing = false;
      _amountController.clear();
      _selectedCategory = '';
      _editingBudgetId = null;
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
      backgroundColor: AppTheme.getBackgroundColor(context),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Presupuestos',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            Text(
              'Gestiona tus límites de gasto',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.8),
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.getPrimaryColor(context),
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
          else
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
                  foregroundColor: AppTheme.getPrimaryColor(context),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        message: _isAdding
            ? 'Agregando presupuesto...'
            : _isEditing
            ? 'Actualizando presupuesto...'
            : 'Eliminando presupuesto...',
        child: Column(
          children: [
            // Success message
            if (_successMessage != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.getSuccessColor(context).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.getSuccessColor(context).withOpacity(0.3),
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
                margin: const EdgeInsets.all(16),
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

            // Add/Edit Form
            if (_isAdding || _isEditing)
              Container(
                margin: const EdgeInsets.all(16),
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
                            color: AppTheme.getPrimaryColor(context),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _isAdding
                              ? 'Agregar Nuevo Presupuesto'
                              : 'Editar Presupuesto',
                          style: TextStyle(
                            color: AppTheme.getTextPrimaryColor(context),
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Category Selection
                    Consumer<TransactionProvider>(
                      builder: (context, transactionProvider, child) {
                        final expenseCategories = transactionProvider.categories
                            .where((cat) => cat.type == 'expense')
                            .toList();

                        return DropdownButtonFormField<String>(
                          value: _selectedCategory.isEmpty
                              ? null
                              : _selectedCategory,
                          decoration: InputDecoration(
                            labelText: 'Categoría',
                            hintText: 'Selecciona una categoría',
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
                          items: expenseCategories.map((category) {
                            return DropdownMenuItem<String>(
                              value: category.name,
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
                              _selectedCategory = value ?? '';
                            });
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Amount Input
                    TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Monto del Presupuesto',
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
                                color: AppTheme.getBorderColor(context),
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
                                ? _addBudget
                                : _updateBudget,
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

            // Budgets List
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
                              AppTheme.getPrimaryColor(context),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Cargando presupuestos...',
                            style: TextStyle(
                              color: AppTheme.getTextSecondaryColor(context),
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

                  final budgets = transactionProvider.budgets;

                  if (budgets.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.account_balance_wallet_outlined,
                            size: 64,
                            color: AppTheme.getTextSecondaryColor(context),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No hay presupuestos',
                            style: TextStyle(
                              color: AppTheme.getTextPrimaryColor(context),
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Agrega tu primer presupuesto para comenzar',
                            style: TextStyle(
                              color: AppTheme.getTextSecondaryColor(context),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Resumen de presupuestos
                        _buildBudgetSummary(context, budgets),
                        const SizedBox(height: 24),

                        // Lista de presupuestos
                        _buildBudgetsList(context, budgets),
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

  Widget _buildBudgetSummary(BuildContext context, List<Budget> budgets) {
    final totalBudget = budgets.fold<double>(
      0,
      (sum, budget) => sum + budget.amount,
    );
    final totalSpent = budgets.fold<double>(
      0,
      (sum, budget) => sum + budget.spent,
    );
    final remaining = totalBudget - totalSpent;
    final percentage = totalBudget > 0 ? (totalSpent / totalBudget) * 100 : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.getPrimaryColor(context).withOpacity(0.1),
            AppTheme.getPrimaryColor(context).withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.getPrimaryColor(context).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_balance_wallet,
                color: AppTheme.getPrimaryColor(context),
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Resumen de Presupuestos',
                style: TextStyle(
                  color: AppTheme.getTextPrimaryColor(context),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Estadísticas
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  context,
                  'Total Presupuestado',
                  NumberFormat.currency(
                    locale: 'es_MX',
                    symbol: 'RD\$',
                  ).format(totalBudget),
                  Icons.account_balance_wallet_outlined,
                  AppTheme.getPrimaryColor(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  context,
                  'Total Gastado',
                  NumberFormat.currency(
                    locale: 'es_MX',
                    symbol: 'RD\$',
                  ).format(totalSpent),
                  Icons.trending_down,
                  AppTheme.getErrorColor(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  context,
                  'Restante',
                  NumberFormat.currency(
                    locale: 'es_MX',
                    symbol: 'RD\$',
                  ).format(remaining),
                  Icons.savings,
                  remaining >= 0
                      ? AppTheme.getSuccessColor(context)
                      : AppTheme.getErrorColor(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  context,
                  'Progreso',
                  '${percentage.toStringAsFixed(1)}%',
                  Icons.trending_up,
                  AppTheme.getWarningColor(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: AppTheme.getTextSecondaryColor(context),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetsList(BuildContext context, List<Budget> budgets) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Presupuestos Activos',
          style: TextStyle(
            color: AppTheme.getTextPrimaryColor(context),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),

        ...budgets.map((budget) => _buildBudgetCard(context, budget)),
      ],
    );
  }

  Widget _buildBudgetCard(BuildContext context, Budget budget) {
    final amount = budget.amount;
    final spent = budget.spent;
    final percentage = amount > 0 ? (spent / amount) * 100 : 0.0;
    final isOverBudget = spent > amount;
    final remaining = amount - spent;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.getBorderColor(context), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con categoría y botones
          Row(
            children: [
              // Icono de categoría
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Color(
                    int.parse(budget.category.color.substring(1), radix: 16) +
                        0xFF000000,
                  ).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _getIconData(budget.category.icon),
                  color: Color(
                    int.parse(budget.category.color.substring(1), radix: 16) +
                        0xFF000000,
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
                      budget.category.name,
                      style: TextStyle(
                        color: AppTheme.getTextPrimaryColor(context),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Presupuesto mensual',
                      style: TextStyle(
                        color: AppTheme.getTextSecondaryColor(context),
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
                    onPressed: () => _editBudget(budget),
                    icon: Icon(
                      Icons.edit_outlined,
                      color: AppTheme.getPrimaryColor(context),
                      size: 18,
                    ),
                    tooltip: 'Editar',
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  IconButton(
                    onPressed: () => _deleteBudget(budget.id),
                    icon: Icon(
                      Icons.delete_outline,
                      color: AppTheme.getErrorColor(context),
                      size: 18,
                    ),
                    tooltip: 'Eliminar',
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Barra de progreso
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Progreso',
                    style: TextStyle(
                      color: AppTheme.getTextSecondaryColor(context),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: isOverBudget
                          ? AppTheme.getErrorColor(context)
                          : AppTheme.getTextSecondaryColor(context),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              LinearProgressIndicator(
                value: percentage / 100,
                backgroundColor: AppTheme.getBorderColor(context),
                valueColor: AlwaysStoppedAnimation<Color>(
                  isOverBudget
                      ? AppTheme.getErrorColor(context)
                      : AppTheme.getPrimaryColor(context),
                ),
                minHeight: 6,
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Montos
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Presupuestado',
                      style: TextStyle(
                        color: AppTheme.getTextSecondaryColor(context),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      NumberFormat.currency(
                        locale: 'es_MX',
                        symbol: 'RD\$',
                      ).format(amount),
                      style: TextStyle(
                        color: AppTheme.getTextPrimaryColor(context),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gastado',
                      style: TextStyle(
                        color: AppTheme.getTextSecondaryColor(context),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      NumberFormat.currency(
                        locale: 'es_MX',
                        symbol: 'RD\$',
                      ).format(spent),
                      style: TextStyle(
                        color: AppTheme.getErrorColor(context),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Restante',
                      style: TextStyle(
                        color: AppTheme.getTextSecondaryColor(context),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      NumberFormat.currency(
                        locale: 'es_MX',
                        symbol: 'RD\$',
                      ).format(remaining),
                      style: TextStyle(
                        color: remaining >= 0
                            ? AppTheme.getSuccessColor(context)
                            : AppTheme.getErrorColor(context),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
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
}
