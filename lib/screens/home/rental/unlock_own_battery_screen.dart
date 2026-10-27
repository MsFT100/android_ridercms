import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/rental_controller.dart';
import '../../../utils/themes/app_theme.dart';
import '../../../widgets/common_widgets.dart';

/// `unlock_own` step — opens the slot holding the rider's own battery.
class UnlockOwnBatteryScreen extends StatelessWidget {
  const UnlockOwnBatteryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<RentalController>();

    return Obx(() {
      final ownRef = controller.ownSlot.value;
      final slotIdentifier = ownRef != null && ownRef.isValid
          ? ownRef.slotIdentifier
          : (controller.active.value?.ownDeposit.slotIdentifier ?? '');

      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
        child: Column(
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: kPrimary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(color: kPrimary.withValues(alpha: 0.3)),
              ),
              child: const Icon(Icons.lock_open_rounded, color: kPrimary, size: 38),
            ),
            const SizedBox(height: 24),
            const Text(
              'Unlock your battery',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: kTextPrimary,
                fontSize: 25,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Your payment is complete. Open the slot and take your fully '
              'charged battery home.',
              textAlign: TextAlign.center,
              style: TextStyle(color: kTextSecondary, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 28),
            AppCard(
              child: Column(
                children: [
                  const Text(
                    'YOUR SLOT',
                    style: TextStyle(
                      color: kTextSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    slotIdentifier.isEmpty ? '—' : slotIdentifier,
                    style: const TextStyle(
                      color: kPrimary,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    controller.displayBoothName,
                    style: const TextStyle(
                      color: kTextSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (controller.error.value.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: kDanger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: kDanger.withValues(alpha: 0.3)),
                ),
                child: Text(
                  controller.error.value,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: kDanger, fontSize: 13),
                ),
              ),
            ],
            const SizedBox(height: 28),
            PrimaryButton(
              label: controller.isBusy.value
                  ? 'Opening slot…'
                  : 'Unlock My Battery',
              onPressed: controller.isBusy.value ? null : controller.unlockOwn,
            ),
          ],
        ),
      );
    });
  }
}
