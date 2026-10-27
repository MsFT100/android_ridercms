import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/rental_controller.dart';
import '../../../utils/themes/app_theme.dart';
import '../../../widgets/common_widgets.dart';

/// `charging_complete` step — the rental is back and the rider's own battery
/// has finished charging.
class OwnBatteryChargingCompleteScreen extends StatelessWidget {
  const OwnBatteryChargingCompleteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<RentalController>();

    return Obx(() {
      final soc = controller.active.value?.ownDeposit.currentSoc ?? 100;

      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          children: [
            const SizedBox(height: 24),
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: kPrimary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(color: kPrimary.withValues(alpha: 0.3)),
              ),
              child: const Icon(Icons.battery_charging_full,
                  color: kPrimary, size: 40),
            ),
            const SizedBox(height: 24),
            const Text(
              'Your battery is ready',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: kTextPrimary,
                fontSize: 26,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'The rental battery is safely returned and your own battery has '
              'finished charging.',
              textAlign: TextAlign.center,
              style: TextStyle(color: kTextSecondary, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 28),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: kBgCard,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Column(
                children: [
                  const Text(
                    'YOUR BATTERY',
                    style: TextStyle(
                      color: kTextSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '$soc%',
                    style: const TextStyle(
                      color: kPrimary,
                      fontSize: 44,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Fully charged and waiting in its slot',
                    style: TextStyle(color: kTextSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            PrimaryButton(
              label: 'View My Bill →',
              onPressed: () => controller.goTo(RentalStep.bill),
            ),
          ],
        ),
      );
    });
  }
}
