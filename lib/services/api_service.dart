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

  // Ensure token is loaded before making requests
  Future<void> _ensureTokenLoaded() async {
    if (_token == null) {
      await _loadToken();
    }
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
    try {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = json.decode(response.body);

        // Handle different response structures
        T parsedData;
        if (data is List) {
          // For list responses, the data is already the list
          parsedData = data as T;
        } else if (data is Map<String, dynamic>) {
          // For object responses, use fromJson
          parsedData = fromJson(data);
        } else {
          // For primitive responses, use as is
          parsedData = data as T;
        }

        return ApiResponse<T>(
          success: true,
          data: parsedData,
          message: data is Map<String, dynamic> ? data['message'] : null,
        );
      } else {
        final error = json.decode(response.body);
        String errorMessage = 'Error desconocido';

        // Manejo específico de códigos de error HTTP
        switch (response.statusCode) {
          case 400:
            errorMessage = error['message'] ?? 'Datos inválidos';
            break;
          case 401:
            errorMessage = error['message'] ?? 'No autorizado';
            break;
          case 403:
            errorMessage = error['message'] ?? 'Acceso denegado';
            break;
          case 404:
            errorMessage = error['message'] ?? 'Recurso no encontrado';
            break;
          case 422:
            errorMessage = error['message'] ?? 'Datos de entrada inválidos';
            break;
          case 500:
            errorMessage = 'Error interno del servidor. Inténtalo más tarde';
            break;
          case 503:
            errorMessage = 'Servicio no disponible. Inténtalo más tarde';
            break;
          default:
            errorMessage =
                error['message'] ??
                'Error del servidor (${response.statusCode})';
        }

        return ApiResponse<T>(
          success: false,
          message: errorMessage,
          error: error['error'],
        );
      }
    } catch (e) {
      return ApiResponse<T>(
        success: false,
        message: 'Error al procesar la respuesta del servidor',
        error: e.toString(),
      );
    }
  }

  Future<ApiResponse<T>> _makeRequest<T>(
    Future<http.Response> Function() request,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    try {
      // Ensure token is loaded before making the request
      await _ensureTokenLoaded();

      final response = await request().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('TimeoutException');
        },
      );
      return await _handleResponse(response, fromJson);
    } on http.ClientException catch (e) {
      // Manejo específico de errores de conexión
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
    } on Exception catch (e) {
      if (e.toString().contains('TimeoutException')) {
        return ApiResponse<T>(
          success: false,
          message: 'La conexión tardó demasiado. Inténtalo nuevamente.',
        );
      }
      return ApiResponse<T>(
        success: false,
        message: 'Error de conexión. Inténtalo más tarde.',
      );
    } catch (e) {
      return ApiResponse<T>(
        success: false,
        message: 'Error inesperado. Inténtalo más tarde.',
        error: e.toString(),
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

    try {
      await _ensureTokenLoaded();
      final response = await http
          .get(uri, headers: _headers)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception('TimeoutException');
            },
          );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = json.decode(response.body);
        List<Transaction> transactions = [];

        if (data is List) {
          transactions = data.map((t) {
            return Transaction.fromJson(t as Map<String, dynamic>);
          }).toList();
        } else if (data is Map<String, dynamic>) {
          if (data.containsKey('transactions')) {
            final transactionsList = data['transactions'] as List;
            transactions = transactionsList.map((t) {
              if (t is Map<String, dynamic>) {
                return Transaction.fromJson(t);
              } else if (t is Transaction) {
                return t;
              } else {
                return Transaction.fromJson(t as Map<String, dynamic>);
              }
            }).toList();
          } else if (data.containsKey('data') && data['data'] is List) {
            final transactionsList = data['data'] as List;
            transactions = transactionsList.map((t) {
              if (t is Map<String, dynamic>) {
                return Transaction.fromJson(t);
              } else if (t is Transaction) {
                return t;
              } else {
                return Transaction.fromJson(t as Map<String, dynamic>);
              }
            }).toList();
          }
        }

        return ApiResponse<List<Transaction>>(
          success: true,
          data: transactions,
          message: data is Map<String, dynamic> ? data['message'] : null,
        );
      } else {
        final error = json.decode(response.body);
        return ApiResponse<List<Transaction>>(
          success: false,
          message: error['message'] ?? 'Error al cargar transacciones',
        );
      }
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
    required String account,
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
          'account': account,
          'date': date.toIso8601String(),
        }),
      );

      final result = await _handleResponse<Map<String, dynamic>>(
        response,
        (data) => data,
      );

      if (result.success && result.data != null) {
        return ApiResponse<Transaction>(
          success: true,
          message: result.message,
          data: Transaction.fromJson(result.data!['transaction']),
        );
      } else {
        return ApiResponse<Transaction>(
          success: false,
          message: result.message,
        );
      }
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
      await _ensureTokenLoaded();
      final response = await http
          .get(Uri.parse('$baseUrl/categories'), headers: _headers)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception('TimeoutException');
            },
          );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = json.decode(response.body);
        List<Category> categories = [];

        if (data is List) {
          categories = data.map((c) {
            if (c is Map<String, dynamic>) {
              return Category.fromJson(c);
            } else if (c is Category) {
              return c;
            } else {
              return Category.fromJson(c as Map<String, dynamic>);
            }
          }).toList();
        } else if (data is Map<String, dynamic>) {
          if (data.containsKey('categories')) {
            final categoriesList = data['categories'] as List;
            categories = categoriesList.map((c) {
              if (c is Map<String, dynamic>) {
                return Category.fromJson(c);
              } else if (c is Category) {
                return c;
              } else {
                return Category.fromJson(c as Map<String, dynamic>);
              }
            }).toList();
          } else if (data.containsKey('data') && data['data'] is List) {
            final categoriesList = data['data'] as List;
            categories = categoriesList.map((c) {
              if (c is Map<String, dynamic>) {
                return Category.fromJson(c);
              } else if (c is Category) {
                return c;
              } else {
                return Category.fromJson(c as Map<String, dynamic>);
              }
            }).toList();
          }
        }

        return ApiResponse<List<Category>>(
          success: true,
          data: categories,
          message: data is Map<String, dynamic> ? data['message'] : null,
        );
      } else {
        final error = json.decode(response.body);
        return ApiResponse<List<Category>>(
          success: false,
          message: error['message'] ?? 'Error al cargar categorías',
        );
      }
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
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    final uri = Uri.parse(
      '$baseUrl/budgets',
    ).replace(queryParameters: queryParams);

    try {
      await _ensureTokenLoaded();
      final response = await http
          .get(uri, headers: _headers)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception('TimeoutException');
            },
          );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = json.decode(response.body);
        List<Budget> budgets = [];

        if (data is List) {
          budgets = data.map((b) {
            if (b is Map<String, dynamic>) {
              return Budget.fromJson(b);
            } else if (b is Budget) {
              return b;
            } else {
              return Budget.fromJson(b as Map<String, dynamic>);
            }
          }).toList();
        } else if (data is Map<String, dynamic>) {
          if (data.containsKey('budgets')) {
            final budgetsList = data['budgets'] as List;
            budgets = budgetsList.map((b) {
              if (b is Map<String, dynamic>) {
                return Budget.fromJson(b);
              } else if (b is Budget) {
                return b;
              } else {
                return Budget.fromJson(b as Map<String, dynamic>);
              }
            }).toList();
          } else if (data.containsKey('data') && data['data'] is List) {
            final budgetsList = data['data'] as List;
            budgets = budgetsList.map((b) {
              if (b is Map<String, dynamic>) {
                return Budget.fromJson(b);
              } else if (b is Budget) {
                return b;
              } else {
                return Budget.fromJson(b as Map<String, dynamic>);
              }
            }).toList();
          }
        }

        return ApiResponse<List<Budget>>(
          success: true,
          data: budgets,
          message: data is Map<String, dynamic> ? data['message'] : null,
        );
      } else {
        final error = json.decode(response.body);
        return ApiResponse<List<Budget>>(
          success: false,
          message: error['message'] ?? 'Error al cargar presupuestos',
        );
      }
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

  Future<ApiResponse<void>> deleteUserAccount({
    required String password,
  }) async {
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

  // Account methods
  Future<ApiResponse<List<dynamic>>> getAccounts() async {
    try {
      await _ensureTokenLoaded();
      final response = await http
          .get(Uri.parse('$baseUrl/accounts'), headers: _headers)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception('TimeoutException');
            },
          );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = json.decode(response.body);
        List<dynamic> accounts = [];

        if (data is List) {
          accounts = data;
        } else if (data is Map<String, dynamic>) {
          if (data.containsKey('accounts')) {
            accounts = data['accounts'] as List;
          } else if (data.containsKey('data') && data['data'] is List) {
            accounts = data['data'] as List;
          }
        }

        return ApiResponse<List<dynamic>>(
          success: true,
          data: accounts,
          message: data is Map<String, dynamic> ? data['message'] : null,
        );
      } else {
        final error = json.decode(response.body);
        return ApiResponse<List<dynamic>>(
          success: false,
          message: error['message'] ?? 'Error al cargar cuentas',
        );
      }
    } catch (e) {
      return ApiResponse<List<dynamic>>(
        success: false,
        message: 'Error de conexión: $e',
      );
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> getAccount(String accountId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/accounts/$accountId'),
        headers: _headers,
      );

      return await _handleResponse<Map<String, dynamic>>(
        response,
        (data) => data['data'] as Map<String, dynamic>,
      );
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Error de conexión: $e',
      );
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> createAccount(
    Map<String, dynamic> accountData,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/accounts'),
        headers: _headers,
        body: json.encode(accountData),
      );

      return await _handleResponse<Map<String, dynamic>>(
        response,
        (data) => data['data'] as Map<String, dynamic>,
      );
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Error de conexión: $e',
      );
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> updateAccount(
    String accountId,
    Map<String, dynamic> accountData,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/accounts/$accountId'),
        headers: _headers,
        body: json.encode(accountData),
      );

      return await _handleResponse<Map<String, dynamic>>(
        response,
        (data) => data['data'] as Map<String, dynamic>,
      );
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Error de conexión: $e',
      );
    }
  }

  Future<ApiResponse<void>> deleteAccount(String accountId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/accounts/$accountId'),
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

  Future<ApiResponse<Map<String, dynamic>>> transferMoney(
    String fromAccountId,
    Map<String, dynamic> transferData,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/accounts/$fromAccountId/transfer'),
        headers: _headers,
        body: json.encode(transferData),
      );

      return await _handleResponse<Map<String, dynamic>>(
        response,
        (data) => data['data'] as Map<String, dynamic>,
      );
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Error de conexión: $e',
      );
    }
  }

  // Transfer Category methods
  Future<ApiResponse<List<dynamic>>> getTransferCategories() async {
    try {
      await _ensureTokenLoaded();
      final response = await http
          .get(Uri.parse('$baseUrl/transfer-categories'), headers: _headers)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception('TimeoutException');
            },
          );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = json.decode(response.body);
        List<dynamic> categories = [];

        if (data is List) {
          categories = data;
        } else if (data is Map<String, dynamic> && data['data'] != null) {
          categories = data['data'] as List<dynamic>;
        }

        return ApiResponse<List<dynamic>>(
          success: true,
          data: categories,
          message: data['message'],
        );
      } else {
        return ApiResponse<List<dynamic>>(
          success: false,
          message: 'Error del servidor: ${response.statusCode}',
        );
      }
    } catch (e) {
      return ApiResponse<List<dynamic>>(
        success: false,
        message: 'Error de conexión: $e',
      );
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> createTransferCategory(
    Map<String, dynamic> categoryData,
  ) async {
    try {
      await _ensureTokenLoaded();
      final response = await http
          .post(
            Uri.parse('$baseUrl/transfer-categories'),
            headers: _headers,
            body: json.encode(categoryData),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception('TimeoutException');
            },
          );

      return await _handleResponse<Map<String, dynamic>>(
        response,
        (data) => data['data'] as Map<String, dynamic>,
      );
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Error de conexión: $e',
      );
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> updateTransferCategory(
    String categoryId,
    Map<String, dynamic> categoryData,
  ) async {
    try {
      await _ensureTokenLoaded();
      final response = await http
          .put(
            Uri.parse('$baseUrl/transfer-categories/$categoryId'),
            headers: _headers,
            body: json.encode(categoryData),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception('TimeoutException');
            },
          );

      return await _handleResponse<Map<String, dynamic>>(
        response,
        (data) => data['data'] as Map<String, dynamic>,
      );
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Error de conexión: $e',
      );
    }
  }

  Future<ApiResponse> deleteTransferCategory(String categoryId) async {
    try {
      await _ensureTokenLoaded();
      final response = await http
          .delete(
            Uri.parse('$baseUrl/transfer-categories/$categoryId'),
            headers: _headers,
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception('TimeoutException');
            },
          );

      return await _handleResponse(response, (data) => data);
    } catch (e) {
      return ApiResponse(success: false, message: 'Error de conexión: $e');
    }
  }

  // Account Reports methods
  Future<ApiResponse<Map<String, dynamic>>> getBalanceSummary() async {
    try {
      await _ensureTokenLoaded();
      final response = await http
          .get(
            Uri.parse('$baseUrl/account-reports/balance-summary'),
            headers: _headers,
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception('TimeoutException');
            },
          );

      return await _handleResponse<Map<String, dynamic>>(
        response,
        (data) => data['data'] as Map<String, dynamic>,
      );
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Error de conexión: $e',
      );
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> getCashFlow({
    String? startDate,
    String? endDate,
    String? accountId,
  }) async {
    try {
      await _ensureTokenLoaded();
      String url = '$baseUrl/account-reports/cash-flow';
      List<String> params = [];

      if (startDate != null) params.add('startDate=$startDate');
      if (endDate != null) params.add('endDate=$endDate');
      if (accountId != null) params.add('accountId=$accountId');

      if (params.isNotEmpty) {
        url += '?${params.join('&')}';
      }

      final response = await http
          .get(Uri.parse(url), headers: _headers)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception('TimeoutException');
            },
          );

      return await _handleResponse<Map<String, dynamic>>(
        response,
        (data) => data['data'] as Map<String, dynamic>,
      );
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Error de conexión: $e',
      );
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> getAccountAnalysis(
    String accountId, {
    String? startDate,
    String? endDate,
  }) async {
    try {
      await _ensureTokenLoaded();
      String url = '$baseUrl/account-reports/account-analysis/$accountId';
      List<String> params = [];

      if (startDate != null) params.add('startDate=$startDate');
      if (endDate != null) params.add('endDate=$endDate');

      if (params.isNotEmpty) {
        url += '?${params.join('&')}';
      }

      final response = await http
          .get(Uri.parse(url), headers: _headers)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception('TimeoutException');
            },
          );

      return await _handleResponse<Map<String, dynamic>>(
        response,
        (data) => data['data'] as Map<String, dynamic>,
      );
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Error de conexión: $e',
      );
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> getBalanceProjection({
    int months = 6,
  }) async {
    try {
      await _ensureTokenLoaded();
      final response = await http
          .get(
            Uri.parse(
              '$baseUrl/account-reports/balance-projection?months=$months',
            ),
            headers: _headers,
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception('TimeoutException');
            },
          );

      return await _handleResponse<Map<String, dynamic>>(
        response,
        (data) => data['data'] as Map<String, dynamic>,
      );
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Error de conexión: $e',
      );
    }
  }
}
