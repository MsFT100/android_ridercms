import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/charging_controller.dart';
import '../../utils/themes/app_theme.dart';
import '../../widgets/common_widgets.dart';

class ChargingScreen extends StatelessWidget {
  const ChargingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Inject the controller
    final controller = Get.put(ChargingController());

    return Scaffold(
      backgroundColor: kBgDark,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 100),
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                    child: Row(
                      children: [
                        const BackBtn(),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Charging Session',
                                style: TextStyle(color: kTextPrimary, fontSize: 20, fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 2),
                              Obx(() => Text(
                                '${controller.batteryStatus.value?.boothUid ?? "Station"} · Active',
                                style: const TextStyle(color: kTextSecondary, fontSize: 12),
                              )),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: kPrimary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              SizedBox(
                                width: 8,
                                height: 8,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(color: kPrimary, shape: BoxShape.circle),
                                ),
                              ),
                              SizedBox(width: 6),
                              Text(
                                'LIVE',
                                style: TextStyle(color: kPrimary, fontSize: 11, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Session timer
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                    child: AppCard(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Session Duration', style: TextStyle(color: kTextSecondary, fontSize: 12)),
                              const SizedBox(height: 4),
                              Obx(() => Text(
                                controller.formatTime(controller.elapsedSeconds.value),
                                style: const TextStyle(
                                  color: kTextPrimary,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'monospace',
                                ),
                              )),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('Battery Status', style: TextStyle(color: kTextSecondary, fontSize: 12)),
                              const SizedBox(height: 4),
                              Obx(() => Text(
                                controller.batteryStatus.value?.sessionStatus.toUpperCase() ?? '...',
                                style: const TextStyle(color: kTextPrimary, fontSize: 18, fontWeight: FontWeight.w700),
                              )),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Battery card
                  Obx(() {
                    final status = controller.batteryStatus.value;
                    if (status == null) return const SizedBox();

                    return Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                      child: AppCard(
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: kWarning.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Center(
                                    child: Icon(Icons.battery_charging_full, size: 24, color: kWarning),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        status.batteryUid,
                                        style: const TextStyle(color: kTextPrimary, fontWeight: FontWeight.w700, fontFamily: 'monospace'),
                                      ),
                                      const SizedBox(height: 2),
                                      RichText(
                                        text: TextSpan(
                                          style: const TextStyle(color: kTextSecondary, fontSize: 12),
                                          children: [
                                            const TextSpan(text: 'Slot: '),
                                            TextSpan(
                                              text: status.slotIdentifier,
                                              style: const TextStyle(color: kPrimary, fontWeight: FontWeight.w600),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: kWarning.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: const [
                                      Icon(Icons.bolt, size: 12, color: kWarning),
                                      SizedBox(width: 4),
                                      Text('Charging', style: TextStyle(color: kWarning, fontSize: 11, fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Charge progress
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Charge Level', style: TextStyle(color: kTextSecondary, fontSize: 12)),
                                Text(
                                  '${status.chargeLevel}%',
                                  style: const TextStyle(color: kPrimary, fontSize: 12, fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            AppProgressBar(value: status.chargeLevel / 100),
                            const SizedBox(height: 12),

                            // Stats row
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(color: kBgCard2, borderRadius: BorderRadius.circular(12)),
                                    child: Column(
                                      children: [
                                        const Text('Temp', style: TextStyle(color: kTextSecondary, fontSize: 11)),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${status.telemetry?['temperature'] ?? "---"}°C',
                                          style: const TextStyle(color: kTextPrimary, fontSize: 13, fontWeight: FontWeight.w700),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(color: kBgCard2, borderRadius: BorderRadius.circular(12)),
                                    child: Column(
                                      children: [
                                        const Text('Voltage', style: TextStyle(color: kTextSecondary, fontSize: 11)),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${status.telemetry?['voltage'] ?? "---"}V',
                                          style: const TextStyle(color: kTextPrimary, fontSize: 13, fontWeight: FontWeight.w700),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                  // ... rest of the static layout (Add another battery, notifications banner) ...
                ],
              ),
            ),
          ),

          // Bottom action
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              decoration: BoxDecoration(
                color: kBgCard,
                border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
              ),
              child: PrimaryButton(
                label: 'Collect Battery →',
                onPressed: () => controller.initiateCollection(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}