import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/rental_controller.dart';
import 'rental_progress_view.dart';

/// `collecting` step — waiting for the rider to take the issued battery.
class RentalCollectingScreen extends StatelessWidget {
  const RentalCollectingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<RentalController>();

    return Obx(() {
      final assigned = controller.assigned.value;
      final active = controller.active.value;

      String? detail;
      if (assigned != null) {
        detail = 'Slot ${assigned.slotIdentifier} · '
            '${assigned.batteryUid} (${assigned.chargeLevel}%)';
      } else if (active != null && active.batteryUid.isNotEmpty) {
        detail = 'Battery ${active.batteryUid}';
      }

      return RentalProgressView(
        title: 'Collect your battery',
        subtitle:
            'The slot is open. Take the battery out and close the door.',
        detail: detail,
      );
    });
  }
}
