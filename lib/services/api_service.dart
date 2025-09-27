import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/api_models.dart';
import '../config/api_config.dart';

class ApiService {
  static String get baseUrl => ApiConfig.baseUrl;
  String? _token;

  ApiService() {
    _loadToken();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    _token = token;
  }

  Future<void> _clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    _token = null;
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  Future<ApiResponse<T>> _handleResponse<T>(
    http.Response response,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = json.decode(response.body);
      return ApiResponse<T>(
        success: true,
        data: fromJson(data),
        message: data['message'],
      );
    } else {
      final error = json.decode(response.body);
      return ApiResponse<T>(
        success: false,
        message: error['message'] ?? 'Error desconocido',
        error: error['error'],
      );
    }
  }

  Future<ApiResponse<T>> _makeRequest<T>(
    Future<http.Response> Function() request,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    try {
      final response = await request();
      return await _handleResponse(response, fromJson);
    } on http.ClientException catch (e) {
      // Manejo simplificado de errores de conexión
      if (e.message.contains('Failed host lookup') ||
          e.message.contains('no address associated with hostname')) {
        return ApiResponse<T>(
          success: false,
          message: 'Sin conexión a internet. Verifica tu red.',
        );
      } else if (e.message.contains('Connection refused') ||
          e.message.contains('Connection timed out')) {
        return ApiResponse<T>(
          success: false,
          message: 'Servidor no disponible. Inténtalo más tarde.',
        );
      } else {
        return ApiResponse<T>(
          success: false,
          message: 'Error de conexión. Verifica tu internet.',
        );
      }
    } catch (e) {
      return ApiResponse<T>(
        success: false,
        message: 'Error de conexión. Inténtalo más tarde.',
      );
    }
  }

  // Authentication methods
  Future<ApiResponse<AuthResponse>> login(String email, String password) async {
    final result = await _makeRequest<AuthResponse>(
      () => http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: _headers,
        body: json.encode({'email': email, 'password': password}),
      ),
      (data) => AuthResponse.fromJson(data),
    );

    if (result.success && result.data != null) {
      await _saveToken(result.data!.token);
    }

    return result;
  }

  Future<ApiResponse<AuthResponse>> register({
    required String name,
    required String email,
    required String password,
    String currency = 'USD',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: _headers,
        body: json.encode({
          'name': name,
          'email': email,
          'password': password,
          'currency': currency,
        }),
      );

      final result = await _handleResponse<AuthResponse>(
        response,
        (data) => AuthResponse.fromJson(data),
      );

      if (result.success && result.data != null) {
        await _saveToken(result.data!.token);
      }

      return result;
    } catch (e) {
      return ApiResponse<AuthResponse>(
        success: false,
        message: 'Error de conexión: $e',
      );
    }
  }

  Future<ApiResponse<User>> getCurrentUser() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/me'),
        headers: _headers,
      );

      return await _handleResponse<User>(
        response,
        (data) => User.fromJson(data['user']),
      );
    } catch (e) {
      return ApiResponse<User>(
        success: false,
        message: 'Error de conexión: $e',
      );
    }
  }

  Future<void> logout() async {
    await _clearToken();
  }

  bool get isAuthenticated => _token != null;

  // Transaction methods
  Future<ApiResponse<List<Transaction>>> getTransactions({
    int page = 1,
    int limit = 100,
    String? type,
    String? category,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
        if (type != null) 'type': type,
        if (category != null) 'category': category,
        if (startDate != null) 'startDate': startDate,
        if (endDate != null) 'endDate': endDate,
      };

      final uri = Uri.parse(
        '$baseUrl/transactions',
      ).replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: _headers);

      return await _handleResponse<List<Transaction>>(
        response,
        (data) => (data['transactions'] as List)
            .map((t) => Transaction.fromJson(t))
            .toList(),
      );
    } catch (e) {
      return ApiResponse<List<Transaction>>(
        success: false,
        message: 'Error de conexión: $e',
      );
    }
  }

  Future<ApiResponse<Transaction>> createTransaction({
    required String type,
    required double amount,
    required String description,
    required String category,
    required String paymentMethod,
    required DateTime date,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/transactions'),
        headers: _headers,
        body: json.encode({
          'type': type,
          'amount': amount,
          'description': description,
          'category': category,
          'paymentMethod': paymentMethod,
          'date': date.toIso8601String(),
        }),
      );

      return await _handleResponse<Transaction>(
        response,
        (data) => Transaction.fromJson(data['transaction']),
      );
    } catch (e) {
      return ApiResponse<Transaction>(
        success: false,
        message: 'Error de conexión: $e',
      );
    }
  }

  Future<ApiResponse<Transaction>> updateTransaction(
    String id, {
    String? type,
    double? amount,
    String? description,
    String? category,
    String? paymentMethod,
    DateTime? date,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (type != null) body['type'] = type;
      if (amount != null) body['amount'] = amount;
      if (description != null) body['description'] = description;
      if (category != null) body['category'] = category;
      if (paymentMethod != null) body['paymentMethod'] = paymentMethod;
      if (date != null) body['date'] = date.toIso8601String();

      final response = await http.put(
        Uri.parse('$baseUrl/transactions/$id'),
        headers: _headers,
        body: json.encode(body),
      );

      return await _handleResponse<Transaction>(
        response,
        (data) => Transaction.fromJson(data['transaction']),
      );
    } catch (e) {
      return ApiResponse<Transaction>(
        success: false,
        message: 'Error de conexión: $e',
      );
    }
  }

  Future<ApiResponse<void>> deleteTransaction(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/transactions/$id'),
        headers: _headers,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse<void>(
          success: true,
          message: 'Transacción eliminada exitosamente',
        );
      } else {
        final error = json.decode(response.body);
        return ApiResponse<void>(
          success: false,
          message: error['message'] ?? 'Error al eliminar transacción',
        );
      }
    } catch (e) {
      return ApiResponse<void>(
        success: false,
        message: 'Error de conexión: $e',
      );
    }
  }

  // Category methods
  Future<ApiResponse<List<Category>>> getCategories() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/categories'),
        headers: _headers,
      );

      return await _handleResponse<List<Category>>(
        response,
        (data) => (data['categories'] as List)
            .map((c) => Category.fromJson(c))
            .toList(),
      );
    } catch (e) {
      return ApiResponse<List<Category>>(
        success: false,
        message: 'Error de conexión: $e',
      );
    }
  }

  Future<ApiResponse<Category>> createCategory({
    required String name,
    required String type,
    String? color,
    String? icon,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/categories'),
        headers: _headers,
        body: json.encode({
          'name': name,
          'type': type,
          'color': color ?? '#6B7280',
          'icon': icon ?? 'category',
        }),
      );

      return await _handleResponse<Category>(
        response,
        (data) => Category.fromJson(data['category']),
      );
    } catch (e) {
      return ApiResponse<Category>(
        success: false,
        message: 'Error de conexión: $e',
      );
    }
  }

  Future<ApiResponse<Category>> updateCategory(
    String id, {
    String? name,
    String? type,
    String? color,
    String? icon,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (type != null) body['type'] = type;
      if (color != null) body['color'] = color;
      if (icon != null) body['icon'] = icon;

      final response = await http.put(
        Uri.parse('$baseUrl/categories/$id'),
        headers: _headers,
        body: json.encode(body),
      );

      return await _handleResponse<Category>(
        response,
        (data) => Category.fromJson(data['category']),
      );
    } catch (e) {
      return ApiResponse<Category>(
        success: false,
        message: 'Error de conexión: $e',
      );
    }
  }

  Future<ApiResponse<void>> deleteCategory(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/categories/$id'),
        headers: _headers,
      );

      return await _handleResponse<void>(response, (data) => null);
    } catch (e) {
      return ApiResponse<void>(
        success: false,
        message: 'Error de conexión: $e',
      );
    }
  }

  // Budget methods
  Future<ApiResponse<List<Budget>>> getBudgets({
    int page = 1,
    int limit = 100,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      final uri = Uri.parse(
        '$baseUrl/budgets',
      ).replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: _headers);

      return await _handleResponse<List<Budget>>(
        response,
        (data) =>
            (data['budgets'] as List).map((b) => Budget.fromJson(b)).toList(),
      );
    } catch (e) {
      return ApiResponse<List<Budget>>(
        success: false,
        message: 'Error de conexión: $e',
      );
    }
  }

  Future<ApiResponse<Budget>> createBudget({
    required String categoryId,
    required double amount,
    required String period,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/budgets'),
        headers: _headers,
        body: json.encode({
          'category': categoryId,
          'amount': amount,
          'period': period,
          'startDate': startDate.toIso8601String(),
          'endDate': endDate.toIso8601String(),
        }),
      );

      return await _handleResponse<Budget>(
        response,
        (data) => Budget.fromJson(data['budget']),
      );
    } catch (e) {
      return ApiResponse<Budget>(
        success: false,
        message: 'Error de conexión: $e',
      );
    }
  }

  Future<ApiResponse<Budget>> updateBudget(
    String id, {
    String? categoryId,
    double? amount,
    String? period,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (categoryId != null) body['category'] = categoryId;
      if (amount != null) body['amount'] = amount;
      if (period != null) body['period'] = period;
      if (startDate != null) body['startDate'] = startDate.toIso8601String();
      if (endDate != null) body['endDate'] = endDate.toIso8601String();

      final response = await http.put(
        Uri.parse('$baseUrl/budgets/$id'),
        headers: _headers,
        body: json.encode(body),
      );

      return await _handleResponse<Budget>(
        response,
        (data) => Budget.fromJson(data['budget']),
      );
    } catch (e) {
      return ApiResponse<Budget>(
        success: false,
        message: 'Error de conexión: $e',
      );
    }
  }

  Future<ApiResponse<void>> deleteBudget(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/budgets/$id'),
        headers: _headers,
      );

      return await _handleResponse<void>(response, (data) => null);
    } catch (e) {
      return ApiResponse<void>(
        success: false,
        message: 'Error de conexión: $e',
      );
    }
  }

  // User profile methods
  Future<ApiResponse<User>> updateProfile({
    String? name,
    String? currency,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (currency != null) body['currency'] = currency;

      final response = await http.put(
        Uri.parse('$baseUrl/user/profile'),
        headers: _headers,
        body: json.encode(body),
      );

      return await _handleResponse<User>(
        response,
        (data) => User.fromJson(data['user']),
      );
    } catch (e) {
      return ApiResponse<User>(
        success: false,
        message: 'Error de conexión: $e',
      );
    }
  }

  Future<ApiResponse<void>> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/user/password'),
        headers: _headers,
        body: json.encode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      );

      return await _handleResponse<void>(response, (data) => null);
    } catch (e) {
      return ApiResponse<void>(
        success: false,
        message: 'Error de conexión: $e',
      );
    }
  }

  Future<ApiResponse<void>> updateNotificationSettings({
    bool? budgetReminders,
    bool? weeklySummary,
    bool? savingGoals,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (budgetReminders != null) body['budgetReminders'] = budgetReminders;
      if (weeklySummary != null) body['weeklySummary'] = weeklySummary;
      if (savingGoals != null) body['savingGoals'] = savingGoals;

      final response = await http.put(
        Uri.parse('$baseUrl/user/notifications'),
        headers: _headers,
        body: json.encode(body),
      );

      return await _handleResponse<void>(response, (data) => null);
    } catch (e) {
      return ApiResponse<void>(
        success: false,
        message: 'Error de conexión: $e',
      );
    }
  }

  Future<ApiResponse<void>> deleteAccount({required String password}) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/user/account'),
        headers: _headers,
        body: json.encode({'password': password}),
      );

      return await _handleResponse<void>(response, (data) => null);
    } catch (e) {
      return ApiResponse<void>(
        success: false,
        message: 'Error de conexión: $e',
      );
    }
  }

  // Statistics methods
  Future<ApiResponse<TransactionStats>> getTransactionStats({
    String? startDate,
    String? endDate,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (startDate != null) queryParams['startDate'] = startDate;
      if (endDate != null) queryParams['endDate'] = endDate;

      final uri = Uri.parse(
        '$baseUrl/transactions/stats/summary',
      ).replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: _headers);

      return await _handleResponse<TransactionStats>(
        response,
        (data) => TransactionStats.fromJson(data),
      );
    } catch (e) {
      return ApiResponse<TransactionStats>(
        success: false,
        message: 'Error de conexión: $e',
      );
    }
  }
}
