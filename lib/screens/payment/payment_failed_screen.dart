import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../utils/themes/app_theme.dart';
import '../../widgets/common_widgets.dart';

class PaymentFailedScreen extends StatelessWidget {
  const PaymentFailedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String error = Get.arguments?['error'] ?? 'Transaction failed';

    return Scaffold(
      backgroundColor: kBgDark,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            // Error Icon
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: kDanger.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      color: kDanger,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Payment Failed',
              style: TextStyle(
                color: kTextPrimary,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Text(
                error,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: kTextSecondary,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
            ),
            const Spacer(),
            // Bottom Actions
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  PrimaryButton(
                    label: 'Try Again',
                    onPressed: () => Get.back(),
                  ),
                  const SizedBox(height: 12),
                  GhostButton(
                    label: 'Return to Dashboard',
                    onPressed: () => Get.offAllNamed('/dashboard'),
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
