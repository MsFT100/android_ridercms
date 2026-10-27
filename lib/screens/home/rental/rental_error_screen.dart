import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/rental_controller.dart';
import '../../../utils/themes/app_theme.dart';
import '../../../widgets/common_widgets.dart';

/// `error` step — terminal rental failure with a retry gate.
class RentalErrorScreen extends StatelessWidget {
  const RentalErrorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<RentalController>();

    return Obx(() {
      final message = controller.error.value.isEmpty
          ? 'Something went wrong. Please try again.'
          : controller.error.value;
      final canRetry = controller.assigned.value != null;

      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(26),
            decoration: BoxDecoration(
              color: kBgCard,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: kDanger.withValues(alpha: 0.3)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: kDanger.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: kDanger.withValues(alpha: 0.3)),
                  ),
                  child: const Icon(Icons.battery_alert, color: kDanger, size: 34),
                ),
                const SizedBox(height: 22),
                const Text(
                  'Rental could not continue',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: kTextPrimary,
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: kTextSecondary,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 26),
                if (canRetry) ...[
                  PrimaryButton(
                    label: 'Try Again',
                    onPressed: controller.retry,
                  ),
                  const SizedBox(height: 12),
                ],
                GhostButton(
                  label: 'Back to Dashboard',
                  onPressed: controller.finish,
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
