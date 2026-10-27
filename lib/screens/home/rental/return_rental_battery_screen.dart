import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/rental_controller.dart';
import '../../../utils/themes/app_theme.dart';
import '../../../widgets/common_widgets.dart';

/// `return` step — the rider picks the booth and opens the return slot.
class ReturnRentalBatteryScreen extends StatelessWidget {
  const ReturnRentalBatteryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<RentalController>();

    return Obx(() {
      final slot = controller.returnSlot.value ?? controller.active.value?.returnSlot;

      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                BackBtn(onTap: () => controller.goTo(RentalStep.active)),
                const SizedBox(width: 12),
                const Text(
                  'Return Battery',
                  style: TextStyle(
                    color: kTextPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: kAccent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: kAccent.withValues(alpha: 0.3)),
              ),
              child: const Icon(Icons.keyboard_return, color: kAccent, size: 32),
            ),
            const SizedBox(height: 20),
            const Text(
              'Return your rental battery',
              style: TextStyle(
                color: kTextPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Bring the rental battery back to '
              '${controller.displayBoothName.isEmpty ? 'the station' : controller.displayBoothName} '
              'and open a free slot.',
              style: const TextStyle(
                color: kTextSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            AppCard(
              child: Column(
                children: [
                  _InfoRow(
                    label: 'RENTAL BATTERY',
                    value: controller.rentalBatteryId,
                    mono: true,
                  ),
                  const SizedBox(height: 14),
                  _InfoRow(
                    label: 'STATION',
                    value: controller.displayBoothName,
                  ),
                  const SizedBox(height: 14),
                  _InfoRow(
                    label: 'RETURN SLOT',
                    value: slot != null && slot.isValid
                        ? slot.slotIdentifier
                        : 'Assigning…',
                    highlight: slot != null && slot.isValid,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AppCard(
              padding: const EdgeInsets.all(16),
              borderColor: kAccent.withValues(alpha: 0.25),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, size: 18, color: kAccent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      slot != null && slot.isValid
                          ? 'Slot ${slot.slotIdentifier} is open. Insert the battery, '
                              'connect the plug and close the cabinet door.'
                          : 'Your slot opens when you tap Open Return Slot.',
                      style: const TextStyle(
                        color: kTextSecondary,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (controller.returnError.value.isNotEmpty) ...[
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
                  controller.returnError.value,
                  style: const TextStyle(color: kDanger, fontSize: 13),
                ),
              ),
            ],
            const SizedBox(height: 24),
            PrimaryButton(
              label: controller.isBusy.value
                  ? 'Opening return slot…'
                  : slot != null && slot.isValid
                      ? 'Continue with Slot ${slot.slotIdentifier}'
                      : 'Open Return Slot',
              onPressed: controller.isBusy.value
                  ? null
                  : () => controller.requestReturn(),
            ),
          ],
        ),
      );
    });
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool mono;
  final bool highlight;

  const _InfoRow({
    required this.label,
    required this.value,
    this.mono = false,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: kTextSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: highlight ? kPrimary : kTextPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            fontFamily: mono ? 'monospace' : null,
          ),
        ),
      ],
    );
  }
}
