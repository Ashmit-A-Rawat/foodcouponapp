// lib/models/order.dart
import 'package:flutter/material.dart';

class OrderItem {
  final String menuItemId;
  final String name;
  final int quantity;
  final double price;
  final double totalPrice;

  OrderItem({
    required this.menuItemId,
    required this.name,
    required this.quantity,
    required this.price,
    required this.totalPrice,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    // Helper function to safely extract String
    String safeString(dynamic value, {String defaultValue = ''}) {
      if (value == null) return defaultValue;
      if (value is String) return value;
      if (value is Map && value.containsKey('_id')) return value['_id'].toString();
      return value.toString();
    }

    // Helper function to safely extract double
    double safeDouble(dynamic value, {double defaultValue = 0.0}) {
      if (value == null) return defaultValue;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        try {
          return double.parse(value);
        } catch (e) {
          return defaultValue;
        }
      }
      return defaultValue;
    }

    // Helper function to safely extract int
    int safeInt(dynamic value, {int defaultValue = 0}) {
      if (value == null) return defaultValue;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) {
        try {
          return int.parse(value);
        } catch (e) {
          return defaultValue;
        }
      }
      return defaultValue;
    }

    return OrderItem(
      menuItemId: safeString(json['menuItem']),
      name: json['name']?.toString() ?? '',
      quantity: safeInt(json['quantity'], defaultValue: 1),
      price: safeDouble(json['price']),
      totalPrice: safeDouble(json['totalPrice']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'menuItemId': menuItemId,
      'quantity': quantity,
    };
  }
}

class Order {
  final String id;
  final String orderNumber;
  final String userId;
  final String userName;
  final List<OrderItem> items;
  final double subtotal;
  final double totalAmount;
  final String status;
  final String paymentStatus;
  final String paymentMethod;
  final String? razorpayOrderId;
  final DateTime requestedTime;
  final DateTime estimatedReadyTime;
  final DateTime? actualReadyTime;
  final DateTime? completedTime;
  final String? qrCodeToken;
  final DateTime? qrScannedAt;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Order({
    required this.id,
    required this.orderNumber,
    required this.userId,
    required this.userName,
    required this.items,
    required this.subtotal,
    required this.totalAmount,
    required this.status,
    required this.paymentStatus,
    required this.paymentMethod,
    this.razorpayOrderId,
    required this.requestedTime,
    required this.estimatedReadyTime,
    this.actualReadyTime,
    this.completedTime,
    this.qrCodeToken,
    this.qrScannedAt,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    // Helper function to safely extract String
    String safeString(dynamic value, {String defaultValue = ''}) {
      if (value == null) return defaultValue;
      if (value is String) return value;
      if (value is Map && value.containsKey('_id')) return value['_id'].toString();
      return value.toString();
    }

    // Helper function to safely extract double
    double safeDouble(dynamic value, {double defaultValue = 0.0}) {
      if (value == null) return defaultValue;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        try {
          return double.parse(value);
        } catch (e) {
          return defaultValue;
        }
      }
      return defaultValue;
    }

    // Helper function to safely extract DateTime
    DateTime safeDate(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is DateTime) return value;
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          return DateTime.now();
        }
      }
      return DateTime.now();
    }

    return Order(
      id: safeString(json['_id']),
      orderNumber: json['orderNumber']?.toString() ?? '',
      userId: json['user'] is Map 
          ? safeString(json['user']['_id'])
          : safeString(json['user']),
      userName: json['userName']?.toString() ?? '',
      items: (json['items'] as List? ?? [])
          .map((item) => OrderItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      subtotal: safeDouble(json['subtotal']),
      totalAmount: safeDouble(json['totalAmount']),
      status: json['status']?.toString() ?? 'pending',
      paymentStatus: json['paymentStatus']?.toString() ?? 'pending',
      paymentMethod: json['paymentMethod']?.toString() ?? 'wallet',
      razorpayOrderId: json['razorpayOrderId']?.toString(),
      requestedTime: safeDate(json['requestedTime']),
      estimatedReadyTime: safeDate(json['estimatedReadyTime']),
      actualReadyTime: json['actualReadyTime'] != null
          ? safeDate(json['actualReadyTime'])
          : null,
      completedTime: json['completedTime'] != null
          ? safeDate(json['completedTime'])
          : null,
      qrCodeToken: json['qrCodeToken']?.toString(),
      qrScannedAt: json['qrScannedAt'] != null
          ? safeDate(json['qrScannedAt'])
          : null,
      notes: json['notes']?.toString() ?? '',
      createdAt: safeDate(json['createdAt']),
      updatedAt: safeDate(json['updatedAt']),
    );
  }

  // Status helpers
  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
  bool get isPreparing => status == 'preparing';
  bool get isReady => status == 'ready';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';

  // Payment status helpers
  bool get isPaid => paymentStatus == 'paid';
  bool get isPaymentPending => paymentStatus == 'pending';

  // Status color
  Color get statusColor {
    switch (status) {
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'confirmed':
        return const Color(0xFF3B82F6);
      case 'preparing':
        return const Color(0xFF8B5CF6);
      case 'ready':
        return const Color(0xFF10B981);
      case 'completed':
        return const Color(0xFF6366F1);
      case 'cancelled':
        return const Color(0xFFEF4444);
      default:
        return Colors.grey;
    }
  }

  // Status icon
  IconData get statusIcon {
    switch (status) {
      case 'pending':
        return Icons.pending_actions;
      case 'confirmed':
        return Icons.check_circle_outline;
      case 'preparing':
        return Icons.restaurant;
      case 'ready':
        return Icons.room_service;
      case 'completed':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  // Status display
  String get statusDisplay {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'confirmed':
        return 'Confirmed';
      case 'preparing':
        return 'Preparing';
      case 'ready':
        return 'Ready for Pickup';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }
}