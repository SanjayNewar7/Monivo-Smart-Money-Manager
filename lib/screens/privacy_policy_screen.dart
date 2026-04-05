import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_colors.dart';
import '../providers/theme_provider.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.lightGray,
      appBar: AppBar(
        title: const Text(
          'Privacy Policy',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: themeProvider.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Information We Collect'),
            const SizedBox(height: 8),
            _buildSectionContent(
              'Monivo collects the following information to provide its services:\n\n'
                  '• Personal Information: Name, phone number, and optional profile information like email, occupation, and location.\n\n'
                  '• Financial Information: Transaction data, budget settings, savings goals, and account balances that you voluntarily enter.\n\n'
                  '• Device Information: Basic device information for app functionality and crash reporting.\n\n'
                  '• Usage Data: Anonymous usage statistics to improve the app experience.',
            ),
            const SizedBox(height: 20),
            _buildSectionTitle('How We Use Your Information'),
            const SizedBox(height: 8),
            _buildSectionContent(
              'We use your information to:\n\n'
                  '• Provide and maintain the App\'s core functionality\n'
                  '• Generate personalized spending insights and personality analysis\n'
                  '• Send notifications about budgets, goals, and spending patterns (if enabled)\n'
                  '• Improve and optimize the App based on usage patterns\n'
                  '• Respond to support inquiries and feedback',
            ),
            const SizedBox(height: 20),
            _buildSectionTitle('Data Storage and Security'),
            const SizedBox(height: 8),
            _buildSectionContent(
              'All your financial data is stored locally on your device using encrypted SharedPreferences. We do not transmit your financial data to external servers. Your password is hashed using SHA-256 before storage. We implement industry-standard security measures to protect your information.',
            ),
            const SizedBox(height: 20),
            _buildSectionTitle('Third-Party Services'),
            const SizedBox(height: 8),
            _buildSectionContent(
              'Monivo does not share your personal or financial data with third parties. The App may include links to external websites for informational purposes (e.g., financial tips), but these sites have their own privacy policies.',
            ),
            const SizedBox(height: 20),
            _buildSectionTitle('Your Rights and Choices'),
            const SizedBox(height: 8),
            _buildSectionContent(
              'You have the right to:\n\n'
                  '• Access and export your data\n'
                  '• Correct or update your information\n'
                  '• Delete your account and all associated data\n'
                  '• Opt out of notifications at any time\n'
                  '• Clear local data from the app settings',
            ),
            const SizedBox(height: 20),
            _buildSectionTitle('Children\'s Privacy'),
            const SizedBox(height: 8),
            _buildSectionContent(
              'Monivo is not intended for children under 13 years of age. We do not knowingly collect personal information from children under 13.',
            ),
            const SizedBox(height: 20),
            _buildSectionTitle('Changes to This Policy'),
            const SizedBox(height: 8),
            _buildSectionContent(
              'We may update this Privacy Policy from time to time. We will notify you of any changes by posting the new policy in the app and updating the "Last Updated" date.',
            ),
            const SizedBox(height: 20),
            _buildSectionTitle('Contact Us'),
            const SizedBox(height: 8),
            _buildSectionContent(
              'If you have questions about this Privacy Policy, please contact us at sanjaynewar007@gmail.com.',
            ),
            const SizedBox(height: 30),
            Center(
              child: Text(
                'Last Updated: April 5, 2026',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textLight,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildSectionContent(String content) {
    return Text(
      content,
      style: TextStyle(
        fontSize: 14,
        color: AppColors.textSecondary,
        height: 1.5,
      ),
    );
  }
}