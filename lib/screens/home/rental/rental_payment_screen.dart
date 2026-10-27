import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/rental_controller.dart';
import '../../../utils/themes/app_theme.dart';
import '../../../widgets/common_widgets.dart';

/// `payment` step — M-Pesa STK push plus status polling.
class RentalPaymentScreen extends StatelessWidget {
  const RentalPaymentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<RentalController>();

    Future<void> submit() async {
      final paid = await controller.pay();
      if (paid) controller.continueAfterPayment();
    }

    return Obx(() {
      final stage = controller.paymentStage.value;
      final amount = controller.bill.value?.amount ?? 0;
      final waiting = stage == RentalPaymentStage.waiting;
      final failed = stage == RentalPaymentStage.failed;

      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          children: [
            Row(
              children: [
                BackBtn(
                  onTap: () {
                    if (!waiting) controller.backToBill();
                  },
                ),
                const SizedBox(width: 12),
                const Text(
                  'Pay Bill',
                  style: TextStyle(
                    color: kTextPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: (failed ? kDanger : kPrimary).withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: (failed ? kDanger : kPrimary).withValues(alpha: 0.3),
                ),
              ),
              child: waiting
                  ? const Padding(
                      padding: EdgeInsets.all(28),
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: kPrimary,
                      ),
                    )
                  : Icon(
                      failed ? Icons.error_outline : Icons.smartphone,
                      color: failed ? kDanger : kPrimary,
                      size: 38,
                    ),
            ),
            const SizedBox(height: 24),
            Text(
              failed
                  ? 'Payment not completed'
                  : waiting
                      ? 'Check your phone'
                      : 'Pay with M-Pesa',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: kTextPrimary,
                fontSize: 25,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              failed
                  ? 'The payment was not completed. Please try again.'
                  : waiting
                      ? 'Enter your M-Pesa PIN on the prompt sent to your phone. '
                          'This screen updates automatically.'
                      : 'An STK push will be sent to your phone to confirm the payment.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: kTextSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: kBgCard,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Column(
                children: [
                  const Text(
                    'AMOUNT DUE',
                    style: TextStyle(
                      color: kTextSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'KES ${amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: kPrimary,
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Charging + rental, one payment',
                    style: TextStyle(color: kTextSecondary, fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: waiting
                  ? 'Waiting for confirmation…'
                  : failed
                      ? 'Try Again'
                      : 'Pay KES ${amount.toStringAsFixed(2)} via M-Pesa',
              onPressed: waiting ? null : submit,
            ),
            if (!waiting) ...[
              const SizedBox(height: 12),
              GhostButton(
                label: 'Back to Bill',
                onPressed: () => controller.backToBill(),
              ),
            ],
          ],
        ),
      );
    });
  }
}
