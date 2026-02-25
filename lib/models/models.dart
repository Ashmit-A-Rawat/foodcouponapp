// lib/models/models.dart
// Single source of truth for User and Transaction.
// menu_item.dart and order.dart are re-exported from here for convenience.

export 'menu_item.dart';
export 'order.dart';

// ==================== USER ====================
class User {
  final String id;
  final String username;
  final String name;
  final double balance;
  final String role;

  User({
    required this.id,
    required this.username,
    required this.name,
    required this.balance,
    required this.role,
  });

  bool get isAdmin => role == 'admin';
  bool get isCanteen => role == 'canteen';
  bool get isUser => role == 'user';

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: _str(json['_id'] ?? json['id']),
      username: _str(json['username']),
      name: _str(json['name']),
      balance: _dbl(json['balance']),
      role: _str(json['role']),
    );
  }

  Map<String, dynamic> toJson() =>
      {'id': id, 'username': username, 'name': name, 'balance': balance, 'role': role};

  static String _str(dynamic v) => v?.toString() ?? '';
  static double _dbl(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }
}

// ==================== TRANSACTION ====================
// IMPORTANT: Defined ONLY here. lib/models/transaction.dart just re-exports.
class Transaction {
  final String id;
  final String type; // 'credit' | 'debit'
  final double amount;
  final String description;
  final double balanceAfter;
  final DateTime date;
  final String? username;
  final String? name;

  Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.balanceAfter,
    required this.date,
    this.username,
    this.name,
  });

  bool get isCredit => type == 'credit';
  bool get isDebit => type == 'debit';

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: _str(json['_id'] ?? json['id']),
      type: _str(json['type']),
      amount: _dbl(json['amount']),
      description: _str(json['description']),
      balanceAfter: _dbl(json['balanceAfter']),
      date: _date(json['createdAt'] ?? json['date']),
      username: json['username']?.toString(),
      name: json['name']?.toString(),
    );
  }

  static String _str(dynamic v) => v?.toString() ?? '';
  static double _dbl(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  static DateTime _date(dynamic v) {
    if (v == null) return DateTime.now();
    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString()) ?? DateTime.now();
  }
}