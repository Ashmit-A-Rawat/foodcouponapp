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

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      name: json['name'] ?? '',
      balance: (json['balance'] ?? 0).toDouble(),
      role: json['role'] ?? 'user',
    );
  }

  bool get isAdmin => role == 'admin';
}

class Transaction {
  final String id;
  final String type;
  final double amount;
  final String description;
  final double balanceAfter;
  final DateTime date;
  final String? username;  // Add this
  final String? name;      // Add this

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

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['_id'] ?? json['transactionId'] ?? '',
      type: json['type'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      description: json['description'] ?? '',
      balanceAfter: (json['balanceAfter'] ?? 0).toDouble(),
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      username: json['username'],  // Add this
      name: json['name'],          // Add this
    );
  }

  bool get isCredit => type == 'credit';
  bool get isDebit => type == 'debit';
}