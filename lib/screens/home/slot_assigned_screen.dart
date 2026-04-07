import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/slot_assigned_controller.dart';
import '../../utils/themes/app_theme.dart';
import '../../widgets/common_widgets.dart';

class SlotAssignedScreen extends StatelessWidget {
  const SlotAssignedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Inject the controller
    final controller = Get.put(SlotAssignedController());

    return Scaffold(
      backgroundColor: kBgDark,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 24),
                child: Row(
                  children: [
                    const BackBtn(),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Slot Assigned',
                            style: TextStyle(
                                color: kTextPrimary,
                                fontSize: 20,
                                fontWeight: FontWeight.w700)),
                        Obx(() => Text(controller.boothName.value,
                            style: const TextStyle(
                                color: kTextSecondary, fontSize: 12))),
                      ],
                    ),
                  ],
                ),
              ),

              // Slot info
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0d2a1a), Color(0xFF0a1f14)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: kPrimary.withValues(alpha: 0.2)),
                ),
                child: Column(
                  children: [
                    const Text('Your Assigned Slot',
                        style: TextStyle(color: kTextSecondary, fontSize: 12)),
                    const SizedBox(height: 8),
                    Obx(() => Text(
                      controller.slotIdentifier.value,
                      style: const TextStyle(
                          color: kPrimary,
                          fontSize: 72,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'monospace'),
                    )),
                    const Text('Please insert your battery now',
                        style: TextStyle(color: kTextSecondary, fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Door status card
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Door Status',
                        style: TextStyle(
                            color: kTextSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 16),

                    // Animated door
                    Center(
                      child: Obx(() => AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        width: 120,
                        height: 150,
                        decoration: BoxDecoration(
                          color: _getDoorBg(controller.doorStatus.value),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: _getDoorColor(controller.doorStatus.value),
                              width: 2),
                          boxShadow: controller.doorStatus.value == DoorStatus.open
                              ? [
                            BoxShadow(
                                color: kPrimary.withValues(alpha: 0.3),
                                blurRadius: 30)
                          ]
                              : [],
                        ),
                        child: Center(
                            child: Icon(_getDoorIcon(controller.doorStatus.value),
                                size: 56,
                                color: _getDoorColor(controller.doorStatus.value))),
                      )),
                    ),
                    const SizedBox(height: 24),

                    // Status label
                    Obx(() => Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getStatusLabel(controller.doorStatus.value),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _getDoorColor(controller.doorStatus.value),
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Instructions
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kWarning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: kWarning.withValues(alpha: 0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lightbulb, size: 20, color: kWarning),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Instructions',
                              style: TextStyle(
                                  color: kWarning,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Obx(() => Text(
                            'Insert your battery firmly into slot ${controller.slotIdentifier.value}. The session will start automatically once detected.',
                            style: const TextStyle(
                                color: kTextSecondary,
                                fontSize: 12,
                                height: 1.5),
                          )),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Bottom Actions
              Obx(() => controller.doorStatus.value == DoorStatus.closed
                  ? PrimaryButton(
                      label: 'View Charging Session →',
                      onPressed: () => Get.offAllNamed('/charging'),
                    )
                  : Column(
                      children: [
                        const CircularProgressIndicator(color: kPrimary),
                        const SizedBox(height: 24),
                        GhostButton(
                          label: 'Cancel Session',
                          onPressed: () => controller.cancelSession(),
                        ),
                      ],
                    )),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // Helper methods for styles
  Color _getDoorBg(DoorStatus status) {
    switch (status) {
      case DoorStatus.closed: return kAccent.withValues(alpha: 0.15);
      case DoorStatus.opening:
      case DoorStatus.closing: return kWarning.withValues(alpha: 0.15);
      default: return kPrimary.withValues(alpha: 0.15);
    }
  }

  Color _getDoorColor(DoorStatus status) {
    switch (status) {
      case DoorStatus.closed: return kAccent;
      case DoorStatus.opening:
      case DoorStatus.closing: return kWarning;
      default: return kPrimary;
    }
  }

  IconData _getDoorIcon(DoorStatus status) {
    switch (status) {
      case DoorStatus.closed: return Icons.lock;
      case DoorStatus.opening:
      case DoorStatus.closing: return Icons.hourglass_top;
      default: return Icons.lock_open;
    }
  }

  String _getStatusLabel(DoorStatus status) {
    switch (status) {
      case DoorStatus.opening: return 'Opening door...';
      case DoorStatus.open: return 'Door Open – Insert Battery';
      case DoorStatus.insert: return 'Battery Detected';
      case DoorStatus.closing: return 'Closing door...';
      case DoorStatus.closed: return 'Charging Started!';
    }
  }
}
