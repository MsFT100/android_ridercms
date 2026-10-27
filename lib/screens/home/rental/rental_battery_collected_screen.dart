import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/rental_controller.dart';
import '../../../utils/themes/app_theme.dart';
import '../../../widgets/common_widgets.dart';

/// `collected` step — the rider's own battery has been released.
class RentalBatteryCollectedScreen extends StatelessWidget {
  const RentalBatteryCollectedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<RentalController>();

    return Obx(() {
      final ownSlot = controller.ownSlot.value;
      final slotIdentifier = ownSlot != null && ownSlot.isValid
          ? ownSlot.slotIdentifier
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
              child: const Icon(Icons.check_rounded, color: kPrimary, size: 44),
            ),
            const SizedBox(height: 22),
            const Text(
              'BATTERY COLLECTED',
              style: TextStyle(
                color: kPrimary,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Take your battery',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: kTextPrimary,
                fontSize: 25,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'The slot is open. Your battery has been released from the '
              'charging station and is ready to use.',
              textAlign: TextAlign.center,
              style: TextStyle(color: kTextSecondary, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 26),
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
                  const SizedBox(height: 14),
                  const Divider(height: 1, color: Color(0x1AFFFFFF)),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Icon(Icons.check_circle, color: kPrimary, size: 18),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Rental returned',
                          style: TextStyle(
                            color: kTextSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Text(
                        controller.displayBoothName,
                        style: const TextStyle(
                          color: kTextPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            PrimaryButton(
              label: 'Complete Session',
              onPressed: controller.continueToClosed,
            ),
          ],
        ),
      );
    });
  }
}
