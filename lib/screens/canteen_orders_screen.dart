// lib/screens/canteen_orders_screen.dart
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../models/order.dart';

class CanteenOrdersScreen extends StatefulWidget {
  const CanteenOrdersScreen({super.key});

  @override
  State<CanteenOrdersScreen> createState() => _CanteenOrdersScreenState();
}

class _CanteenOrdersScreenState extends State<CanteenOrdersScreen> with SingleTickerProviderStateMixin {
  final _apiService = ApiService();
  List<Order> _orders = [];
  bool _isLoading = true;
  String _selectedStatus = 'pending';
  DateTime? _selectedDate;

  late AnimationController _animationController;

  final List<Map<String, dynamic>> _statusTabs = [
    {'id': 'pending', 'name': 'Pending', 'icon': Icons.pending_actions, 'color': const Color(0xFFF59E0B)},
    {'id': 'confirmed', 'name': 'Confirmed', 'icon': Icons.check_circle_outline, 'color': const Color(0xFF3B82F6)},
    {'id': 'preparing', 'name': 'Preparing', 'icon': Icons.restaurant, 'color': const Color(0xFF8B5CF6)},
    {'id': 'ready', 'name': 'Ready', 'icon': Icons.room_service, 'color': const Color(0xFF10B981)},
    {'id': 'completed', 'name': 'Completed', 'icon': Icons.check_circle, 'color': const Color(0xFF6366F1)},
    {'id': 'cancelled', 'name': 'Cancelled', 'icon': Icons.cancel, 'color': const Color(0xFFEF4444)},
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _loadOrders();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);

    final dateStr = _selectedDate != null
        ? DateFormat('yyyy-MM-dd').format(_selectedDate!)
        : null;

    final result = await _apiService.getCanteenOrders(
      status: _selectedStatus == 'all' ? null : _selectedStatus,
      date: dateStr,
    );

    if (result['success'] && mounted) {
      setState(() {
        _orders = (result['orders'] as List)
            .map((json) => Order.fromJson(json))
            .toList();
        _isLoading = false;
      });
      _animationController.forward();
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateOrderStatus(Order order, String newStatus) async {
    setState(() => _isLoading = true);

    DateTime? actualReadyTime;
    if (newStatus == 'ready') {
      actualReadyTime = DateTime.now();
    }

    final result = await _apiService.updateOrderStatus(
      orderId: order.id,
      status: newStatus,
      actualReadyTime: actualReadyTime,
    );

    setState(() => _isLoading = false);

    if (result['success'] && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order status updated to ${newStatus.toUpperCase()}'),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(20),
        ),
      );
      _loadOrders();
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF6366F1),
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
      _loadOrders();
    }
  }

  String _formatTime(DateTime time) {
    return DateFormat('hh:mm a').format(time);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: Stack(
        children: [
          // Background decorative elements
          Positioned(
            top: -100,
            right: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF8B5CF6).withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -120,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6366F1).withOpacity(0.06),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Header with date filter
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.8),
                                width: 1,
                              ),
                            ),
                            child: IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.arrow_back, color: Color(0xFF1F2937)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'Orders',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: _selectDate,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.8),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_today,
                                    size: 16,
                                    color: Color(0xFF6366F1),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _selectedDate == null
                                        ? 'Today'
                                        : DateFormat('dd MMM').format(_selectedDate!),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1F2937),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Status tabs
                Container(
                  height: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _statusTabs.length,
                    itemBuilder: (context, index) {
                      final tab = _statusTabs[index];
                      final isSelected = _selectedStatus == tab['id'];

                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: FilterChip(
                          selected: isSelected,
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                tab['icon'],
                                size: 16,
                                color: isSelected ? Colors.white : tab['color'],
                              ),
                              const SizedBox(width: 6),
                              Text(tab['name']),
                            ],
                          ),
                          onSelected: (selected) {
                            setState(() {
                              _selectedStatus = tab['id'];
                            });
                            _loadOrders();
                          },
                          backgroundColor: Colors.white.withOpacity(0.7),
                          selectedColor: tab['color'],
                          checkmarkColor: Colors.white,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : tab['color'],
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 20),

                // Orders list
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
                      : _orders.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.shopping_bag,
                                    size: 80,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    'No orders found',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(24),
                              itemCount: _orders.length,
                              itemBuilder: (context, index) {
                                return _buildOrderCard(_orders[index], index);
                              },
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Order order, int index) {
    final statusTab = _statusTabs.firstWhere(
      (tab) => tab['id'] == order.status,
      orElse: () => _statusTabs[0],
    );

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 400 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value.clamp(0.0, 1.0),
          child: Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.7),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: statusTab['color'].withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: statusTab['color'].withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    statusTab['icon'],
                    color: statusTab['color'],
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.orderNumber,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        order.userName,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusTab['color'].withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    order.statusDisplay,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: statusTab['color'],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Items
            ...order.items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Text(
                    '${item.quantity}x',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6366F1),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ),
                  Text(
                    '₹${item.totalPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ],
              ),
            )),

            const Divider(height: 20),

            // Order info
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Color(0xFF64748B)),
                const SizedBox(width: 4),
                Text(
                  'Requested: ${_formatTime(order.requestedTime)}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.schedule, size: 16, color: Color(0xFF10B981)),
                const SizedBox(width: 4),
                Text(
                  'Ready by: ${_formatTime(order.estimatedReadyTime)}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF10B981)),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Payment info
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: order.paymentMethod == 'wallet'
                        ? const Color(0xFF6366F1).withOpacity(0.1)
                        : const Color(0xFFF59E0B).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    order.paymentMethod == 'wallet' ? 'Wallet' : 'Razorpay',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: order.paymentMethod == 'wallet'
                          ? const Color(0xFF6366F1)
                          : const Color(0xFFF59E0B),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: order.isPaid
                        ? const Color(0xFF10B981).withOpacity(0.1)
                        : const Color(0xFFEF4444).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    order.paymentStatus.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: order.isPaid ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  'Total: ₹${order.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6366F1),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Action buttons based on status
            if (order.status == 'pending')
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _updateOrderStatus(order, 'confirmed'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Confirm'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _updateOrderStatus(order, 'cancelled'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFEF4444),
                        side: const BorderSide(color: Color(0xFFEF4444)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Reject'),
                    ),
                  ),
                ],
              ),

            if (order.status == 'confirmed')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _updateOrderStatus(order, 'preparing'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Start Preparing'),
                ),
              ),

            if (order.status == 'preparing')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _updateOrderStatus(order, 'ready'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Mark Ready'),
                ),
              ),

            if (order.status == 'ready')
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.qr_code_scanner, color: Color(0xFF10B981)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'QR Token: ${order.qrCodeToken?.substring(0, 8)}...',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}