import 'package:flutter/material.dart';

class Account {
  final String? id;
  final String name;
  final String type; // 'cash', 'bank', 'credit', 'savings', 'investment'
  final double balance;
  final String currency;
  final String? description;
  final double? creditLimit;
  final String? bankName;
  final String? accountNumber;
  final bool isActive;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;

  Account({
    this.id,
    required this.name,
    required this.type,
    required this.balance,
    required this.currency,
    this.description,
    this.creditLimit,
    this.bankName,
    this.accountNumber,
    required this.isActive,
    required this.isDefault,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convertir a Map para API
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type,
      'balance': balance,
      'currency': currency,
      'description': description,
      'creditLimit': creditLimit,
      'bankName': bankName,
      'accountNumber': accountNumber,
      'isDefault': isDefault,
    };
  }

  // Crear desde Map (desde API)
  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['_id']?.toString() ?? map['id']?.toString(),
      name: map['name']?.toString() ?? 'Cuenta sin nombre',
      type: map['type']?.toString() ?? 'cash',
      balance: (map['balance'] as num?)?.toDouble() ?? 0.0,
      currency: map['currency']?.toString() ?? 'USD',
      description: map['description']?.toString(),
      creditLimit: map['creditLimit'] != null
          ? (map['creditLimit'] as num?)?.toDouble()
          : null,
      bankName: map['bankName']?.toString(),
      accountNumber: map['accountNumber']?.toString(),
      isActive: map['isActive'] as bool? ?? true,
      isDefault: map['isDefault'] as bool? ?? false,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : DateTime.now(),
    );
  }

  // Crear copia con nuevos valores
  Account copyWith({
    String? id,
    String? name,
    String? type,
    double? balance,
    String? currency,
    String? description,
    double? creditLimit,
    String? bankName,
    String? accountNumber,
    bool? isActive,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      balance: balance ?? this.balance,
      currency: currency ?? this.currency,
      description: description ?? this.description,
      creditLimit: creditLimit ?? this.creditLimit,
      bankName: bankName ?? this.bankName,
      accountNumber: accountNumber ?? this.accountNumber,
      isActive: isActive ?? this.isActive,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Getters para display
  String get typeDisplay {
    const types = {
      'cash': 'Efectivo',
      'bank': 'Cuenta Bancaria',
      'credit': 'Tarjeta de Crédito',
      'savings': 'Cuenta de Ahorros',
      'investment': 'Inversión',
    };
    return types[type] ?? type;
  }

  IconData get typeIcon {
    final icons = {
      'cash': Icons.account_balance_wallet,
      'bank': Icons.account_balance,
      'credit': Icons.credit_card,
      'savings': Icons.savings,
      'investment': Icons.trending_up,
    };
    return icons[type] ?? Icons.account_balance_wallet;
  }

  double? get availableCredit {
    if (type == 'credit' && creditLimit != null) {
      return creditLimit! - balance.abs();
    }
    return null;
  }

  String get formattedBalance {
    return '\$${balance.toStringAsFixed(2)}';
  }

  @override
  String toString() {
    return 'Account(id: $id, name: $name, type: $type, balance: $balance)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Account && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
