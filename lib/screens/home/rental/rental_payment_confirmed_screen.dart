import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/rental_controller.dart';
import '../../../utils/themes/app_theme.dart';
import '../../../widgets/common_widgets.dart';

/// `payment_confirmed` step — the consolidated bill has been paid.
class RentalPaymentConfirmedScreen extends StatelessWidget {
  const RentalPaymentConfirmedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<RentalController>();

    return Obx(() {
      final amount = controller.bill.value?.amount ?? 0;

      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
        child: Column(
          children: [
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                color: kPrimary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(color: kPrimary.withValues(alpha: 0.35)),
              ),
              child: const Icon(Icons.check_rounded, color: kPrimary, size: 46),
            ),
            const SizedBox(height: 24),
            const Text(
              'Payment Received',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: kTextPrimary,
                fontSize: 26,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'We received KES ${amount.toStringAsFixed(2)}. Your rental is now '
              'complete — you can unlock your own battery.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: kTextSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: kBgCard,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.receipt_long, color: kPrimary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Paid via M-Pesa',
                          style: TextStyle(
                            color: kTextPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Rental #${controller.sessionId ?? '-'}',
                          style: const TextStyle(
                            color: kTextSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'KES ${amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: kPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            PrimaryButton(
              label: 'Unlock My Battery →',
              onPressed: controller.continueToUnlockOwn,
            ),
          ],
        ),
      );
    });
  }
}
