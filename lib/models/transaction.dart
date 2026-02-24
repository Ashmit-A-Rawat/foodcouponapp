// lib/models/transaction.dart
import 'package:flutter/material.dart';

class Transaction {
  final String id;
  final String type;
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

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['_id'] ?? json['transactionId'] ?? '',
      type: json['type'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      description: json['description'] ?? '',
      balanceAfter: (json['balanceAfter'] ?? 0).toDouble(),
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      username: json['username'],
      name: json['name'],
    );
  }

  bool get isCredit => type == 'credit';
  bool get isDebit => type == 'debit';
}