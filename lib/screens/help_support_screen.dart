import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/app_colors.dart';
import '../providers/theme_provider.dart';
import '../widgets/main_layout.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({Key? key}) : super(key: key);

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<int> _expandedFaqs = [];

// FAQ Categories
  final List<Map<String, dynamic>> _faqCategories = [
    {'id': 'all', 'name': 'All', 'icon': Icons.list},
    {'id': 'account', 'name': 'Account', 'icon': Icons.person},
    {'id': 'transactions', 'name': 'Transactions', 'icon': Icons.receipt},
    {'id': 'budgets', 'name': 'Budgets', 'icon': Icons.pie_chart},
    {'id': 'goals', 'name': 'Goals', 'icon': Icons.flag},
    {'id': 'security', 'name': 'Security', 'icon': Icons.security},
    {'id': 'troubleshooting', 'name': 'Troubleshooting', 'icon': Icons.build},
  ];

  String _selectedCategory = 'all';

// FAQ Data
  final List<Map<String, dynamic>> _faqs = [
    {
      'id': 1,
      'question': 'How do I create a new account?',
      'answer': 'To create a new account, tap on "Create one" on the login screen. You\'ll be guided through a simple onboarding process where you\'ll enter your name, phone number, and preferences. After completing onboarding, you\'ll need to set up a password and security question in the Privacy & Security section to secure your account.',
      'category': 'account',
      'popular': true,
    },
    {
      'id': 2,
      'question': 'How do I add a transaction?',
      'answer': 'To add a transaction, go to the Dashboard or Transactions screen and tap the + button at the bottom right. Select whether it\'s an income or expense, choose a category, enter the amount, and add a note if desired. You can also select the account and date for the transaction.',
      'category': 'transactions',
      'popular': true,
    },
    {
      'id': 3,
      'question': 'How do I create a budget?',
      'answer': 'To create a budget, go to the Budgets screen and tap the + button at the top right. Enter a budget name, set a limit, choose a category, and select the period (weekly, monthly, or yearly). The app will automatically track your spending against this budget.',
      'category': 'budgets',
      'popular': true,
    },
    {
      'id': 4,
      'question': 'How do I set up a savings goal?',
      'answer': 'To set up a savings goal, go to the Budgets screen and tap the flag icon at the top right. Enter a goal name, target amount, current savings, and target date. You can also enable auto-save and set a color theme for your goal.',
      'category': 'goals',
      'popular': true,
    },
    {
      'id': 5,
      'question': 'How do I change my password?',
      'answer': 'To change your password, go to Settings → Privacy & Security → Security → Change Password. You\'ll need to enter your current password and then your new password. Make sure your new password is at least 6 characters long.',
      'category': 'security',
      'popular': true,
    },
    {
      'id': 6,
      'question': 'What should I do if I forget my password?',
      'answer': 'If you forget your password, tap on "Forgot Password?" on the login screen. Enter your phone number, and you\'ll be prompted to answer your security question. After answering correctly, you can set a new password.',
      'category': 'security',
      'popular': true,
    },
    {
      'id': 7,
      'question': 'How do I edit or delete a transaction?',
      'answer': 'To edit a transaction, go to the Transactions screen and tap on the transaction you want to modify. This will open the transaction details where you can make changes. To delete, tap the delete icon in the transaction details or swipe left on the transaction in the list.',
      'category': 'transactions',
      'popular': false,
    },
    {
      'id': 8,
      'question': 'How do I add a new account (bank account)?',
      'answer': 'To add a new account, go to Settings → Linked Accounts → Add Account. Enter the account name, bank name, and initial balance. This will add the account to your dashboard for tracking.',
      'category': 'account',
      'popular': false,
    },
    {
      'id': 9,
      'question': 'How do I change my currency preference?',
      'answer': 'To change your currency, go to Settings → Preferences → Currency. Select your preferred currency from the list. The app supports NPR, INR, USD, EUR, GBP, JPY, and more.',
      'category': 'account',
      'popular': false,
    },
    {
      'id': 10,
      'question': 'How do I change the app theme?',
      'answer': 'To change the app theme, go to Settings → Preferences → Theme. You can choose from Blue, Green, Purple, and Dark themes. The theme will be applied throughout the app.',
      'category': 'account',
      'popular': false,
    },
    {
      'id': 11,
      'question': 'How do I manage categories?',
      'answer': 'To manage categories, go to Settings → General → Manage Categories. You can add, edit, or delete expense and income categories. Default categories cannot be deleted.',
      'category': 'transactions',
      'popular': false,
    },
    {
      'id': 12,
      'question': 'What are the notification types?',
      'answer': 'Monivo sends three types of notifications: 1) Budget alerts when you\'re approaching or exceeding budget limits, 2) Savings goal reminders every 3 days, and 3) Spending insights with personalized tips three times a week.',
      'category': 'troubleshooting',
      'popular': false,
    },
    {
      'id': 13,
      'question': 'Why am I not receiving notifications?',
      'answer': 'If you\'re not receiving notifications, check: 1) Notification settings in the app (Settings → Notifications), 2) Device notification settings for Monivo, 3) Battery optimization settings (may block notifications), and 4) Ensure you\'ve granted notification permission when prompted.',
      'category': 'troubleshooting',
      'popular': true,
    },
    {
      'id': 14,
      'question': 'How do I clear all app data?',
      'answer': 'To clear local app data, go to Settings → Privacy → Clear Local Data. This will remove all transactions, budgets, and goals from this device, but your account will remain active.',
      'category': 'account',
      'popular': false,
    },
    {
      'id': 15,
      'question': 'How do I delete my account?',
      'answer': 'To delete your account, go to Settings → Privacy → Delete Account. You\'ll need to confirm by typing "DELETE" and enter your password. This action is permanent and all your data will be lost.',
      'category': 'security',
      'popular': false,
    },
    {
      'id': 16,
      'question': 'Is my data secure?',
      'answer': 'Yes, Monivo takes security seriously. All passwords are hashed using SHA-256, and your data is stored locally on your device. We recommend setting up a strong password and security question to protect your account.',
      'category': 'security',
      'popular': true,
    },
    {
      'id': 17,
      'question': 'How do I view spending insights?',
      'answer': 'Spending insights are automatically generated based on your transaction history. You can view them on the Dashboard in the "Spending Insights" section, or go to the Spending Insights screen for detailed analysis.',
      'category': 'analytics',
      'popular': false,
    },
    {
      'id': 18,
      'question': 'What is my spending personality?',
      'answer': 'Your spending personality is an analysis of your financial habits based on your transactions, budgets, and goals. It categorizes you into types like "The Saver", "The Planner", "The Investor", etc., with personalized advice.',
      'category': 'analytics',
      'popular': false,
    },
    {
      'id': 19,
      'question': 'How do I export my data?',
      'answer': 'Data export feature is coming soon! We\'re working on allowing you to export your transactions and reports in CSV and PDF formats.',
      'category': 'account',
      'popular': false,
    },
    {
      'id': 20,
      'question': 'How do I contact support?',
      'answer': 'You can contact our support team at sanjaynewar007@gmail.com. We typically respond within 24-48 hours. You can also use the contact options below to send us a message directly.',
      'category': 'troubleshooting',
      'popular': true,
    },
  ];

// Quick Tips
  final List<Map<String, dynamic>> _quickTips = [
    {
      'title': 'Quick Transaction Entry',
      'description': 'Use the + button on Dashboard for fast transaction entry',
      'icon': Icons.speed,
    },
    {
      'title': 'Budget Alerts',
      'description': 'Enable budget alerts to stay on top of your spending',
      'icon': Icons.notifications_active,
    },
    {
      'title': 'Dark Theme',
      'description': 'Switch to dark theme for easier night viewing',
      'icon': Icons.dark_mode,
    },
    {
      'title': 'Goal Tracking',
      'description': 'Set up auto-save to reach your goals faster',
      'icon': Icons.auto_graph,
    },
    {
      'title': 'Category Management',
      'description': 'Customize categories to match your spending habits',
      'icon': Icons.category,
    },
    {
      'title': 'Security First',
      'description': 'Set up a security question for account recovery',
      'icon': Icons.security,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  List<Map<String, dynamic>> get _filteredFaqs {
    return _faqs.where((faq) {
// Filter by category
      if (_selectedCategory != 'all' && faq['category'] != _selectedCategory) {
        return false;
      }

// Filter by search query
      if (_searchQuery.isNotEmpty) {
        return faq['question'].toLowerCase().contains(_searchQuery) ||
            faq['answer'].toLowerCase().contains(_searchQuery);
      }

      return true;
    }).toList();
  }

  List<Map<String, dynamic>> get _popularFaqs {
    return _faqs.where((faq) => faq['popular'] == true).toList();
  }

  void _toggleFaq(int id) {
    setState(() {
      if (_expandedFaqs.contains(id)) {
        _expandedFaqs.remove(id);
      } else {
        _expandedFaqs.add(id);
      }
    });
  }

  Future<void> _launchEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'sanjaynewar007@gmail.com',
      query: encodeQueryParameters(<String, String>{
        'subject': 'Monivo App Support',
      }),
    );

    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        _showErrorSnackBar('Could not launch email app');
      }
    } catch (e) {
      _showErrorSnackBar('Error launching email: $e');
    }
  }

  Future<void> _openPlayStore() async {
    final Uri playStoreUri = Uri.parse('https://play.google.com/store/apps/details?id=com.sanjaya.monivo');

    try {
      if (await canLaunchUrl(playStoreUri)) {
        await launchUrl(playStoreUri, mode: LaunchMode.externalApplication);
      } else {
        _showErrorSnackBar('Could not open Play Store');
      }
    } catch (e) {
      _showErrorSnackBar('Error opening Play Store: $e');
    }
  }

  String? encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
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

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showContactDialog() {
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
                      AppColors.accentTeal,
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
                        Icons.support_agent,
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
                            'Contact Support',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'We\'re here to help',
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
                        border: Border.all(
                          color: themeProvider.primaryColor.withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.email_outlined,
                                size: 20,
                                color: AppColors.primaryBlue,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Email us at:',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SelectableText(
                            'sanjaynewar007@gmail.com',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: themeProvider.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 16),
                          const Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 20,
                                color: AppColors.primaryBlue,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Response Time:',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'We typically respond within 24-48 hours',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
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
                            onPressed: () {
                              Navigator.pop(context);
                              _launchEmail();
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
                              'Send Email',
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

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MainLayout(
      currentIndex: 4, // Settings tab
      child: Scaffold(
        backgroundColor: AppColors.lightGray,
        appBar: AppBar(
          title: const Text(
            'Help & Support',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: themeProvider.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withOpacity(0.7),
            tabs: const [
              Tab(text: 'FAQ', icon: Icon(Icons.help_outline)),
              Tab(text: 'Contact', icon: Icon(Icons.support_agent)),
              Tab(text: 'Tips', icon: Icon(Icons.lightbulb_outline)),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
// FAQ Tab
            _buildFaqTab(themeProvider),

// Contact Tab
            _buildContactTab(themeProvider),

// Tips Tab
            _buildTipsTab(themeProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqTab(ThemeProvider themeProvider) {
    return Column(
      children: [
// Search Bar
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search FAQs...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                    },
                  )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: AppColors.lightGray,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),

// Category Chips
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _faqCategories.map((category) {
                    final isSelected = _selectedCategory == category['id'];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(category['name']),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategory = category['id'];
                          });
                        },
                        backgroundColor: Colors.grey[100],
                        selectedColor: themeProvider.primaryColor,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : AppColors.textSecondary,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                        avatar: Icon(
                          category['icon'],
                          size: 16,
                          color: isSelected ? Colors.white : themeProvider.primaryColor,
                        ),
                        showCheckmark: false,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),

// FAQ List
        Expanded(
          child: _filteredFaqs.isEmpty
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off,
                  size: 64,
                  color: AppColors.textLight.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No FAQs found',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _searchQuery.isNotEmpty
                      ? 'No results for "$_searchQuery"'
                      : 'Try selecting a different category',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
          )
              : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _filteredFaqs.length,
            itemBuilder: (context, index) {
              final faq = _filteredFaqs[index];
              final isExpanded = _expandedFaqs.contains(faq['id']);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Theme(
                  data: Theme.of(context).copyWith(
                    dividerColor: Colors.transparent,
                  ),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    expandedCrossAxisAlignment: CrossAxisAlignment.start,
                    onExpansionChanged: (expanded) => _toggleFaq(faq['id']),
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: themeProvider.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getCategoryIcon(faq['category']),
                        color: themeProvider.primaryColor,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      faq['question'],
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    subtitle: faq['popular']
                        ? Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.greenAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Popular',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.blue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                        : null,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Text(
                          faq['answer'],
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildContactTab(ThemeProvider themeProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
// Contact Card
          Container(
            padding: const EdgeInsets.all(24),
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
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: themeProvider.primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.support_agent,
                    size: 48,
                    color: themeProvider.primaryColor,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Get in Touch',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'We\'re here to help with any questions or issues',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

// Email Option
                _buildContactOption(
                  icon: Icons.email_outlined,
                  title: 'Email Support',
                  subtitle: 'sanjaynewar007@gmail.com',
                  color: themeProvider.primaryColor,
                  onTap: _launchEmail,
                ),

                const SizedBox(height: 16),

// Feedback Option - Now opens Play Store
                _buildContactOption(
                  icon: Icons.feedback_outlined,
                  title: 'Rate & Review',
                  subtitle: 'Help us improve Monivo by rating on Play Store',
                  color: Colors.orange,
                  onTap: _openPlayStore,
                ),

                const SizedBox(height: 16),

// FAQ Option
                _buildContactOption(
                  icon: Icons.help_outline,
                  title: 'Browse FAQs',
                  subtitle: 'Find answers to common questions',
                  color: Colors.green,
                  onTap: () {
                    _tabController.animateTo(0);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

// Response Time Card
          Container(
            padding: const EdgeInsets.all(20),
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
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.access_time,
                    color: AppColors.success,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Response Time',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'We typically respond within 24-48 hours',
                        style: TextStyle(
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

          const SizedBox(height: 20),

// App Info Card
          Container(
            padding: const EdgeInsets.all(20),
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
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.info_outline,
                        color: AppColors.primaryBlue,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'App Information',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Monivo v1.0.8',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildInfoItem('Developed by', 'Sanjaya Rajbhandari'),
                    Container(
                      height: 30,
                      width: 1,
                      color: Colors.grey[300],
                    ),
                    _buildInfoItem('Last Update', '5 April 2026'),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

// Contact Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showContactDialog,
              icon: const Icon(Icons.email_outlined),
              label: const Text('Contact Support'),
              style: ElevatedButton.styleFrom(
                backgroundColor: themeProvider.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildTipsTab(ThemeProvider themeProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  themeProvider.primaryColor,
                  AppColors.accentTeal,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: themeProvider.primaryColor.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '💡 Quick Tips',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Get the most out of Monivo with these helpful tips',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          ...List.generate(_quickTips.length, (index) {
            final tip = _quickTips[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: themeProvider.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      tip['icon'],
                      color: themeProvider.primaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tip['title'],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          tip['description'],
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
            );
          }),

          const SizedBox(height: 20),

// Pro Tip Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.amber,
                  Colors.orange,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.emoji_events,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pro Tip',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Set up automatic notifications to never miss a budget alert!',
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

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildContactOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: color,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textLight,
          ),
        ),
      ],
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'account':
        return Icons.person;
      case 'transactions':
        return Icons.receipt;
      case 'budgets':
        return Icons.pie_chart;
      case 'goals':
        return Icons.flag;
      case 'security':
        return Icons.security;
      case 'troubleshooting':
        return Icons.build;
      case 'analytics':
        return Icons.analytics;
      default:
        return Icons.help_outline;
    }
  }
}