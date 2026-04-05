import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_colors.dart';
import '../models/transaction.dart';
import '../models/user_model.dart';
import '../services/storage_service.dart';
import '../services/category_service.dart';
import '../providers/theme_provider.dart';
import '../widgets/main_layout.dart';

class ManageCategoriesScreen extends StatefulWidget {
  const ManageCategoriesScreen({Key? key}) : super(key: key);

  @override
  State<ManageCategoriesScreen> createState() => _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState extends State<ManageCategoriesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Category> _expenseCategories = [];
  List<Category> _incomeCategories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);

    final allCategories = await StorageService.getCategories();

    setState(() {
      _expenseCategories = allCategories
          .where((c) => c.type == TransactionType.expense)
          .toList();
      _incomeCategories = allCategories
          .where((c) => c.type == TransactionType.income)
          .toList();
      _isLoading = false;
    });
  }

  Future<void> _addCategory(TransactionType type) async {
    final nameController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String selectedIcon = '📦';
    Color selectedColor = AppColors.primaryBlue;

    // EXPANDED ICONS LIST - 50+ common icons for categories
    final List<String> icons = [
      // Food & Dining (8)
      '🍕', '🍔', '🍟', '🌭', '🍿', '🥗', '🍜', '🍣', '🍱', '🥘',
      '🍲', '🥪', '🌮', '🥙', '🍳', '🥓', '🍗', '🥩', '🍝', '☕',
      '🧋', '🥤', '🍺', '🍷', '🥂', '🧃',

      // Shopping (8)
      '🛍️', '👕', '👖', '👗', '👔', '🧥', '👟', '👠', '👜', '💼',
      '👓', '🧦', '🧢', '💍', '⌚', '📱', '💻', '🖥️', '📷', '🎧',

      // Transport (6)
      '🚗', '🚕', '🚌', '🚎', '🏎️', '🚲', '🛵', '🚆', '✈️', '🚢',
      '⛽', '🅿️', '🚦', '🚧',

      // Home & Utilities (8)
      '🏠', '🏢', '🏡', '🏪', '💡', '🔦', '🔌', '💧', '🔥', '❄️',
      '🧹', '🧺', '🔨', '🛠️', '🧰', '🚪',

      // Entertainment (8)
      '🎬', '🎮', '🎯', '🎲', '♟️', '🎨', '🎭', '🎪', '🎟️', '🎫',
      '🏟️', '🎡', '🎢', '🎠', '🏊', '⚽', '🏀', '🏈', '⚾', '🎾',

      // Health & Wellness (6)
      '🏥', '💊', '🩺', '💉', '🦷', '👁️', '🧠', '❤️', '🫀', '🧘',
      '🏋️', '🚴', '🤸', '🧖', '💆', '💇',

      // Education (5)
      '📚', '✏️', '📝', '📖', '🎓', '📌', '📍', '📎', '📏', '📐',

      // Finance (8)
      '💰', '💵', '💴', '💶', '💷', '💳', '🏦', '📈', '📉', '⚖️',
      '🧾', '📊', '📋', '📁',

      // Miscellaneous (10)
      '🎁', '✨', '💫', '⭐', '🌟', '💥', '🔥', '💧', '❄️', '🌈',
      '☀️', '🌙', '☁️', '⛅', '🌧️', '🌨️', '🌩️', '⚡', '💨', '🌪️',
      '🌍', '🌎', '🌏', '🗺️', '🧭', '⏰', '⌛', '📅', '📆', '🔔'
    ];

    // Common colors for categories
    final List<Color> colors = [
      const Color(0xFFFF6B6B), // Red
      const Color(0xFF4ECDC4), // Teal
      const Color(0xFF45B7D1), // Blue
      const Color(0xFFFFA07A), // Orange
      const Color(0xFFDDA15E), // Gold
      const Color(0xFFBC6C25), // Brown
      const Color(0xFF606C38), // Olive
      const Color(0xFF9C89B8), // Purple
      const Color(0xFFF2C14E), // Yellow
      const Color(0xFFE5989B), // Pink
      const Color(0xFFB5838D), // Mauve
      const Color(0xFF6D6875), // Gray
      const Color(0xFF52B788), // Green
      const Color(0xFF74C69D), // Light Green
      const Color(0xFF40916C), // Dark Green
    ];

    return showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            elevation: 0,
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 400),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header with gradient - FIXED: Icons and text now white
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              type == TransactionType.income
                                  ? AppColors.success
                                  : AppColors.primaryBlue,
                              type == TransactionType.income
                                  ? AppColors.incomeLight
                                  : AppColors.accentTeal,
                            ],
                          ),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                type == TransactionType.income
                                    ? Icons.trending_up
                                    : Icons.shopping_bag,
                                color: Colors.white, // FIXED: White icon
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Add ${type == TransactionType.income ? 'Income' : 'Expense'} Category',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white, // FIXED: White text
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white, // FIXED: White close icon
                                  size: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Form Content
                      Flexible(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Form(
                            key: formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Category Name Field
                                const Text(
                                  'Category Name',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: nameController,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter category name';
                                    }
                                    return null;
                                  },
                                  decoration: InputDecoration(
                                    hintText: 'e.g., Groceries, Salary, etc.',
                                    prefixIcon: Container(
                                      padding: const EdgeInsets.all(12),
                                      child: const Icon(
                                        Icons.category,
                                        color: AppColors.primaryBlue,
                                        size: 18,
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: AppColors.lightGray,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: AppColors.primaryBlue,
                                        width: 2,
                                      ),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: AppColors.error,
                                        width: 1,
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 20),

                                // Icon Selection - Now with more icons
                                const Text(
                                  'Select Icon',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  height: 200, // Increased height for more icons
                                  child: GridView.builder(
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 6,
                                      crossAxisSpacing: 8,
                                      mainAxisSpacing: 8,
                                    ),
                                    itemCount: icons.length,
                                    itemBuilder: (context, index) {
                                      final icon = icons[index];
                                      final isSelected = selectedIcon == icon;
                                      return GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            selectedIcon = icon;
                                          });
                                        },
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? (type == TransactionType.income
                                                ? AppColors.success
                                                : AppColors.primaryBlue)
                                                : AppColors.lightGray,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: isSelected
                                                  ? Colors.transparent
                                                  : Colors.grey[300]!,
                                              width: 1,
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              icon,
                                              style: const TextStyle(fontSize: 20),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),

                                const SizedBox(height: 20),

                                // Color Selection
                                const Text(
                                  'Select Color',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  height: 50,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: colors.length,
                                    itemBuilder: (context, index) {
                                      final color = colors[index];
                                      final isSelected = selectedColor.value == color.value;
                                      return GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            selectedColor = color;
                                          });
                                        },
                                        child: Container(
                                          width: 40,
                                          height: 40,
                                          margin: const EdgeInsets.only(right: 12),
                                          decoration: BoxDecoration(
                                            color: color,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: isSelected ? Colors.white : Colors.transparent,
                                              width: 3,
                                            ),
                                            boxShadow: isSelected
                                                ? [
                                              BoxShadow(
                                                color: color.withOpacity(0.5),
                                                blurRadius: 8,
                                                spreadRadius: 2,
                                              ),
                                            ]
                                                : null,
                                          ),
                                          child: isSelected
                                              ? const Center(
                                            child: Icon(
                                              Icons.check,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                          )
                                              : null,
                                        ),
                                      );
                                    },
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // Action Buttons
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () => Navigator.pop(context),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppColors.textSecondary,
                                          side: BorderSide(color: Colors.grey[300]!),
                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                        child: const Text(
                                          'Cancel',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () async {
                                          if (formKey.currentState!.validate()) {
                                            // Show loading indicator
                                            showDialog(
                                              context: context,
                                              barrierDismissible: false,
                                              builder: (context) => const Center(
                                                child: CircularProgressIndicator(),
                                              ),
                                            );

                                            try {
                                              final newCategory = Category(
                                                id: DateTime.now().millisecondsSinceEpoch.toString(),
                                                name: nameController.text.trim(),
                                                icon: selectedIcon,
                                                color: '#${selectedColor.value.toRadixString(16).substring(2)}',
                                                type: type,
                                                isDefault: false,
                                              );

                                              final categories = await StorageService.getCategories();
                                              categories.add(newCategory);
                                              await StorageService.saveCategories(categories);

                                              // Close loading dialog
                                              if (mounted) Navigator.pop(context);

                                              // Close add dialog
                                              if (mounted) Navigator.pop(context);

                                              // Refresh the list
                                              await _loadCategories();

                                              // Show success message
                                              if (mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Row(
                                                      children: [
                                                        Container(
                                                          padding: const EdgeInsets.all(6),
                                                          decoration: const BoxDecoration(
                                                            color: Colors.white,
                                                            shape: BoxShape.circle,
                                                          ),
                                                          child: Icon(
                                                            Icons.check,
                                                            color: type == TransactionType.income
                                                                ? AppColors.success
                                                                : AppColors.primaryBlue,
                                                            size: 14,
                                                          ),
                                                        ),
                                                        const SizedBox(width: 10),
                                                        Expanded(
                                                          child: Text(
                                                            'Category added successfully!',
                                                            style: const TextStyle(
                                                              fontSize: 13,
                                                              fontWeight: FontWeight.w600,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    backgroundColor: type == TransactionType.income
                                                        ? AppColors.success
                                                        : AppColors.primaryBlue,
                                                    behavior: SnackBarBehavior.floating,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(10),
                                                    ),
                                                    margin: const EdgeInsets.all(16),
                                                    duration: const Duration(seconds: 2),
                                                  ),
                                                );
                                              }
                                            } catch (e) {
                                              if (mounted) Navigator.pop(context); // Close loading
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Row(
                                                    children: [
                                                      const Icon(
                                                        Icons.error_outline,
                                                        color: Colors.white,
                                                        size: 18,
                                                      ),
                                                      const SizedBox(width: 10),
                                                      Expanded(
                                                        child: Text('Error: $e'),
                                                      ),
                                                    ],
                                                  ),
                                                  backgroundColor: AppColors.error,
                                                  behavior: SnackBarBehavior.floating,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                  margin: const EdgeInsets.all(16),
                                                ),
                                              );
                                            }
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: type == TransactionType.income
                                              ? AppColors.success
                                              : AppColors.primaryBlue,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          elevation: 0,
                                        ),
                                        child: const Text(
                                          'Add Category',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _editCategory(Category category) async {
    final nameController = TextEditingController(text: category.name);
    final formKey = GlobalKey<FormState>();
    String selectedIcon = category.icon;
    Color selectedColor = _parseColor(category.color);

    // EXPANDED ICONS LIST - Same expanded list for edit
    final List<String> icons = [
      // Food & Dining (8)
      '🍕', '🍔', '🍟', '🌭', '🍿', '🥗', '🍜', '🍣', '🍱', '🥘',
      '🍲', '🥪', '🌮', '🥙', '🍳', '🥓', '🍗', '🥩', '🍝', '☕',
      '🧋', '🥤', '🍺', '🍷', '🥂', '🧃',

      // Shopping (8)
      '🛍️', '👕', '👖', '👗', '👔', '🧥', '👟', '👠', '👜', '💼',
      '👓', '🧦', '🧢', '💍', '⌚', '📱', '💻', '🖥️', '📷', '🎧',

      // Transport (6)
      '🚗', '🚕', '🚌', '🚎', '🏎️', '🚲', '🛵', '🚆', '✈️', '🚢',
      '⛽', '🅿️', '🚦', '🚧',

      // Home & Utilities (8)
      '🏠', '🏢', '🏡', '🏪', '💡', '🔦', '🔌', '💧', '🔥', '❄️',
      '🧹', '🧺', '🔨', '🛠️', '🧰', '🚪',

      // Entertainment (8)
      '🎬', '🎮', '🎯', '🎲', '♟️', '🎨', '🎭', '🎪', '🎟️', '🎫',
      '🏟️', '🎡', '🎢', '🎠', '🏊', '⚽', '🏀', '🏈', '⚾', '🎾',

      // Health & Wellness (6)
      '🏥', '💊', '🩺', '💉', '🦷', '👁️', '🧠', '❤️', '🫀', '🧘',
      '🏋️', '🚴', '🤸', '🧖', '💆', '💇',

      // Education (5)
      '📚', '✏️', '📝', '📖', '🎓', '📌', '📍', '📎', '📏', '📐',

      // Finance (8)
      '💰', '💵', '💴', '💶', '💷', '💳', '🏦', '📈', '📉', '⚖️',
      '🧾', '📊', '📋', '📁',

      // Miscellaneous (10)
      '🎁', '✨', '💫', '⭐', '🌟', '💥', '🔥', '💧', '❄️', '🌈',
      '☀️', '🌙', '☁️', '⛅', '🌧️', '🌨️', '🌩️', '⚡', '💨', '🌪️',
      '🌍', '🌎', '🌏', '🗺️', '🧭', '⏰', '⌛', '📅', '📆', '🔔'
    ];

    // Common colors for categories
    final List<Color> colors = [
      const Color(0xFFFF6B6B), // Red
      const Color(0xFF4ECDC4), // Teal
      const Color(0xFF45B7D1), // Blue
      const Color(0xFFFFA07A), // Orange
      const Color(0xFFDDA15E), // Gold
      const Color(0xFFBC6C25), // Brown
      const Color(0xFF606C38), // Olive
      const Color(0xFF9C89B8), // Purple
      const Color(0xFFF2C14E), // Yellow
      const Color(0xFFE5989B), // Pink
      const Color(0xFFB5838D), // Mauve
      const Color(0xFF6D6875), // Gray
      const Color(0xFF52B788), // Green
      const Color(0xFF74C69D), // Light Green
      const Color(0xFF40916C), // Dark Green
    ];

    return showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            elevation: 0,
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 400),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header with gradient - FIXED: Icons and text now white
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              category.type == TransactionType.income
                                  ? AppColors.success
                                  : AppColors.primaryBlue,
                              category.type == TransactionType.income
                                  ? AppColors.incomeLight
                                  : AppColors.accentTeal,
                            ],
                          ),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                category.type == TransactionType.income
                                    ? Icons.trending_up
                                    : Icons.shopping_bag,
                                color: Colors.white, // FIXED: White icon
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Edit Category',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white, // FIXED: White text
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white, // FIXED: White close icon
                                  size: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Form Content
                      Flexible(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Form(
                            key: formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Category Name Field
                                const Text(
                                  'Category Name',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: nameController,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter category name';
                                    }
                                    return null;
                                  },
                                  decoration: InputDecoration(
                                    hintText: 'e.g., Groceries, Salary, etc.',
                                    prefixIcon: Container(
                                      padding: const EdgeInsets.all(12),
                                      child: const Icon(
                                        Icons.category,
                                        color: AppColors.primaryBlue,
                                        size: 18,
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: AppColors.lightGray,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: AppColors.primaryBlue,
                                        width: 2,
                                      ),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: AppColors.error,
                                        width: 1,
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 20),

                                // Icon Selection
                                const Text(
                                  'Select Icon',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  height: 200, // Increased height for more icons
                                  child: GridView.builder(
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 6,
                                      crossAxisSpacing: 8,
                                      mainAxisSpacing: 8,
                                    ),
                                    itemCount: icons.length,
                                    itemBuilder: (context, index) {
                                      final icon = icons[index];
                                      final isSelected = selectedIcon == icon;
                                      return GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            selectedIcon = icon;
                                          });
                                        },
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? (category.type == TransactionType.income
                                                ? AppColors.success
                                                : AppColors.primaryBlue)
                                                : AppColors.lightGray,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: isSelected
                                                  ? Colors.transparent
                                                  : Colors.grey[300]!,
                                              width: 1,
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              icon,
                                              style: const TextStyle(fontSize: 20),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),

                                const SizedBox(height: 20),

                                // Color Selection
                                const Text(
                                  'Select Color',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  height: 50,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: colors.length,
                                    itemBuilder: (context, index) {
                                      final color = colors[index];
                                      final isSelected = selectedColor.value == color.value;
                                      return GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            selectedColor = color;
                                          });
                                        },
                                        child: Container(
                                          width: 40,
                                          height: 40,
                                          margin: const EdgeInsets.only(right: 12),
                                          decoration: BoxDecoration(
                                            color: color,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: isSelected ? Colors.white : Colors.transparent,
                                              width: 3,
                                            ),
                                            boxShadow: isSelected
                                                ? [
                                              BoxShadow(
                                                color: color.withOpacity(0.5),
                                                blurRadius: 8,
                                                spreadRadius: 2,
                                              ),
                                            ]
                                                : null,
                                          ),
                                          child: isSelected
                                              ? const Center(
                                            child: Icon(
                                              Icons.check,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                          )
                                              : null,
                                        ),
                                      );
                                    },
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // Action Buttons
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () => Navigator.pop(context),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppColors.textSecondary,
                                          side: BorderSide(color: Colors.grey[300]!),
                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                        child: const Text(
                                          'Cancel',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () async {
                                          if (formKey.currentState!.validate()) {
                                            // Show loading indicator
                                            showDialog(
                                              context: context,
                                              barrierDismissible: false,
                                              builder: (context) => const Center(
                                                child: CircularProgressIndicator(),
                                              ),
                                            );

                                            try {
                                              final updatedCategory = Category(
                                                id: category.id,
                                                name: nameController.text.trim(),
                                                icon: selectedIcon,
                                                color: '#${selectedColor.value.toRadixString(16).substring(2)}',
                                                type: category.type,
                                                isDefault: category.isDefault,
                                              );

                                              final categories = await StorageService.getCategories();
                                              final index = categories.indexWhere((c) => c.id == category.id);
                                              if (index != -1) {
                                                categories[index] = updatedCategory;
                                                await StorageService.saveCategories(categories);
                                              }

                                              // Close loading dialog
                                              if (mounted) Navigator.pop(context);

                                              // Close edit dialog
                                              if (mounted) Navigator.pop(context);

                                              // Refresh the list
                                              await _loadCategories();

                                              // Show success message
                                              if (mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Row(
                                                      children: [
                                                        Container(
                                                          padding: const EdgeInsets.all(6),
                                                          decoration: const BoxDecoration(
                                                            color: Colors.white,
                                                            shape: BoxShape.circle,
                                                          ),
                                                          child: Icon(
                                                            Icons.check,
                                                            color: category.type == TransactionType.income
                                                                ? AppColors.success
                                                                : AppColors.primaryBlue,
                                                            size: 14,
                                                          ),
                                                        ),
                                                        const SizedBox(width: 10),
                                                        const Expanded(
                                                          child: Text(
                                                            'Category updated successfully!',
                                                            style: const TextStyle(
                                                              fontSize: 13,
                                                              fontWeight: FontWeight.w600,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    backgroundColor: category.type == TransactionType.income
                                                        ? AppColors.success
                                                        : AppColors.primaryBlue,
                                                    behavior: SnackBarBehavior.floating,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(10),
                                                    ),
                                                    margin: const EdgeInsets.all(16),
                                                    duration: const Duration(seconds: 2),
                                                  ),
                                                );
                                              }
                                            } catch (e) {
                                              if (mounted) Navigator.pop(context); // Close loading
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Row(
                                                    children: [
                                                      const Icon(
                                                        Icons.error_outline,
                                                        color: Colors.white,
                                                        size: 18,
                                                      ),
                                                      const SizedBox(width: 10),
                                                      Expanded(
                                                        child: Text('Error: $e'),
                                                      ),
                                                    ],
                                                  ),
                                                  backgroundColor: AppColors.error,
                                                  behavior: SnackBarBehavior.floating,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                  margin: const EdgeInsets.all(16),
                                                ),
                                              );
                                            }
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: category.type == TransactionType.income
                                              ? AppColors.success
                                              : AppColors.primaryBlue,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          elevation: 0,
                                        ),
                                        child: const Text(
                                          'Save Changes',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _deleteCategory(Category category) async {
    if (category.isDefault) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.info_outline,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Default categories cannot be deleted',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    return showDialog(
      context: context,
      builder: (context) => Dialog(
        elevation: 0,
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 340),
          child: Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header - FIXED: White text and icons
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.delete_outline,
                            color: Colors.white, // FIXED: White icon
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Delete Category',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white, // FIXED: White text
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Content (unchanged)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.lightGray,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: _parseColor(category.color).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    category.icon,
                                    style: const TextStyle(fontSize: 24),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      category.name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      category.type == TransactionType.income
                                          ? 'Income Category'
                                          : 'Expense Category',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Are you sure you want to delete this category?',
                          style: TextStyle(
                            fontSize: 15,
                            color: AppColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'This action cannot be undone. Transactions using this category will be moved to "Other".',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textLight,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),

                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.textSecondary,
                                  side: BorderSide(color: Colors.grey[300]!),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () async {
                                  // Show loading indicator
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (context) => const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  );

                                  try {
                                    // Delete the category
                                    final categories = await StorageService.getCategories();
                                    categories.removeWhere((c) => c.id == category.id);
                                    await StorageService.saveCategories(categories);

                                    // Update any transactions using this category
                                    final transactions = await StorageService.getTransactions();
                                    final updatedTransactions = transactions.map((t) {
                                      if (t.category == category.name) {
                                        // Create a new Transaction object with updated category
                                        return Transaction(
                                          id: t.id,
                                          amount: t.amount,
                                          type: t.type,
                                          category: 'Other', // Changed category
                                          note: t.note,
                                          date: t.date,
                                          account: t.account,
                                          attachmentPath: t.attachmentPath,
                                          isRecurring: t.isRecurring,
                                        );
                                      }
                                      return t;
                                    }).toList();

                                    await StorageService.saveTransactions(updatedTransactions);

                                    // Close loading dialog
                                    if (mounted) Navigator.pop(context);

                                    // Close delete dialog
                                    if (mounted) Navigator.pop(context);

                                    // Refresh the list
                                    await _loadCategories();

                                    // Show success message
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(6),
                                                decoration: const BoxDecoration(
                                                  color: Colors.white,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Icons.check,
                                                  color: AppColors.success,
                                                  size: 14,
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              const Expanded(
                                                child: Text(
                                                  'Category deleted successfully!',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          backgroundColor: AppColors.success,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          margin: const EdgeInsets.all(16),
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (mounted) Navigator.pop(context); // Close loading
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Row(
                                          children: [
                                            const Icon(
                                              Icons.error_outline,
                                              color: Colors.white,
                                              size: 18,
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text('Error: $e'),
                                            ),
                                          ],
                                        ),
                                        backgroundColor: AppColors.error,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        margin: const EdgeInsets.all(16),
                                      ),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.error,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: const Text(
                                  'Delete',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
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
      ),
    );
  }

  Color _parseColor(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    return Color(int.parse('FF$hexColor', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MainLayout(
      currentIndex: 4, // Settings tab
      child: Scaffold(
        backgroundColor: AppColors.lightGray,
        appBar: AppBar(
          title: const Text(
            'Manage Categories',
            style: TextStyle(color: Colors.white), // FIXED: White title
          ),
          backgroundColor: themeProvider.primaryColor,
          foregroundColor: Colors.white, // FIXED: White foreground for all icons
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white), // FIXED: White back button
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white, // FIXED: White text for selected tab
            unselectedLabelColor: Colors.white.withOpacity(0.7), // FIXED: Light white for unselected
            tabs: const [
              Tab(
                icon: Icon(Icons.shopping_bag, color: Colors.white), // FIXED: White icon
                text: 'Expenses',
              ),
              Tab(
                icon: Icon(Icons.trending_up, color: Colors.white), // FIXED: White icon
                text: 'Income',
              ),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
          controller: _tabController,
          children: [
            // Expense Categories Tab
            _buildCategoryList(_expenseCategories, TransactionType.expense),

            // Income Categories Tab
            _buildCategoryList(_incomeCategories, TransactionType.income),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            final isExpenseTab = _tabController.index == 0;
            _addCategory(isExpenseTab ? TransactionType.expense : TransactionType.income);
          },
          backgroundColor: themeProvider.primaryColor,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildCategoryList(List<Category> categories, TransactionType type) {
    if (categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              type == TransactionType.expense
                  ? Icons.shopping_bag_outlined
                  : Icons.trending_up_outlined,
              size: 80,
              color: AppColors.textLight,
            ),
            const SizedBox(height: 16),
            Text(
              'No ${type == TransactionType.expense ? 'expense' : 'income'} categories',
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap + to add a new category',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textLight,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final color = _parseColor(category.color);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  category.icon,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            title: Text(
              category.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            subtitle: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  category.isDefault ? 'Default' : 'Custom',
                  style: TextStyle(
                    fontSize: 12,
                    color: category.isDefault ? AppColors.primaryBlue : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: AppColors.primaryBlue),
                  onPressed: () => _editCategory(category),
                ),
                if (!category.isDefault)
                  IconButton(
                    icon: const Icon(Icons.delete, color: AppColors.error),
                    onPressed: () => _deleteCategory(category),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}