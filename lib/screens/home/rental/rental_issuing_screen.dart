import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/rental_controller.dart';
import 'rental_progress_view.dart';

/// `issuing` step — the assigned pool slot is being opened.
class RentalIssuingScreen extends StatelessWidget {
  const RentalIssuingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<RentalController>();

    return Obx(() {
      final assigned = controller.assigned.value;
      final detail = assigned == null
          ? null
          : 'Slot ${assigned.slotIdentifier} · '
              '${assigned.batteryUid} (${assigned.chargeLevel}%)';

      return RentalProgressView(
        title: 'Opening your slot',
        subtitle: 'Issuing your rental battery…',
        detail: detail,
      );
    });
  }
}
