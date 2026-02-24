// lib/screens/menu_screen.dart
import 'package:flutter/material.dart';
import 'dart:ui';
import '../services/api_service.dart';
import '../models/menu_item.dart';
import 'order_confirmation_screen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> with TickerProviderStateMixin {
  final _apiService = ApiService();
  List<MenuItem> _menuItems = [];
  List<MenuItem> _filteredItems = [];
  bool _isLoading = true;
  String _selectedCategory = 'all';
  final Map<String, int> _cart = {}; // itemId -> quantity

  late AnimationController _animationController;

  final List<Map<String, dynamic>> _categories = [
    {'id': 'all', 'name': 'All', 'icon': Icons.restaurant_menu},
    {'id': 'breakfast', 'name': 'Breakfast', 'icon': Icons.free_breakfast},
    {'id': 'lunch', 'name': 'Lunch', 'icon': Icons.lunch_dining},
    {'id': 'snacks', 'name': 'Snacks', 'icon': Icons.fastfood},
    {'id': 'dinner', 'name': 'Dinner', 'icon': Icons.dinner_dining},
    {'id': 'beverages', 'name': 'Beverages', 'icon': Icons.local_cafe},
    {'id': 'desserts', 'name': 'Desserts', 'icon': Icons.cake},
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _loadMenu();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadMenu() async {
    setState(() => _isLoading = true);

    final result = await _apiService.getMenuItems(
      category: _selectedCategory != 'all' ? _selectedCategory : null,
    );

    if (result['success']) {
      setState(() {
        _menuItems = (result['menuItems'] as List)
            .map((json) => MenuItem.fromJson(json))
            .where((item) => item.isAvailable)
            .toList();
        _filterItems();
        _isLoading = false;
      });
      _animationController.forward();
    } else {
      setState(() => _isLoading = false);
    }
  }

  void _filterItems() {
    if (_selectedCategory == 'all') {
      _filteredItems = _menuItems;
    } else {
      _filteredItems = _menuItems
          .where((item) => item.category == _selectedCategory)
          .toList();
    }
  }

  void _addToCart(String itemId) {
    setState(() {
      _cart[itemId] = (_cart[itemId] ?? 0) + 1;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Item added to cart'),
        backgroundColor: Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(20),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _removeFromCart(String itemId) {
    setState(() {
      if (_cart.containsKey(itemId)) {
        if (_cart[itemId]! > 1) {
          _cart[itemId] = _cart[itemId]! - 1;
        } else {
          _cart.remove(itemId);
        }
      }
    });
  }

  int _getCartCount() {
    return _cart.values.fold(0, (sum, count) => sum + count);
  }

  double _getCartTotal() {
    double total = 0;
    _cart.forEach((itemId, quantity) {
      final item = _menuItems.firstWhere((item) => item.id == itemId);
      total += item.price * quantity;
    });
    return total;
  }

  void _goToCart() {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cart is empty'),
          backgroundColor: Color(0xFFF59E0B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: EdgeInsets.all(20),
        ),
      );
      return;
    }

    final cartItems = _cart.entries.map((entry) {
      final item = _menuItems.firstWhere((item) => item.id == entry.key);
      return {
        'item': item,
        'quantity': entry.value,
      };
    }).toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderConfirmationScreen(
          cartItems: cartItems,
          totalAmount: _getCartTotal(),
        ),
      ),
    ).then((_) {
      // Refresh cart after order placement
      setState(() {
        _cart.clear();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F7),
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
                color: Color(0xFF10B981).withOpacity(0.08),
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
                color: Color(0xFF6366F1).withOpacity(0.06),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: EdgeInsets.all(24),
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
                              icon: Icon(Icons.arrow_back, color: Color(0xFF1F2937)),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Menu',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                      ),
                      // Cart button
                      Stack(
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
                                  onPressed: _goToCart,
                                  icon: Icon(Icons.shopping_cart, color: Color(0xFF6366F1)),
                                ),
                              ),
                            ),
                          ),
                          if (_getCartCount() > 0)
                            Positioned(
                              right: 6,
                              top: 6,
                              child: Container(
                                padding: EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Color(0xFFEF4444),
                                  shape: BoxShape.circle,
                                ),
                                constraints: BoxConstraints(
                                  minWidth: 18,
                                  minHeight: 18,
                                ),
                                child: Text(
                                  '${_getCartCount()}',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Category chips
                Container(
                  height: 50,
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      final isSelected = _selectedCategory == category['id'];

                      return Padding(
                        padding: EdgeInsets.only(right: 12),
                        child: FilterChip(
                          selected: isSelected,
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                category['icon'],
                                size: 16,
                                color: isSelected ? Colors.white : Color(0xFF64748B),
                              ),
                              SizedBox(width: 6),
                              Text(category['name']),
                            ],
                          ),
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategory = category['id'];
                              _filterItems();
                            });
                            _loadMenu();
                          },
                          backgroundColor: Colors.white.withOpacity(0.7),
                          selectedColor: Color(0xFF6366F1),
                          checkmarkColor: Colors.white,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Color(0xFF1F2937),
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          ),
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                            side: BorderSide(
                              color: isSelected
                                  ? Colors.transparent
                                  : Colors.white.withOpacity(0.5),
                              width: 1,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                SizedBox(height: 20),

                // Menu items grid
                Expanded(
                  child: _isLoading
                      ? Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF6366F1),
                            strokeWidth: 3,
                          ),
                        )
                      : _filteredItems.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.restaurant,
                                    size: 80,
                                    color: Colors.grey.shade400,
                                  ),
                                  SizedBox(height: 20),
                                  Text(
                                    'No items available',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : GridView.builder(
                              padding: EdgeInsets.fromLTRB(24, 0, 24, 100),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.75,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                              ),
                              itemCount: _filteredItems.length,
                              itemBuilder: (context, index) {
                                final item = _filteredItems[index];
                                final cartQuantity = _cart[item.id] ?? 0;
                                return _buildMenuItemCard(item, cartQuantity, index);
                              },
                            ),
                ),
              ],
            ),
          ),

          // Cart bottom bar
          if (_getCartCount() > 0)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.5),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF6366F1).withOpacity(0.2),
                          blurRadius: 20,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${_getCartCount()} items',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              Text(
                                '₹${_getCartTotal().toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF6366F1),
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: _goToCart,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF6366F1),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'View Cart',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
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
    );
  }

  Widget _buildMenuItemCard(MenuItem item, int cartQuantity, int index) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 400 + (index * 50)),
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withOpacity(0.5),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Item image placeholder with category color
                Container(
                  height: 100,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: item.categoryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Icon(
                          item.categoryIcon,
                          size: 40,
                          color: item.categoryColor,
                        ),
                      ),
                      // Category badge
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: item.categoryColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            item.categoryDisplay,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Text(
                        item.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.timer,
                            size: 14,
                            color: Color(0xFFF59E0B),
                          ),
                          SizedBox(width: 4),
                          Text(
                            '${item.preparationTime} min',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '₹${item.price.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF6366F1),
                            ),
                          ),
                          if (cartQuantity > 0)
                            Container(
                              decoration: BoxDecoration(
                                color: Color(0xFF6366F1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    onPressed: () => _removeFromCart(item.id),
                                    icon: Icon(Icons.remove, color: Colors.white, size: 16),
                                    constraints: BoxConstraints(
                                      minWidth: 30,
                                      minHeight: 30,
                                    ),
                                    padding: EdgeInsets.zero,
                                  ),
                                  Text(
                                    '$cartQuantity',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () => _addToCart(item.id),
                                    icon: Icon(Icons.add, color: Colors.white, size: 16),
                                    constraints: BoxConstraints(
                                      minWidth: 30,
                                      minHeight: 30,
                                    ),
                                    padding: EdgeInsets.zero,
                                  ),
                                ],
                              ),
                            )
                          else
                            IconButton(
                              onPressed: () => _addToCart(item.id),
                              icon: Icon(Icons.add_shopping_cart, color: Color(0xFF6366F1)),
                              constraints: BoxConstraints(
                                minWidth: 36,
                                minHeight: 36,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}