import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/rental_controller.dart';
import 'rental_progress_view.dart';

/// `waiting_return` step — waiting for the hardware to confirm the insert.
class RentalWaitingReturnScreen extends StatelessWidget {
  const RentalWaitingReturnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<RentalController>();

    return Obx(() {
      final slot = controller.returnSlot.value ?? controller.active.value?.returnSlot;

      String? detail;
      if (slot != null && slot.isValid) {
        detail = 'Slot ${slot.slotIdentifier} at '
            '${controller.displayBoothName.isEmpty ? slot.boothUid : controller.displayBoothName}';
      }

      return RentalProgressView(
        title: 'Returning battery',
        subtitle:
            'Insert the battery, connect the plug and close the cabinet.',
        detail: detail,
      );
    });
  }
}
