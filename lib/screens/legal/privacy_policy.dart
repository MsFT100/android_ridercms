import 'package:flutter/material.dart';
import 'package:ridercms/utils/themes/app_theme.dart';
import '../../widgets/common_widgets.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgDark,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
              child: Row(
                children: [
                  const BackBtn(),
                  const SizedBox(width: 12),
                  const Text(
                    'Privacy Policy',
                    style: TextStyle(
                      color: kTextPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    _PolicySection(
                      title: '1. Information We Collect',
                      content:
                          'We collect information you provide directly to us when you create an account, such as your name, email address, and phone number. We also collect location data to help you find nearby charging stations.',
                    ),
                    _PolicySection(
                      title: '2. How We Use Information',
                      content:
                          'We use the information we collect to provide, maintain, and improve our services, including to process transactions, send you technical notices, and respond to your comments and questions.',
                    ),
                    _PolicySection(
                      title: '3. Sharing of Information',
                      content:
                          'We do not share your personal information with third parties except as described in this policy, such as with your consent or to comply with laws.',
                    ),
                    _PolicySection(
                      title: '4. Security',
                      content:
                          'We take reasonable measures to help protect information about you from loss, theft, misuse, and unauthorized access.',
                    ),
                    _PolicySection(
                      title: '5. Contact Us',
                      content:
                          'If you have any questions about this Privacy Policy, please contact us at support@ridercms.com.',
                    ),
                    SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PolicySection extends StatelessWidget {
  final String title;
  final String content;

  const _PolicySection({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: kPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(
              color: kTextSecondary,
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
