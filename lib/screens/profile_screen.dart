import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../utils/app_colors.dart';
import '../models/user_model.dart';
import '../models/transaction.dart';
import '../models/budget.dart';
import '../services/storage_service.dart';
import '../services/personality_service.dart';
import '../services/auth_service.dart';
import '../providers/theme_provider.dart';
import '../widgets/main_layout.dart';
import '../widgets/currency_formatter.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserProfile? _user;
  List<Transaction> _transactions = [];
  List<Account> _accounts = [];
  List<Budget> _budgets = [];
  List<SavingsGoal> _goals = [];
  Map<String, dynamic> _personalityAnalysis = {};
  bool _isLoading = true;

  // State for achievements
  bool _showAllAchievements = false;

  // Controllers for editable fields
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();
  final _locationController = TextEditingController();
  final _occupationController = TextEditingController();

  // Focus nodes for form navigation
  final _nameFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _occupationFocus = FocusNode();
  final _locationFocus = FocusNode();
  final _bioFocus = FocusNode();

  // Profile image
  File? _newProfileImage;
  String? _tempImagePath;
  DateTime? _selectedDate;

  // Track original values for unsaved changes detection
  String _originalName = '';
  String _originalPhone = '';
  String _originalBio = '';
  String _originalLocation = '';
  String _originalOccupation = '';
  DateTime? _originalDate;
  String? _originalImagePath; // Store the original image path instead of a boolean flag

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _occupationController.dispose();
    _nameFocus.dispose();
    _phoneFocus.dispose();
    _occupationFocus.dispose();
    _locationFocus.dispose();
    _bioFocus.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    try {
      final user = await StorageService.getUser();
      final transactions = await StorageService.getTransactions();
      final accounts = await StorageService.getAccounts();
      final budgets = await StorageService.getBudgets();
      final goals = await StorageService.getSavingsGoals();

      // Calculate current month totals for personality
      final now = DateTime.now();
      final currentMonthIncome = transactions
          .where((t) => t.type == TransactionType.income &&
          t.date.month == now.month && t.date.year == now.year)
          .fold(0.0, (sum, t) => sum + t.amount);

      final currentMonthExpenses = transactions
          .where((t) => t.type == TransactionType.expense &&
          t.date.month == now.month && t.date.year == now.year)
          .fold(0.0, (sum, t) => sum + t.amount);

      // Get total balance from accounts
      final totalBalance = accounts.fold(0.0, (sum, acc) => sum + acc.balance);

      // Get personality analysis
      _personalityAnalysis = PersonalityService.analyzeSpendingPersonality(
        transactions: transactions,
        budgets: budgets,
        goals: goals,
        monthlyIncome: currentMonthIncome,
        monthlyExpenses: currentMonthExpenses,
        totalBalance: totalBalance,
        currency: user?.preferredCurrency,
      );

      if (mounted) {
        setState(() {
          _user = user;
          _transactions = transactions;
          _accounts = accounts;
          _budgets = budgets;
          _goals = goals;
          _selectedDate = user?.createdAt;

          // Initialize controllers with user data
          _nameController.text = user?.name ?? '';
          _phoneController.text = user?.phone ?? '';
          _bioController.text = user?.bio ?? '';
          _locationController.text = user?.location ?? '';
          _occupationController.text = user?.occupation ?? '';

          // Store original values for unsaved changes detection (trimmed)
          _originalName = user?.name?.trim() ?? '';
          _originalPhone = user?.phone?.trim() ?? '';
          _originalBio = user?.bio?.trim() ?? '';
          _originalLocation = user?.location?.trim() ?? '';
          _originalOccupation = user?.occupation?.trim() ?? '';
          _originalDate = user?.createdAt;
          _originalImagePath = user?.profileImagePath; // Store the actual image path

          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ==============================
  // UNSAVED CHANGES DETECTION (FIXED)
  // ==============================

  bool _hasUnsavedChanges() {
    if (_user == null) return false;

    // Helper function to safely compare strings with trimming
    bool isFieldChanged(String current, String original) {
      final currentTrimmed = current.trim();
      final originalTrimmed = original.trim();

      // Handle empty vs null cases
      if (currentTrimmed.isEmpty && originalTrimmed.isEmpty) return false;
      if (currentTrimmed.isEmpty || originalTrimmed.isEmpty) {
        return currentTrimmed != originalTrimmed;
      }
      return currentTrimmed != originalTrimmed;
    }

    // Check each field with proper trimming and null handling
    final nameChanged = isFieldChanged(_nameController.text, _originalName);
    final phoneChanged = isFieldChanged(_phoneController.text, _originalPhone);
    final bioChanged = isFieldChanged(_bioController.text, _originalBio);
    final locationChanged = isFieldChanged(_locationController.text, _originalLocation);
    final occupationChanged = isFieldChanged(_occupationController.text, _originalOccupation);

    // Date comparison (handle null)
    final dateChanged = _selectedDate?.difference(_originalDate ?? DateTime(1900)).inDays != 0;

    // Image change detection (FIXED - compare actual paths)
    bool imageChanged = false;

    // Get the current displayed image path
    String? currentImagePath;
    if (_newProfileImage != null) {
      currentImagePath = _newProfileImage!.path;
    } else if (_user?.profileImagePath != null && _user!.profileImagePath!.isNotEmpty) {
      currentImagePath = _user!.profileImagePath;
    }

    // Compare current vs original
    if (currentImagePath != _originalImagePath) {
      imageChanged = true;
    }

    return nameChanged || phoneChanged || bioChanged ||
        locationChanged || occupationChanged || dateChanged || imageChanged;
  }

  // Helper to get secondary color based on primary
  Color _getSecondaryColor(Color primary) {
    if (primary == const Color(0xFF007AFF)) return const Color(0xFF00C1D4);
    if (primary == const Color(0xFF34C759)) return const Color(0xFF74C69D);
    if (primary == const Color(0xFFAF52DE)) return const Color(0xFFD291FF);
    if (primary == const Color(0xFF1C1C1E)) return const Color(0xFF3A3A3C);
    return const Color(0xFF00C1D4);
  }

  // ==============================
  // UNSAVED CHANGES DIALOG
  // ==============================

  Future<bool?> _showUnsavedChangesDialog() async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 360),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with theme gradient
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      themeProvider.primaryColor,
                      _getSecondaryColor(themeProvider.primaryColor),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Unsaved Changes',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'You have unsaved profile changes',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Changes summary
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: themeProvider.primaryColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: themeProvider.primaryColor.withOpacity(0.1),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 20,
                                color: themeProvider.primaryColor,
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Would you like to save your changes before leaving?',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildChangeSummaryItem(
                            'Name',
                            _originalName,
                            _nameController.text.trim(),
                            themeProvider,
                          ),
                          _buildChangeSummaryItem(
                            'Phone',
                            _originalPhone,
                            _phoneController.text.trim(),
                            themeProvider,
                          ),
                          _buildChangeSummaryItem(
                            'Occupation',
                            _originalOccupation,
                            _occupationController.text.trim(),
                            themeProvider,
                          ),
                          _buildChangeSummaryItem(
                            'Location',
                            _originalLocation,
                            _locationController.text.trim(),
                            themeProvider,
                          ),
                          _buildChangeSummaryItem(
                            'Bio',
                            _originalBio,
                            _bioController.text.trim(),
                            themeProvider,
                          ),
                          _buildChangeSummaryItem(
                            'Date of Birth',
                            _originalDate != null ? DateFormat('MMM d, yyyy').format(_originalDate!) : 'Not set',
                            _selectedDate != null ? DateFormat('MMM d, yyyy').format(_selectedDate!) : 'Not set',
                            themeProvider,
                          ),
                          _buildImageChangeSummaryItem(themeProvider),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context, false), // Discard
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.error,
                              side: const BorderSide(color: AppColors.error),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              'Discard',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context, true), // Save
                            style: ElevatedButton.styleFrom(
                              backgroundColor: themeProvider.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 2,
                            ),
                            child: const Text(
                              'Save',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Cancel option
                    TextButton(
                      onPressed: () => Navigator.pop(context, null), // Cancel navigation
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                      ),
                      child: const Text(
                        'Stay on Profile',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChangeSummaryItem(String label, String oldValue, String newValue, ThemeProvider themeProvider) {
    // Only show if values are actually different
    if (oldValue.trim() == newValue.trim()) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 4,
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: themeProvider.primaryColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        oldValue.isEmpty ? 'Not set' : oldValue,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textLight,
                          decoration: TextDecoration.lineThrough,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        Icons.arrow_forward,
                        size: 10,
                        color: AppColors.textLight,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        newValue.isEmpty ? 'Not set' : newValue,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: themeProvider.primaryColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageChangeSummaryItem(ThemeProvider themeProvider) {
    // Get current image status
    String? currentImagePath;
    if (_newProfileImage != null) {
      currentImagePath = _newProfileImage!.path;
    } else if (_user?.profileImagePath != null && _user!.profileImagePath!.isNotEmpty) {
      currentImagePath = _user!.profileImagePath;
    }

    // Check if image actually changed
    if (currentImagePath == _originalImagePath) {
      return const SizedBox.shrink();
    }

    // Determine old and new status text
    String oldStatus = _originalImagePath != null && _originalImagePath!.isNotEmpty ? 'Has image' : 'No image';
    String newStatus = currentImagePath != null && currentImagePath.isNotEmpty ? 'Has image' : 'No image';

    // If image path changed but both have images, show as changed
    if (_originalImagePath != null && currentImagePath != null && _originalImagePath != currentImagePath) {
      newStatus = 'New image';
    }
    // If image was removed
    else if (_originalImagePath != null && currentImagePath == null) {
      newStatus = 'Removed';
    }
    // If image was added
    else if (_originalImagePath == null && currentImagePath != null) {
      newStatus = 'Added';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 4,
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: themeProvider.primaryColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Profile Image',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        oldStatus,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textLight,
                          decoration: TextDecoration.lineThrough,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        Icons.arrow_forward,
                        size: 10,
                        color: AppColors.textLight,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        newStatus,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: themeProvider.primaryColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Unsaved Changes Indicator
  Widget _buildUnsavedIndicator(ThemeProvider themeProvider) {
    if (!_hasUnsavedChanges()) return const SizedBox.shrink();

    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      right: 16,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 300),
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.scale(
              scale: value,
              child: child,
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.warning,
                AppColors.warning.withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.warning.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.edit,
                color: Colors.white,
                size: 14,
              ),
              const SizedBox(width: 4),
              const Text(
                'Unsaved',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getUserSubtitle() {
    if (_user?.occupation != null && _user!.occupation!.isNotEmpty) {
      return _user!.occupation!;
    } else if (_user?.location != null && _user!.location!.isNotEmpty) {
      return _user!.location!;
    } else {
      return 'Complete your profile';
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _tempImagePath = image.path;
          _newProfileImage = File(image.path);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image selected successfully'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to pick image'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _takePhotoWithCamera() async {
    try {
      final picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (photo != null) {
        setState(() {
          _tempImagePath = photo.path;
          _newProfileImage = File(photo.path);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo captured successfully'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      print('Error taking photo: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to take photo'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _removeImage() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Image'),
        content: const Text('Are you sure you want to remove your profile image?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _newProfileImage = null;
                _tempImagePath = null;
              });
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Image removed'),
                  backgroundColor: AppColors.warning,
                  duration: Duration(seconds: 1),
                ),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  // Function to show full-size profile image
  void _showFullProfileImage() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background overlay with blur effect
            Container(
              color: Colors.black.withOpacity(0.9),
            ),

            // Close button
            Positioned(
              top: 40,
              right: 20,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),

            // Profile image
            Center(
              child: Hero(
                tag: 'profile_image',
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.8,
                  height: MediaQuery.of(context).size.width * 0.8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: themeProvider.primaryColor.withOpacity(0.3),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                    image: _newProfileImage != null
                        ? DecorationImage(
                      image: FileImage(_newProfileImage!),
                      fit: BoxFit.cover,
                    )
                        : (_user?.profileImagePath != null
                        ? DecorationImage(
                      image: FileImage(File(_user!.profileImagePath!)),
                      fit: BoxFit.cover,
                    )
                        : null),
                  ),
                  child: _newProfileImage == null && _user?.profileImagePath == null
                      ? Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person,
                      size: 100,
                      color: Colors.white.withOpacity(0.5),
                    ),
                  )
                      : null,
                ),
              ),
            ),

            // User name at bottom
            Positioned(
              bottom: 50,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Text(
                    _user?.name ?? 'User',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getUserSubtitle(),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
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

  void _showImagePickerOptions() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Profile Image',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: themeProvider.primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.photo_library,
                      color: themeProvider.primaryColor,
                    ),
                  ),
                  title: const Text('Choose from Gallery'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImageFromGallery();
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.green,
                    ),
                  ),
                  title: const Text('Take a Photo'),
                  onTap: () {
                    Navigator.pop(context);
                    _takePhotoWithCamera();
                  },
                ),
                if (_newProfileImage != null || _user?.profileImagePath != null)
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.delete,
                        color: AppColors.error,
                      ),
                    ),
                    title: const Text(
                      'Remove Current Image',
                      style: TextStyle(color: AppColors.error),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _removeImage();
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveChanges() async {
    if (_user == null) return;

    FocusScope.of(context).unfocus(); // Dismiss keyboard

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Determine the final profile image path
      String? finalImagePath;
      if (_newProfileImage != null) {
        finalImagePath = _newProfileImage!.path;
      } else {
        finalImagePath = _user!.profileImagePath;
      }

      final updatedUser = UserProfile(
        id: _user!.id,
        name: _nameController.text.trim(),
        email: _user!.email,
        phone: _phoneController.text.trim().isEmpty ? _user!.phone : _phoneController.text.trim(),
        profileImagePath: finalImagePath,
        bio: _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
        location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
        occupation: _occupationController.text.trim().isEmpty ? null : _occupationController.text.trim(),
        preferredCurrency: _user!.preferredCurrency,
        theme: _user!.theme,
        notificationsEnabled: _user!.notificationsEnabled,
        budgetAlertsEnabled: _user!.budgetAlertsEnabled,
        dailyRemindersEnabled: _user!.dailyRemindersEnabled,
        createdAt: _selectedDate ?? _user!.createdAt,
        lastLogin: _user!.lastLogin,
      );

      await StorageService.saveUser(updatedUser);

      // Update original values after successful save (FIXED)
      setState(() {
        _user = updatedUser;
        _originalName = _nameController.text.trim();
        _originalPhone = _phoneController.text.trim();
        _originalBio = _bioController.text.trim();
        _originalLocation = _locationController.text.trim();
        _originalOccupation = _occupationController.text.trim();
        _originalDate = _selectedDate;

        // IMPORTANT FIX: Update original image path with the saved path
        _originalImagePath = updatedUser.profileImagePath;

        // Clear temp image after save
        _newProfileImage = null;
        _tempImagePath = null;
      });

      if (mounted) Navigator.pop(context); // Close loading dialog

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile updated successfully!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // Close loading dialog

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  // ==============================
  // LOGOUT FUNCTIONALITY
  // ==============================

  Future<bool> _isAccountSecure() async {
    if (_user == null) return false;
    return await AuthService.userHasPassword(_user!.id);
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // Modern Logout Dialog with security check
  Future<void> _logout() async {
    // First check for unsaved changes
    if (_hasUnsavedChanges()) {
      final shouldSave = await _showUnsavedChangesDialog();

      if (shouldSave == true) {
        // Save changes and then proceed with logout check
        await _saveChanges();
        if (!mounted) return;
      } else if (shouldSave == false) {
        // Discard changes and proceed with logout check
        // Continue to logout check
      } else {
        // Cancel navigation - stay on profile
        return;
      }
    }

    // Proceed with logout security check
    final isSecure = await _isAccountSecure();

    if (!isSecure) {
      _showIncompleteProfileWarning();
      return;
    }

    _showLogoutConfirmationDialog();
  }

  // Modern Logout Confirmation Dialog
  void _showLogoutConfirmationDialog() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 360),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      themeProvider.primaryColor,
                      _getSecondaryColor(themeProvider.primaryColor),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.logout,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Logout',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Sign out of your account',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white70,
                            ),
                          ),
                        ],
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
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: themeProvider.primaryColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 20,
                            color: themeProvider.primaryColor,
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Are you sure you want to logout?',
                              style: TextStyle(
                                fontSize: 15,
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
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
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              Navigator.pop(context); // Close dialog
                              _showLoadingDialog();

                              await AuthService().logout();

                              if (mounted) {
                                Navigator.pop(context); // Close loading
                                Navigator.pushReplacementNamed(context, '/login');
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: themeProvider.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 2,
                            ),
                            child: const Text(
                              'Logout',
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
            ],
          ),
        ),
      ),
    );
  }

  // Modern Incomplete Profile Warning Dialog
  void _showIncompleteProfileWarning() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 360),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Warning Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.warning,
                      Color(0xFFFFA07A),
                    ],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Important!',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Account not protected',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white70,
                            ),
                          ),
                        ],
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
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.warning.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'You haven\'t set up a password yet.',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.warning,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          _buildWarningItem(
                              'All your account data will be permanently deleted'),
                          const SizedBox(height: 8),
                          _buildWarningItem(
                              'You will not be able to recover this account'),
                          const SizedBox(height: 8),
                          _buildWarningItem(
                              'Create a password first to save your data'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

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
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context); // Close warning
                              // Navigate to Privacy & Security to set up password
                              Navigator.pushNamed(context, '/privacy-security');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: themeProvider.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 2,
                            ),
                            child: const Text('Set Password'),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Proceed anyway option
                    TextButton(
                      onPressed: () async {
                        Navigator.pop(context); // Close warning

                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Confirm Logout'),
                            content: const Text(
                              'Are you absolutely sure? All your data will be lost forever.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.error,
                                ),
                                child: const Text('Yes, Delete Data'),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          _showLoadingDialog();

                          try {
                            await StorageService.deleteAllUserData();
                            await AuthService().logout();

                            if (mounted) {
                              Navigator.pop(context); // Close loading
                              Navigator.pushReplacementNamed(context, '/login');
                            }
                          } catch (e) {
                            if (mounted) {
                              Navigator.pop(context);
                              _showErrorSnackBar('Error: ${e.toString()}');
                            }
                          }
                        }
                      },
                      child: const Text(
                        'Proceed anyway (data will be lost)',
                        style: TextStyle(
                          color: AppColors.error,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWarningItem(String text) {
    return Row(
      children: [
        Icon(
          Icons.error_outline,
          size: 16,
          color: AppColors.warning,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  // ==============================
  // ACHIEVEMENT METHODS
  // ==============================

  // Get list of achievements with their conditions
  List<Map<String, dynamic>> _getAllAchievements() {
    final transactionCount = _transactions.length;
    final hasGoals = _goals.isNotEmpty;
    final hasBudgets = _budgets.isNotEmpty;
    final hasBeenActive = _transactions.isNotEmpty &&
        _transactions.any((t) => t.date.isAfter(DateTime.now().subtract(const Duration(days: 30))));

    // Calculate goal completion stats
    final completedGoals = _goals.where((g) => g.progress >= 100).length;
    final behindGoals = _goals.where((g) => g.isBehind).length;

    // Calculate budget stats
    final exceededBudgets = _budgets.where((b) => b.isExceeded).length;
    final onTrackBudgets = _budgets.where((b) => b.isOnTrack).length;

    // Calculate streak (consecutive days with transactions)
    final streak = _calculateStreak();

    // Calculate monthly activity
    final now = DateTime.now();
    final thisMonthCount = _transactions.where((t) =>
    t.date.month == now.month && t.date.year == now.year).length;
    final lastMonthCount = _transactions.where((t) =>
    t.date.month == now.month - 1 && t.date.year == now.year).length;

    return [
      {
        'id': 'first_transaction',
        'name': 'First Transaction',
        'description': 'Record your first transaction',
        'icon': Icons.receipt,
        'achieved': transactionCount > 0,
        'category': 'Getting Started',
        'date': transactionCount > 0 ? _transactions.first.date : null,
      },
      {
        'id': 'ten_transactions',
        'name': 'Getting Started',
        'description': 'Record 10 transactions',
        'icon': Icons.format_list_numbered,
        'achieved': transactionCount >= 10,
        'category': 'Milestones',
        'progress': (transactionCount / 10 * 100).clamp(0, 100),
      },
      {
        'id': 'fifty_transactions',
        'name': 'Regular User',
        'description': 'Record 50 transactions',
        'icon': Icons.star,
        'achieved': transactionCount >= 50,
        'category': 'Milestones',
        'progress': (transactionCount / 50 * 100).clamp(0, 100),
      },
      {
        'id': 'hundred_transactions',
        'name': 'Power User',
        'description': 'Record 100 transactions',
        'icon': Icons.workspace_premium,
        'achieved': transactionCount >= 100,
        'category': 'Milestones',
        'progress': (transactionCount / 100 * 100).clamp(0, 100),
      },
      {
        'id': 'five_hundred_transactions',
        'name': 'Finance Master',
        'description': 'Record 500 transactions',
        'icon': Icons.military_tech,
        'achieved': transactionCount >= 500,
        'category': 'Milestones',
        'progress': (transactionCount / 500 * 100).clamp(0, 100),
      },
      {
        'id': 'goal_setter',
        'name': 'Goal Setter',
        'description': 'Create your first savings goal',
        'icon': Icons.flag,
        'achieved': hasGoals,
        'category': 'Goals',
      },
      {
        'id': 'goal_completer',
        'name': 'Goal Crusher',
        'description': 'Complete your first savings goal',
        'icon': Icons.emoji_events,
        'achieved': completedGoals > 0,
        'category': 'Goals',
        'count': completedGoals,
      },
      {
        'id': 'multiple_goals',
        'name': 'Multi-Tasker',
        'description': 'Have 3 active goals simultaneously',
        'icon': Icons.flag_circle,
        'achieved': _goals.length >= 3,
        'category': 'Goals',
        'progress': (_goals.length / 3 * 100).clamp(0, 100),
      },
      {
        'id': 'goal_master',
        'name': 'Goal Master',
        'description': 'Complete 5 savings goals',
        'icon': Icons.workspace_premium,
        'achieved': completedGoals >= 5,
        'category': 'Goals',
        'progress': (completedGoals / 5 * 100).clamp(0, 100),
      },
      {
        'id': 'budget_creator',
        'name': 'Budget Master',
        'description': 'Create your first budget',
        'icon': Icons.pie_chart,
        'achieved': hasBudgets,
        'category': 'Budgets',
      },
      {
        'id': 'budget_disciplined',
        'name': 'Budget Disciplined',
        'description': 'Stay within all budgets for a month',
        'icon': Icons.check_circle,
        'achieved': _budgets.isNotEmpty && exceededBudgets == 0,
        'category': 'Budgets',
      },
      {
        'id': 'budget_planner',
        'name': 'Budget Planner',
        'description': 'Create 5 budgets',
        'icon': Icons.account_balance,
        'achieved': _budgets.length >= 5,
        'category': 'Budgets',
        'progress': (_budgets.length / 5 * 100).clamp(0, 100),
      },
      {
        'id': 'active_user',
        'name': 'Active User',
        'description': 'Active for 30 consecutive days',
        'icon': Icons.whatshot,
        'achieved': hasBeenActive,
        'category': 'Activity',
      },
      {
        'id': 'streak_7',
        'name': 'Weekly Warrior',
        'description': '7-day activity streak',
        'icon': Icons.local_fire_department,
        'achieved': streak >= 7,
        'category': 'Activity',
        'progress': (streak / 7 * 100).clamp(0, 100),
      },
      {
        'id': 'streak_30',
        'name': 'Monthly Champion',
        'description': '30-day activity streak',
        'icon': Icons.whatshot,
        'achieved': streak >= 30,
        'category': 'Activity',
        'progress': (streak / 30 * 100).clamp(0, 100),
      },
      {
        'id': 'streak_100',
        'name': 'Legend',
        'description': '100-day activity streak',
        'icon': Icons.emoji_events,
        'achieved': streak >= 100,
        'category': 'Activity',
        'progress': (streak / 100 * 100).clamp(0, 100),
      },
      {
        'id': 'early_bird',
        'name': 'Early Bird',
        'description': 'Add transactions before 9 AM',
        'icon': Icons.wb_sunny,
        'achieved': _transactions.any((t) => t.date.hour < 9),
        'category': 'Habits',
      },
      {
        'id': 'night_owl',
        'name': 'Night Owl',
        'description': 'Add transactions after 10 PM',
        'icon': Icons.nightlight,
        'achieved': _transactions.any((t) => t.date.hour >= 22),
        'category': 'Habits',
      },
      {
        'id': 'weekend_planner',
        'name': 'Weekend Planner',
        'description': 'Add transactions on weekends',
        'icon': Icons.weekend,
        'achieved': _transactions.any((t) =>
        t.date.weekday == DateTime.saturday || t.date.weekday == DateTime.sunday),
        'category': 'Habits',
      },
      {
        'id': 'consistent',
        'name': 'Consistent',
        'description': 'Add transactions 5 days in a row',
        'icon': Icons.trending_up,
        'achieved': streak >= 5,
        'category': 'Activity',
      },
      {
        'id': 'saver',
        'name': 'Super Saver',
        'description': 'Save more than you spend for 3 months',
        'icon': Icons.savings,
        'achieved': _checkSaverAchievement(),
        'category': 'Financial',
      },
      {
        'id': 'investor',
        'name': 'Investor',
        'description': 'Create investment category transactions',
        'icon': Icons.trending_up,
        'achieved': _transactions.any((t) => t.category.contains('Investment')),
        'category': 'Financial',
      },
      {
        'id': 'emergency_fund',
        'name': 'Emergency Ready',
        'description': 'Save 3 months of expenses',
        'icon': Icons.security,
        'achieved': _checkEmergencyFund(),
        'category': 'Financial',
      },
      {
        'id': 'debt_free',
        'name': 'Debt Free',
        'description': 'No negative balances in accounts',
        'icon': Icons.credit_score,
        'achieved': _accounts.every((a) => a.balance >= 0),
        'category': 'Financial',
      },
    ];
  }

  int _calculateStreak() {
    if (_transactions.isEmpty) return 0;

    final sortedDates = _transactions.map((t) =>
        DateTime(t.date.year, t.date.month, t.date.day)).toSet().toList()
      ..sort((a, b) => b.compareTo(a));

    int streak = 1;
    for (int i = 0; i < sortedDates.length - 1; i++) {
      final diff = sortedDates[i].difference(sortedDates[i + 1]).inDays;
      if (diff == 1) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  bool _checkSaverAchievement() {
    // Check if savings rate was positive for last 3 months
    final now = DateTime.now();
    int positiveMonths = 0;

    for (int i = 0; i < 3; i++) {
      final month = DateTime(now.year, now.month - i, 1);
      final monthIncome = _transactions
          .where((t) => t.type == TransactionType.income &&
          t.date.month == month.month && t.date.year == month.year)
          .fold(0.0, (sum, t) => sum + t.amount);
      final monthExpenses = _transactions
          .where((t) => t.type == TransactionType.expense &&
          t.date.month == month.month && t.date.year == month.year)
          .fold(0.0, (sum, t) => sum + t.amount);

      if (monthIncome > monthExpenses) positiveMonths++;
    }

    return positiveMonths >= 2;
  }

  bool _checkEmergencyFund() {
    if (_transactions.isEmpty) return false;

    // Calculate average monthly expenses
    final now = DateTime.now();
    double totalExpenses = 0;
    int monthCount = 0;

    for (int i = 0; i < 3; i++) {
      final month = DateTime(now.year, now.month - i, 1);
      final monthExpenses = _transactions
          .where((t) => t.type == TransactionType.expense &&
          t.date.month == month.month && t.date.year == month.year)
          .fold(0.0, (sum, t) => sum + t.amount);

      if (monthExpenses > 0) {
        totalExpenses += monthExpenses;
        monthCount++;
      }
    }

    if (monthCount == 0) return false;

    final avgMonthlyExpenses = totalExpenses / monthCount;
    final totalBalance = _accounts.fold(0.0, (sum, acc) => sum + acc.balance);

    return totalBalance >= avgMonthlyExpenses * 3;
  }

  List<Map<String, dynamic>> _getObtainedAchievements() {
    return _getAllAchievements().where((a) => a['achieved'] == true).toList();
  }

  List<Map<String, dynamic>> _getLockedAchievements() {
    return _getAllAchievements().where((a) => a['achieved'] != true).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final themeProvider = Provider.of<ThemeProvider>(context);
    final currency = _user?.preferredCurrency ?? Currency.npr;
    final primaryPersonality = _personalityAnalysis['primary'] as String? ?? 'The Balanced';
    final reasoning = _personalityAnalysis['reasoning'] as String? ??
        'Your financial personality is still evolving. Keep tracking to discover more insights.';
    final metrics = _personalityAnalysis['metrics'] as Map<String, dynamic>? ?? {};

    final obtainedAchievements = _getObtainedAchievements();
    final lockedAchievements = _getLockedAchievements();
    final displayAchievements = _showAllAchievements ? obtainedAchievements : obtainedAchievements.take(6).toList();

    return WillPopScope(
      onWillPop: () async {
        // Check if there are unsaved changes
        if (_hasUnsavedChanges()) {
          final shouldSave = await _showUnsavedChangesDialog();

          if (shouldSave == true) {
            // Save changes and then pop
            await _saveChanges();
            return true;
          } else if (shouldSave == false) {
            // Discard changes and pop
            return true;
          } else {
            // Cancel navigation
            return false;
          }
        }
        // No unsaved changes, allow pop
        return true;
      },
      child: MainLayout(
        currentIndex: 4,
        child: Scaffold(
          backgroundColor: AppColors.lightGray,
          body: Stack(
            children: [
              SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                child: Column(
                  children: [
                    // Header with Profile Image using theme gradient
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            themeProvider.primaryColor,
                            _getSecondaryColor(themeProvider.primaryColor),
                          ],
                        ),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(32),
                          bottomRight: Radius.circular(32),
                        ),
                      ),
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              const SizedBox(height: 20),
                              // Stack with GestureDetector for full-size view
                              Stack(
                                children: [
                                  GestureDetector(
                                    onTap: _showFullProfileImage,
                                    child: Hero(
                                      tag: 'profile_image',
                                      child: Container(
                                        width: 120,
                                        height: 120,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.2),
                                              blurRadius: 10,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                          image: _newProfileImage != null
                                              ? DecorationImage(
                                            image: FileImage(_newProfileImage!),
                                            fit: BoxFit.cover,
                                          )
                                              : (_user?.profileImagePath != null
                                              ? DecorationImage(
                                            image: FileImage(File(_user!.profileImagePath!)),
                                            fit: BoxFit.cover,
                                          )
                                              : null),
                                        ),
                                        child: _newProfileImage == null && _user?.profileImagePath == null
                                            ? Icon(
                                          Icons.person,
                                          size: 60,
                                          color: themeProvider.primaryColor.withOpacity(0.3),
                                        )
                                            : null,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: GestureDetector(
                                      onTap: _showImagePickerOptions,
                                      child: Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: themeProvider.primaryColor,
                                            width: 2,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.camera_alt,
                                          color: themeProvider.primaryColor,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: MediaQuery.of(context).size.width - 80,
                                ),
                                child: Text(
                                  _user?.name ?? 'User',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _user?.occupation != null && _user!.occupation!.isNotEmpty
                                          ? Icons.work_outline
                                          : Icons.info_outline,
                                      color: Colors.white70,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _getUserSubtitle(),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (_user?.location != null && _user!.location!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.location_on, color: Colors.white70, size: 14),
                                    const SizedBox(width: 4),
                                    Text(
                                      _user!.location!,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: themeProvider.primaryColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      primaryPersonality.replaceFirst('The ', ''),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Profile Form
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          // Personal Information Section with theme
                          _buildSection(
                            title: 'Personal Information',
                            icon: Icons.person_outline,
                            themeProvider: themeProvider,
                            children: [
                              _buildFormField(
                                controller: _nameController,
                                label: 'Full Name',
                                icon: Icons.person_outline,
                                focusNode: _nameFocus,
                                nextFocus: _phoneFocus,
                                textInputAction: TextInputAction.next,
                                themeProvider: themeProvider,
                                onChanged: () => setState(() {}),
                              ),
                              const SizedBox(height: 16),
                              _buildFormField(
                                controller: _phoneController,
                                label: 'Phone Number',
                                icon: Icons.phone_outlined,
                                focusNode: _phoneFocus,
                                nextFocus: _occupationFocus,
                                textInputAction: TextInputAction.next,
                                keyboardType: TextInputType.phone,
                                readOnly: true,
                                themeProvider: themeProvider,
                                onChanged: () => setState(() {}),
                              ),
                              const SizedBox(height: 16),
                              _buildDatePicker(themeProvider),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // About Me Section with theme
                          _buildSection(
                            title: 'About Me',
                            icon: Icons.info_outline,
                            themeProvider: themeProvider,
                            children: [
                              _buildFormField(
                                controller: _occupationController,
                                label: 'Occupation',
                                icon: Icons.work_outline,
                                focusNode: _occupationFocus,
                                nextFocus: _locationFocus,
                                textInputAction: TextInputAction.next,
                                themeProvider: themeProvider,
                                onChanged: () => setState(() {}),
                              ),
                              const SizedBox(height: 16),
                              _buildFormField(
                                controller: _locationController,
                                label: 'Location',
                                icon: Icons.location_on_outlined,
                                focusNode: _locationFocus,
                                nextFocus: _bioFocus,
                                textInputAction: TextInputAction.next,
                                themeProvider: themeProvider,
                                onChanged: () => setState(() {}),
                              ),
                              const SizedBox(height: 16),
                              _buildBioField(themeProvider),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Financial Personality Section with theme
                          _buildPersonalitySection(currency, primaryPersonality, reasoning, metrics, themeProvider),

                          const SizedBox(height: 20),

                          // Achievement Stats Section with theme
                          _buildAchievementSection(
                            themeProvider: themeProvider,
                            obtainedAchievements: obtainedAchievements,
                            displayAchievements: displayAchievements,
                            showAllAchievements: _showAllAchievements,
                            onToggleShowAll: () {
                              setState(() {
                                _showAllAchievements = !_showAllAchievements;
                              });
                            },
                          ),

                          const SizedBox(height: 32),

                          // Save Changes Button with theme
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _saveChanges,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: themeProvider.primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 4,
                              ),
                              child: const Text(
                                'Save Changes',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Logout Button
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: _logout,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.error,
                                side: const BorderSide(color: AppColors.error),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Text(
                                'Logout',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Back button positioned absolutely with unsaved changes check
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                left: 8,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 24,
                    ),
                    onPressed: () async {
                      // Check for unsaved changes before popping
                      if (_hasUnsavedChanges()) {
                        final shouldSave = await _showUnsavedChangesDialog();

                        if (shouldSave == true) {
                          // Save changes and then pop
                          await _saveChanges();
                          if (mounted) Navigator.pop(context);
                        } else if (shouldSave == false) {
                          // Discard changes and pop
                          if (mounted) Navigator.pop(context);
                        }
                        // If shouldSave is null, do nothing (stay on screen)
                      } else {
                        // No unsaved changes, just pop
                        Navigator.pop(context);
                      }
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    splashRadius: 24,
                  ),
                ),
              ),

              // Unsaved changes indicator
              _buildUnsavedIndicator(themeProvider),
            ],
          ),
        ),
      ),
    );
  }

  // Form field with theme
  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required FocusNode focusNode,
    FocusNode? nextFocus,
    TextInputAction? textInputAction,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool readOnly = false,
    required ThemeProvider themeProvider,
    VoidCallback? onChanged,
  }) {
    // Check if this specific field has changes
    bool isFieldChanged() {
      switch (label) {
        case 'Full Name':
          return controller.text.trim() != _originalName;
        case 'Phone Number':
          return controller.text.trim() != _originalPhone;
        case 'Occupation':
          return controller.text.trim() != _originalOccupation;
        case 'Location':
          return controller.text.trim() != _originalLocation;
        default:
          return false;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.lightGray,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isFieldChanged()
                  ? themeProvider.primaryColor
                  : Colors.grey[200]!,
              width: isFieldChanged() ? 2 : 1,
            ),
          ),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            maxLines: maxLines,
            readOnly: readOnly,
            onChanged: (_) {
              setState(() {});
              if (onChanged != null) onChanged();
            },
            onSubmitted: (_) {
              if (nextFocus != null) {
                FocusScope.of(context).requestFocus(nextFocus);
              }
            },
            decoration: InputDecoration(
              prefixIcon: Container(
                margin: const EdgeInsets.all(10),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: themeProvider.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: themeProvider.primaryColor,
                  size: 18,
                ),
              ),
              hintText: 'Enter $label',
              hintStyle: TextStyle(
                fontSize: 15,
                color: Colors.grey[400],
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  // Bio Field with theme
  Widget _buildBioField(ThemeProvider themeProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            'Bio',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.lightGray,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _hasUnsavedChanges() && _bioController.text.trim() != _originalBio
                  ? themeProvider.primaryColor
                  : Colors.grey[200]!,
              width: _hasUnsavedChanges() && _bioController.text.trim() != _originalBio ? 2 : 1,
            ),
          ),
          child: TextField(
            controller: _bioController,
            focusNode: _bioFocus,
            maxLines: 4,
            textInputAction: TextInputAction.done,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => FocusScope.of(context).unfocus(),
            decoration: InputDecoration(
              prefixIcon: Container(
                margin: const EdgeInsets.all(12),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: themeProvider.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.description,
                  color: themeProvider.primaryColor,
                  size: 18,
                ),
              ),
              hintText: 'Tell us about yourself...',
              hintStyle: TextStyle(
                fontSize: 15,
                color: Colors.grey[400],
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  // Financial Personality Section with theme
  Widget _buildPersonalitySection(Currency currency, String personality, String reasoning, Map<String, dynamic> metrics, ThemeProvider themeProvider) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: themeProvider.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.psychology, color: themeProvider.primaryColor, size: 22),
                ),
                const SizedBox(width: 12),
                Text(
                  'Financial Personality',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: themeProvider.primaryColor,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, indent: 16, endIndent: 16),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: themeProvider.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    personality.replaceFirst('The ', ''),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: themeProvider.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  reasoning,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildPersonalityMetric(
                      'Savings Rate',
                      '${metrics['savingsRate']?.toStringAsFixed(1) ?? '0'}%',
                      Icons.trending_up,
                      themeProvider,
                    ),
                    const SizedBox(width: 12),
                    _buildPersonalityMetric(
                      'Emergency',
                      '${metrics['emergencyFundMonths']?.toStringAsFixed(1) ?? '0'}mo',
                      Icons.security,
                      themeProvider,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Personality Metric Helper with theme
  Widget _buildPersonalityMetric(String label, String value, IconData icon, ThemeProvider themeProvider) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.lightGray,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: themeProvider.primaryColor, size: 18),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Achievement Section with theme and see more functionality
  Widget _buildAchievementSection({
    required ThemeProvider themeProvider,
    required List<Map<String, dynamic>> obtainedAchievements,
    required List<Map<String, dynamic>> displayAchievements,
    required bool showAllAchievements,
    required VoidCallback onToggleShowAll,
  }) {
    final lockedCount = _getLockedAchievements().length;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: themeProvider.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.emoji_events_outlined, color: themeProvider.primaryColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Achievements',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: themeProvider.primaryColor,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${obtainedAchievements.length} Earned',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.success,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, indent: 16, endIndent: 16),

          // Achievements Grid
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ...displayAchievements.map((achievement) {
                      return _buildAchievementBadge(
                        achievement['name'],
                        true,
                        achievement['icon'],
                        themeProvider,
                        date: achievement['date'],
                      );
                    }).toList(),
                  ],
                ),

                // See More / Show Less Button
                if (obtainedAchievements.length > 6)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton.icon(
                          onPressed: onToggleShowAll,
                          icon: Icon(
                            showAllAchievements ? Icons.expand_less : Icons.expand_more,
                            color: themeProvider.primaryColor,
                            size: 18,
                          ),
                          label: Text(
                            showAllAchievements ? 'Show Less' : 'See All (${obtainedAchievements.length})',
                            style: TextStyle(
                              color: themeProvider.primaryColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Locked Achievements Summary
                if (lockedCount > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.lightGray,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey[300]!,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.grey[400]!,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.lock,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '$lockedCount more achievements to unlock',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: themeProvider.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Keep going!',
                              style: TextStyle(
                                fontSize: 11,
                                color: themeProvider.primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Achievement Badge Helper with green color for achieved
  Widget _buildAchievementBadge(String label, bool achieved, IconData icon, ThemeProvider themeProvider, {DateTime? date}) {
    final Color achievedColor = AppColors.success; // Green color for achieved

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: achieved
            ? achievedColor.withOpacity(0.1) // Light green background
            : AppColors.lightGray,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: achieved
              ? achievedColor.withOpacity(0.3) // Green border
              : Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: achieved ? achievedColor : AppColors.textLight,
          ),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: achieved ? FontWeight.w600 : FontWeight.normal,
                  color: achieved ? achievedColor : AppColors.textLight,
                ),
              ),
              if (date != null && achieved)
                Text(
                  DateFormat('MMM d').format(date),
                  style: TextStyle(
                    fontSize: 8,
                    color: achievedColor.withOpacity(0.7),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // Section Builder with theme
  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
    required ThemeProvider themeProvider,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: themeProvider.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: themeProvider.primaryColor, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: themeProvider.primaryColor,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, indent: 16, endIndent: 16),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  // Date Picker with theme
  Widget _buildDatePicker(ThemeProvider themeProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            'Date of Birth',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        InkWell(
          onTap: _selectDate,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.lightGray,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _hasUnsavedChanges() && _selectedDate != _originalDate
                    ? themeProvider.primaryColor
                    : Colors.grey[200]!,
                width: _hasUnsavedChanges() && _selectedDate != _originalDate ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: themeProvider.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.cake,
                    color: themeProvider.primaryColor,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedDate != null
                            ? DateFormat('MMMM d, yyyy').format(_selectedDate!)
                            : 'Select your date of birth',
                        style: TextStyle(
                          fontSize: 15,
                          color: _selectedDate != null
                              ? AppColors.textPrimary
                              : Colors.grey[400],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    color: AppColors.textSecondary,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Date Selection with theme
  Future<void> _selectDate() async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final DateTime initialDate = _selectedDate ??
        DateTime.now().subtract(const Duration(days: 365 * 20));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: 450,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      themeProvider.primaryColor,
                      _getSecondaryColor(themeProvider.primaryColor),
                    ],
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.cake,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Select Date of Birth',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
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
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.date,
                    initialDateTime: initialDate,
                    minimumDate: DateTime(1900),
                    maximumDate: DateTime.now(),
                    onDateTimeChanged: (DateTime newDate) {
                      setState(() {
                        _selectedDate = newDate;
                      });
                    },
                    backgroundColor: Colors.white,
                    dateOrder: DatePickerDateOrder.ymd,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeProvider.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Confirm',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}