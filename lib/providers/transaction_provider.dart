import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../models/api_models.dart' as api_models;

class TransactionProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<api_models.Transaction> _transactions = [];
  List<api_models.Category> _categories = [];
  List<api_models.Budget> _budgets = [];
  bool _isLoading = false;
  String? _error;

  List<api_models.Transaction> get transactions => _transactions;
  List<api_models.Category> get categories => _categories;
  List<api_models.Budget> get budgets => _budgets;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Filtered transactions
  List<api_models.Transaction> get incomeTransactions =>
      _transactions.where((t) => t.type == 'income').toList();

  List<api_models.Transaction> get expenseTransactions =>
      _transactions.where((t) => t.type == 'expense').toList();

  // Statistics
  double get totalIncome =>
      incomeTransactions.fold(0.0, (sum, t) => sum + t.amount);

  double get totalExpenses =>
      expenseTransactions.fold(0.0, (sum, t) => sum + t.amount);

  double get netBalance => totalIncome - totalExpenses;

  // Monthly statistics
  double get monthlyIncome {
    final now = DateTime.now();
    return incomeTransactions
        .where((t) => t.date.year == now.year && t.date.month == now.month)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get monthlyExpenses {
    final now = DateTime.now();
    return expenseTransactions
        .where((t) => t.date.year == now.year && t.date.month == now.month)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get monthlyBalance => monthlyIncome - monthlyExpenses;

  Future<void> loadData() async {
    // Don't show loading if we already have data
    if (_transactions.isNotEmpty && _categories.isNotEmpty) {
      return;
    }

    _setLoading(true);
    _error = null;

    try {
      // Load all data in parallel with reasonable limits
      final futures = await Future.wait([
        _apiService.getCategories(),
        _apiService.getTransactions(
          limit: 100,
        ), // Reduced limit for better performance
        _apiService.getBudgets(
          limit: 50,
        ), // Reduced limit for better performance
      ]);

      final categoriesResponse =
          futures[0] as api_models.ApiResponse<List<api_models.Category>>;
      final transactionsResponse =
          futures[1] as api_models.ApiResponse<List<api_models.Transaction>>;
      final budgetsResponse =
          futures[2] as api_models.ApiResponse<List<api_models.Budget>>;

      // Load categories
      if (categoriesResponse.success && categoriesResponse.data != null) {
        _categories = categoriesResponse.data!;
      } else {
        _error = categoriesResponse.message ?? 'Error al cargar categorías';
        _categories = _getDefaultCategories();
      }

      // Load transactions
      if (transactionsResponse.success && transactionsResponse.data != null) {
        _transactions = transactionsResponse.data!;
      } else {
        _error =
            transactionsResponse.message ?? 'Error al cargar transacciones';
      }

      // Load budgets
      if (budgetsResponse.success && budgetsResponse.data != null) {
        _budgets = budgetsResponse.data!;
      } else {
        _error = budgetsResponse.message ?? 'Error al cargar presupuestos';
      }
    } catch (e) {
      _error = 'Error de conexión: $e';
      _categories = _getDefaultCategories();
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> createTransaction({
    required String type,
    required double amount,
    required String description,
    required String category,
    required String paymentMethod,
    required DateTime date,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      final response = await _apiService.createTransaction(
        type: type,
        amount: amount,
        description: description,
        category: category,
        paymentMethod: paymentMethod,
        date: date,
      );

      if (response.success && response.data != null) {
        _transactions.insert(0, response.data!);
        notifyListeners();
        return true;
      } else {
        _error = response.message ?? 'Error al crear transacción';
        return false;
      }
    } catch (e) {
      _error = 'Error de conexión: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateTransaction(
    String id, {
    String? type,
    double? amount,
    String? description,
    String? category,
    String? paymentMethod,
    DateTime? date,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      final response = await _apiService.updateTransaction(
        id,
        type: type,
        amount: amount,
        description: description,
        category: category,
        paymentMethod: paymentMethod,
        date: date,
      );

      if (response.success && response.data != null) {
        final index = _transactions.indexWhere((t) => t.id == id);
        if (index != -1) {
          _transactions[index] = response.data!;
          notifyListeners();
        }
        return true;
      } else {
        _error = response.message ?? 'Error al actualizar transacción';
        return false;
      }
    } catch (e) {
      _error = 'Error de conexión: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteTransaction(String id) async {
    _setLoading(true);
    _error = null;

    try {
      final response = await _apiService.deleteTransaction(id);

      if (response.success) {
        _transactions.removeWhere((t) => t.id == id);
        notifyListeners();
        return true;
      } else {
        _error = response.message ?? 'Error al eliminar transacción';
        return false;
      }
    } catch (e) {
      _error = 'Error de conexión: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Helper methods for filtering
  List<api_models.Transaction> getTransactionsByType(String type) {
    return _transactions.where((t) => t.type == type).toList();
  }

  List<api_models.Transaction> getTransactionsByCategory(String categoryId) {
    return _transactions.where((t) => t.category == categoryId).toList();
  }

  List<api_models.Transaction> getTransactionsByDateRange(
    DateTime start,
    DateTime end,
  ) {
    return _transactions
        .where(
          (t) =>
              t.date.isAfter(start.subtract(const Duration(days: 1))) &&
              t.date.isBefore(end.add(const Duration(days: 1))),
        )
        .toList();
  }

  List<api_models.Transaction> searchTransactions(String query) {
    if (query.isEmpty) return _transactions;

    final lowercaseQuery = query.toLowerCase();
    return _transactions
        .where((t) => t.description.toLowerCase().contains(lowercaseQuery))
        .toList();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Category management methods
  Future<bool> createCategory({
    required String name,
    required String type,
    String? color,
    String? icon,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      final response = await _apiService.createCategory(
        name: name,
        type: type,
        color: color,
        icon: icon,
      );

      if (response.success && response.data != null) {
        _categories.add(response.data!);
        notifyListeners();
        return true;
      } else {
        _error = response.message ?? 'Error al crear la categoría';
        return false;
      }
    } catch (e) {
      _error = 'Error de conexión: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateCategory(
    String id, {
    String? name,
    String? type,
    String? color,
    String? icon,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      final response = await _apiService.updateCategory(
        id,
        name: name,
        type: type,
        color: color,
        icon: icon,
      );

      if (response.success && response.data != null) {
        final index = _categories.indexWhere((c) => c.id == id);
        if (index != -1) {
          _categories[index] = response.data!;
          notifyListeners();
        }
        return true;
      } else {
        _error = response.message ?? 'Error al actualizar la categoría';
        return false;
      }
    } catch (e) {
      _error = 'Error de conexión: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteCategory(String id) async {
    _setLoading(true);
    _error = null;

    try {
      final response = await _apiService.deleteCategory(id);

      if (response.success) {
        _categories.removeWhere((c) => c.id == id);
        notifyListeners();
        return true;
      } else {
        _error = response.message ?? 'Error al eliminar la categoría';
        return false;
      }
    } catch (e) {
      _error = 'Error de conexión: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Helper method to get user-friendly error messages
  String getErrorMessage() {
    if (_error == null) return '';

    // Map common error messages to user-friendly ones
    if (_error!.contains('SocketException') ||
        _error!.contains('HandshakeException')) {
      return 'Error de conexión. Verifica tu conexión a internet.';
    }

    if (_error!.contains('TimeoutException')) {
      return 'La operación tardó demasiado. Inténtalo de nuevo.';
    }

    if (_error!.contains('FormatException')) {
      return 'Error en el formato de los datos.';
    }

    if (_error!.contains('Unauthorized') || _error!.contains('401')) {
      return 'Sesión expirada. Por favor, inicia sesión nuevamente.';
    }

    if (_error!.contains('Forbidden') || _error!.contains('403')) {
      return 'No tienes permisos para realizar esta acción.';
    }

    if (_error!.contains('Not Found') || _error!.contains('404')) {
      return 'El recurso solicitado no fue encontrado.';
    }

    if (_error!.contains('Internal Server Error') || _error!.contains('500')) {
      return 'Error del servidor. Inténtalo más tarde.';
    }

    return _error!;
  }

  List<api_models.Category> _getDefaultCategories() {
    // These should match exactly with the backend defaultCategories
    return [
      // Income categories (matching backend)
      api_models.Category(
        id: 'default_salary',
        name: 'Salario',
        type: 'income',
        color: '#10B981',
        icon: 'Briefcase',
      ),
      api_models.Category(
        id: 'default_freelance',
        name: 'Freelance',
        type: 'income',
        color: '#3B82F6',
        icon: 'Laptop',
      ),
      api_models.Category(
        id: 'default_investment',
        name: 'Inversiones',
        type: 'income',
        color: '#8B5CF6',
        icon: 'TrendingUp',
      ),
      api_models.Category(
        id: 'default_other_income',
        name: 'Otros',
        type: 'income',
        color: '#6B7280',
        icon: 'Wallet',
      ),

      // Expense categories (matching backend)
      api_models.Category(
        id: 'default_food',
        name: 'Alimentación',
        type: 'expense',
        color: '#F59E0B',
        icon: 'ShoppingCart',
      ),
      api_models.Category(
        id: 'default_transport',
        name: 'Transporte',
        type: 'expense',
        color: '#EF4444',
        icon: 'Car',
      ),
      api_models.Category(
        id: 'default_housing',
        name: 'Vivienda',
        type: 'expense',
        color: '#8B5CF6',
        icon: 'Home',
      ),
      api_models.Category(
        id: 'default_entertainment',
        name: 'Entretenimiento',
        type: 'expense',
        color: '#EC4899',
        icon: 'Film',
      ),
      api_models.Category(
        id: 'default_health',
        name: 'Salud',
        type: 'expense',
        color: '#10B981',
        icon: 'Heart',
      ),
      api_models.Category(
        id: 'default_education',
        name: 'Educación',
        type: 'expense',
        color: '#3B82F6',
        icon: 'BookOpen',
      ),
      api_models.Category(
        id: 'default_clothing',
        name: 'Ropa',
        type: 'expense',
        color: '#F97316',
        icon: 'Shirt',
      ),
      api_models.Category(
        id: 'default_other',
        name: 'Otros',
        type: 'expense',
        color: '#6B7280',
        icon: 'Package',
      ),
    ];
  }

  // Budget methods
  Future<bool> createBudget({
    required String categoryId,
    required double amount,
    required String period,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      final response = await _apiService.createBudget(
        categoryId: categoryId,
        amount: amount,
        period: period,
        startDate: startDate,
        endDate: endDate,
      );

      if (response.success && response.data != null) {
        _budgets.add(response.data!);
        notifyListeners();
        return true;
      } else {
        _error = response.message ?? 'Error al crear el presupuesto';
        return false;
      }
    } catch (e) {
      _error = 'Error de conexión: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateBudget(
    String id, {
    String? categoryId,
    double? amount,
    String? period,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      final response = await _apiService.updateBudget(
        id,
        categoryId: categoryId,
        amount: amount,
        period: period,
        startDate: startDate,
        endDate: endDate,
      );

      if (response.success && response.data != null) {
        final index = _budgets.indexWhere((b) => b.id == id);
        if (index != -1) {
          _budgets[index] = response.data!;
          notifyListeners();
        }
        return true;
      } else {
        _error = response.message ?? 'Error al actualizar el presupuesto';
        return false;
      }
    } catch (e) {
      _error = 'Error de conexión: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteBudget(String id) async {
    _setLoading(true);
    _error = null;

    try {
      final response = await _apiService.deleteBudget(id);

      if (response.success) {
        _budgets.removeWhere((b) => b.id == id);
        notifyListeners();
        return true;
      } else {
        _error = response.message ?? 'Error al eliminar el presupuesto';
        return false;
      }
    } catch (e) {
      _error = 'Error de conexión: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }
}
