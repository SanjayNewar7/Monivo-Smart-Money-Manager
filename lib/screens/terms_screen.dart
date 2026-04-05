import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_colors.dart';
import '../providers/theme_provider.dart';
import '../widgets/main_layout.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.lightGray,
      appBar: AppBar(
        title: const Text(
          'Terms of Service',
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
            _buildSectionTitle('1. Acceptance of Terms'),
            const SizedBox(height: 8),
            _buildSectionContent(
              'By downloading, accessing, or using Monivo ("the App"), you agree to be bound by these Terms of Service. If you do not agree to these terms, please do not use the App.',
            ),
            const SizedBox(height: 20),
            _buildSectionTitle('2. Description of Service'),
            const SizedBox(height: 8),
            _buildSectionContent(
              'Monivo is a personal finance management application that helps users track expenses, create budgets, set savings goals, and gain insights into their spending habits. The App provides tools for financial organization but does not provide financial advice.',
            ),
            const SizedBox(height: 20),
            _buildSectionTitle('3. User Accounts'),
            const SizedBox(height: 8),
            _buildSectionContent(
              'You are responsible for maintaining the confidentiality of your account credentials. You agree to accept responsibility for all activities that occur under your account. You must be at least 13 years old to use this App.',
            ),
            const SizedBox(height: 20),
            _buildSectionTitle('4. Data Privacy'),
            const SizedBox(height: 8),
            _buildSectionContent(
              'Your financial data is stored locally on your device. We do not collect or store your financial information on external servers. Please review our Privacy Policy for more information about how we handle your data.',
            ),
            const SizedBox(height: 20),
            _buildSectionTitle('5. User Conduct'),
            const SizedBox(height: 8),
            _buildSectionContent(
              'You agree not to: (a) use the App for any illegal purpose; (b) attempt to gain unauthorized access to the App or its systems; (c) interfere with or disrupt the App\'s operation; (d) upload malicious code or content.',
            ),
            const SizedBox(height: 20),
            _buildSectionTitle('6. Intellectual Property'),
            const SizedBox(height: 8),
            _buildSectionContent(
              'The App and its original content, features, and functionality are owned by Monivo and are protected by copyright, trademark, and other intellectual property laws.',
            ),
            const SizedBox(height: 20),
            _buildSectionTitle('7. Limitation of Liability'),
            const SizedBox(height: 8),
            _buildSectionContent(
              'Monivo shall not be liable for any indirect, incidental, special, consequential, or punitive damages resulting from your use of or inability to use the App. The App is provided "as is" without warranties of any kind.',
            ),
            const SizedBox(height: 20),
            _buildSectionTitle('8. Modifications to Service'),
            const SizedBox(height: 8),
            _buildSectionContent(
              'We reserve the right to modify or discontinue, temporarily or permanently, the App or any features with or without notice. We shall not be liable to you or any third party for any modification, suspension, or discontinuance.',
            ),
            const SizedBox(height: 20),
            _buildSectionTitle('9. Governing Law'),
            const SizedBox(height: 8),
            _buildSectionContent(
              'These Terms shall be governed by and construed in accordance with the laws of Nepal, without regard to its conflict of law provisions.',
            ),
            const SizedBox(height: 20),
            _buildSectionTitle('10. Contact Information'),
            const SizedBox(height: 8),
            _buildSectionContent(
              'For any questions about these Terms, please contact us at sanjaynewar007@gmail.com.',
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