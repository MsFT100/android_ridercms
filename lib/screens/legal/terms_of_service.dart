import 'package:flutter/material.dart';
import 'package:ridercms/utils/themes/app_theme.dart';
import '../../widgets/common_widgets.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

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
                    'Terms of Service',
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
                    _TermSection(
                      title: '1. Acceptance of Terms',
                      content:
                          'By accessing or using the Ridercms application, you agree to be bound by these Terms of Service. If you do not agree to all of these terms, do not use the service.',
                    ),
                    _TermSection(
                      title: '2. Description of Service',
                      content:
                          'Ridercms provides a platform for battery swapping and charging for electric vehicles. We reserve the right to modify or discontinue the service at any time.',
                    ),
                    _TermSection(
                      title: '3. User Accounts',
                      content:
                          'You are responsible for maintaining the confidentiality of your account and password and for restricting access to your computer or mobile device.',
                    ),
                    _TermSection(
                      title: '4. Fees and Payments',
                      content:
                          'Usage of certain features of the service may require payment of fees. You agree to pay all applicable fees in connection with your use of the service.',
                    ),
                    _TermSection(
                      title: '5. Limitation of Liability',
                      content:
                          'Ridercms shall not be liable for any direct, indirect, incidental, special, or consequential damages resulting from the use or inability to use the service.',
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

class _TermSection extends StatelessWidget {
  final String title;
  final String content;

  const _TermSection({required this.title, required this.content});

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
