// lib/screens/canteen_menu_management.dart
import 'package:flutter/material.dart';
import 'dart:ui';
import '../services/api_service.dart';
import '../models/menu_item.dart';

class CanteenMenuManagement extends StatefulWidget {
  const CanteenMenuManagement({super.key});

  @override
  State<CanteenMenuManagement> createState() => _CanteenMenuManagementState();
}

class _CanteenMenuManagementState extends State<CanteenMenuManagement> with SingleTickerProviderStateMixin {
  final _apiService = ApiService();
  List<MenuItem> _menuItems = [];
  bool _isLoading = true;
  String _selectedCategory = 'all';

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

  try {
    final result = await _apiService.getCanteenMenu();

    if (mounted) {
      if (result['success'] == true) {
        final List<dynamic> menuData = result['menuItems'] ?? [];
        
        // Safe conversion with error handling
        final List<MenuItem> items = [];
        for (var item in menuData) {
          try {
            if (item is Map<String, dynamic>) {
              items.add(MenuItem.fromJson(item));
            }
          } catch (e) {
            print('Error parsing menu item: $e');
          }
        }
        
        setState(() {
          _menuItems = items;
          _isLoading = false;
        });
        _animationController.forward();
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to load menu'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  } catch (e) {
    print('Error loading menu: $e');
    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading menu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
  List<MenuItem> get _filteredItems {
    if (_selectedCategory == 'all') {
      return _menuItems;
    }
    return _menuItems.where((item) => item.category == _selectedCategory).toList();
  }

  void _showAddEditDialog({MenuItem? item}) {
    final isEditing = item != null;
    final nameController = TextEditingController(text: item?.name ?? '');
    final descriptionController = TextEditingController(text: item?.description ?? '');
    final priceController = TextEditingController(text: item?.price.toString() ?? '');
    final timeController = TextEditingController(text: item?.preparationTime.toString() ?? '15');
    String selectedCategory = item?.category ?? 'snacks';
    String availableFrom = item?.availableFrom ?? '09:00';
    String availableTo = item?.availableTo ?? '21:00';

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: Colors.white.withOpacity(0.9),
                  width: 1.5,
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isEditing ? 'Edit Menu Item' : 'Add Menu Item',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Name
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Item Name',
                        prefixIcon: const Icon(Icons.restaurant, color: Color(0xFF6366F1)),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Description
                    TextField(
                      controller: descriptionController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        prefixIcon: const Icon(Icons.description, color: Color(0xFF6366F1)),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Price and Time row
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: priceController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Price',
                              prefixText: '₹ ',
                              prefixIcon: const Icon(Icons.currency_rupee, color: Color(0xFF6366F1)),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: timeController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Prep Time',
                              suffixText: 'min',
                              prefixIcon: const Icon(Icons.timer, color: Color(0xFF6366F1)),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Category dropdown
                    DropdownButtonFormField<String>(
                      initialValue: selectedCategory,
                      decoration: InputDecoration(
                        labelText: 'Category',
                        prefixIcon: const Icon(Icons.category, color: Color(0xFF6366F1)),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: _categories.where((c) => c['id'] != 'all').map((category) {
  return DropdownMenuItem<String>(
    value: category['id'].toString(),
    child: Text(category['name']),
  );
}).toList(),
                      onChanged: (value) {
                        selectedCategory = value!;
                      },
                    ),
                    const SizedBox(height: 12),

                    // Available hours
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: TextEditingController(text: availableFrom),
                            decoration: InputDecoration(
                              labelText: 'From',
                              hintText: '09:00',
                              prefixIcon: const Icon(Icons.access_time, color: Color(0xFF6366F1)),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            onChanged: (value) => availableFrom = value,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: TextEditingController(text: availableTo),
                            decoration: InputDecoration(
                              labelText: 'To',
                              hintText: '21:00',
                              prefixIcon: const Icon(Icons.access_time, color: Color(0xFF6366F1)),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            onChanged: (value) => availableTo = value,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              Navigator.pop(context);
                              if (isEditing) {
                                await _updateItem(
                                  item.id,
                                  nameController.text,
                                  descriptionController.text,
                                  double.parse(priceController.text),
                                  selectedCategory,
                                  int.parse(timeController.text),
                                  availableFrom,
                                  availableTo,
                                );
                              } else {
                                await _addItem(
                                  nameController.text,
                                  descriptionController.text,
                                  double.parse(priceController.text),
                                  selectedCategory,
                                  int.parse(timeController.text),
                                  availableFrom,
                                  availableTo,
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6366F1),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(isEditing ? 'Update' : 'Add'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _addItem(String name, String description, double price, String category,
      int prepTime, String from, String to) async {
    setState(() => _isLoading = true);

    final result = await _apiService.createMenuItem(
      name: name,
      description: description,
      price: price,
      category: category,
      preparationTime: prepTime,
      availableFrom: from,
      availableTo: to,
    );

    setState(() => _isLoading = false);

    if (result['success'] && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Menu item added successfully'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
      _loadMenu();
    }
  }

  Future<void> _updateItem(String id, String name, String description, double price,
      String category, int prepTime, String from, String to) async {
    setState(() => _isLoading = true);

    final result = await _apiService.updateMenuItem(
      itemId: id,
      name: name,
      description: description,
      price: price,
      category: category,
      preparationTime: prepTime,
      availableFrom: from,
      availableTo: to,
    );

    setState(() => _isLoading = false);

    if (result['success'] && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Menu item updated successfully'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
      _loadMenu();
    }
  }

  Future<void> _toggleAvailability(MenuItem item) async {
    final result = await _apiService.toggleMenuItemAvailability(item.id);

    if (result['success'] && mounted) {
      _loadMenu();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Item ${result['isAvailable'] ? 'available' : 'unavailable'} now'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    }
  }

  Future<void> _deleteItem(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: const Text('Are you sure you want to delete this item?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFEF4444),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      final result = await _apiService.deleteMenuItem(id);
      setState(() => _isLoading = false);

      if (result['success'] && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item deleted successfully'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        _loadMenu();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        backgroundColor: const Color(0xFF6366F1),
        child: const Icon(Icons.add, color: Colors.white),
      ),
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
                color: const Color(0xFF10B981).withOpacity(0.08),
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
                // Header
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
                      const Text(
                        'Manage Menu',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                    ],
                  ),
                ),

                // Category chips
                Container(
                  height: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      final isSelected = _selectedCategory == category['id'];

                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: FilterChip(
                          selected: isSelected,
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                category['icon'],
                                size: 16,
                                color: isSelected ? Colors.white : const Color(0xFF64748B),
                              ),
                              const SizedBox(width: 6),
                              Text(category['name']),
                            ],
                          ),
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategory = category['id'];
                            });
                          },
                          backgroundColor: Colors.white.withOpacity(0.7),
                          selectedColor: const Color(0xFF6366F1),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : const Color(0xFF1F2937),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 20),

                // Menu items list
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
                      : _filteredItems.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.restaurant_menu,
                                    size: 80,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    'No items in this category',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  ElevatedButton(
                                    onPressed: () => _showAddEditDialog(),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF6366F1),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 12,
                                      ),
                                    ),
                                    child: const Text('Add Item'),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(24),
                              itemCount: _filteredItems.length,
                              itemBuilder: (context, index) {
                                return _buildMenuItemCard(_filteredItems[index], index);
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

  Widget _buildMenuItemCard(MenuItem item, int index) {
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
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.7),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: item.isAvailable
                ? Colors.white.withOpacity(0.8)
                : Colors.red.withOpacity(0.3),
            width: item.isAvailable ? 1 : 2,
          ),
        ),
        child: Row(
          children: [
            // Item icon with availability indicator
            Stack(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: item.categoryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    item.categoryIcon,
                    color: item.categoryColor,
                    size: 32,
                  ),
                ),
                if (!item.isAvailable)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(width: 16),

            // Item details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '₹${item.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6366F1),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${item.preparationTime} min',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFF59E0B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Action buttons
            Column(
              children: [
                IconButton(
                  onPressed: () => _toggleAvailability(item),
                  icon: Icon(
                    item.isAvailable ? Icons.visibility : Icons.visibility_off,
                    color: item.isAvailable ? const Color(0xFF10B981) : Colors.grey,
                  ),
                  tooltip: item.isAvailable ? 'Mark Unavailable' : 'Mark Available',
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () => _showAddEditDialog(item: item),
                      icon: const Icon(
                        Icons.edit,
                        color: Color(0xFF6366F1),
                        size: 20,
                      ),
                    ),
                    IconButton(
                      onPressed: () => _deleteItem(item.id),
                      icon: const Icon(
                        Icons.delete,
                        color: Color(0xFFEF4444),
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}