// Base API Response
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final String? error;

  ApiResponse({required this.success, this.data, this.message, this.error});
}

// User model
class User {
  final String id;
  final String name;
  final String email;
  final String currency;
  final NotificationSettings notificationSettings;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.currency,
    required this.notificationSettings,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      currency: json['currency'] as String,
      notificationSettings: NotificationSettings.fromJson(
        json['notificationSettings'] as Map<String, dynamic>,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'currency': currency,
      'notificationSettings': notificationSettings.toJson(),
    };
  }
}

class NotificationSettings {
  final bool budgetReminders;
  final bool weeklySummary;
  final bool savingGoals;

  NotificationSettings({
    required this.budgetReminders,
    required this.weeklySummary,
    required this.savingGoals,
  });

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      budgetReminders: json['budgetReminders'] as bool,
      weeklySummary: json['weeklySummary'] as bool,
      savingGoals: json['savingGoals'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'budgetReminders': budgetReminders,
      'weeklySummary': weeklySummary,
      'savingGoals': savingGoals,
    };
  }
}

// Auth response
class AuthResponse {
  final String token;
  final User user;

  AuthResponse({required this.token, required this.user});

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'] as String,
      user: User.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {'token': token, 'user': user.toJson()};
  }
}

// Transaction model
class Transaction {
  final String id;
  final String type; // 'income' or 'expense'
  final double amount;
  final String description;
  final Category category; // Now it's a Category object
  final String paymentMethod; // 'cash', 'transfer', 'debit', 'credit'
  final DateTime date;
  final DateTime createdAt;

  Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.category,
    required this.paymentMethod,
    required this.date,
    required this.createdAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      type: json['type'] as String,
      amount: (json['amount'] as num).toDouble(),
      description: json['description'] as String,
      category: Category.fromJson(json['category'] as Map<String, dynamic>),
      paymentMethod: json['paymentMethod'] as String,
      date: DateTime.parse(json['date'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'amount': amount,
      'description': description,
      'category': category.toJson(),
      'paymentMethod': paymentMethod,
      'date': date.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

// Category model
class Category {
  final String id;
  final String name;
  final String type; // 'income' or 'expense'
  final String color;
  final String icon;

  Category({
    required this.id,
    required this.name,
    required this.type,
    required this.color,
    required this.icon,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['_id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      color: json['color'] as String,
      icon: json['icon'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'type': type, 'color': color, 'icon': icon};
  }
}

// Budget model
class Budget {
  final String id;
  final Category category; // Now it's a Category object
  final double amount;
  final double spent;
  final String period; // 'monthly', 'weekly', 'yearly'
  final DateTime startDate;
  final DateTime endDate;

  Budget({
    required this.id,
    required this.category,
    required this.amount,
    required this.spent,
    required this.period,
    required this.startDate,
    required this.endDate,
  });

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      id: json['id'] as String,
      category: Category.fromJson(json['category'] as Map<String, dynamic>),
      amount: (json['amount'] as num).toDouble(),
      spent: (json['spent'] as num).toDouble(),
      period: json['period'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category.toJson(),
      'amount': amount,
      'spent': spent,
      'period': period,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
    };
  }
}

// Transaction statistics
class TransactionStats {
  final TransactionSummary summary;
  final DatePeriod period;

  TransactionStats({required this.summary, required this.period});

  factory TransactionStats.fromJson(Map<String, dynamic> json) {
    return TransactionStats(
      summary: TransactionSummary.fromJson(
        json['summary'] as Map<String, dynamic>,
      ),
      period: DatePeriod.fromJson(json['period'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {'summary': summary.toJson(), 'period': period.toJson()};
  }
}

class TransactionSummary {
  final double totalIncome;
  final double totalExpenses;
  final double netAmount;
  final int incomeCount;
  final int expenseCount;
  final int totalTransactions;

  TransactionSummary({
    required this.totalIncome,
    required this.totalExpenses,
    required this.netAmount,
    required this.incomeCount,
    required this.expenseCount,
    required this.totalTransactions,
  });

  factory TransactionSummary.fromJson(Map<String, dynamic> json) {
    return TransactionSummary(
      totalIncome: (json['totalIncome'] as num).toDouble(),
      totalExpenses: (json['totalExpenses'] as num).toDouble(),
      netAmount: (json['netAmount'] as num).toDouble(),
      incomeCount: json['incomeCount'] as int,
      expenseCount: json['expenseCount'] as int,
      totalTransactions: json['totalTransactions'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalIncome': totalIncome,
      'totalExpenses': totalExpenses,
      'netAmount': netAmount,
      'incomeCount': incomeCount,
      'expenseCount': expenseCount,
      'totalTransactions': totalTransactions,
    };
  }
}

class DatePeriod {
  final DateTime startDate;
  final DateTime endDate;

  DatePeriod({required this.startDate, required this.endDate});

  factory DatePeriod.fromJson(Map<String, dynamic> json) {
    return DatePeriod(
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
    };
  }
}
