import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/collect_controller.dart';
import '../../utils/themes/app_theme.dart';
import '../../widgets/common_widgets.dart';

class CollectScreen extends StatelessWidget {
  const CollectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Inject the controller
    final controller = Get.put(CollectController());

    return Scaffold(
      backgroundColor: kBgDark,
      body: SafeArea(
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
                        const Text('Collect Battery',
                            style: TextStyle(color: kTextPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
                        Obx(() => Text(controller.batteryStatus.value?.boothUid ?? "Station",
                            style: const TextStyle(color: kTextSecondary, fontSize: 12))),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Obx(() {
                if (controller.isLoading.value && controller.batteryStatus.value == null) {
                  return const Center(child: CircularProgressIndicator(color: kPrimary));
                }

                if (controller.isCollected.value) {
                  return _buildSuccessState(controller);
                }

                final status = controller.batteryStatus.value;
                if (status == null) return const SizedBox();

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      // Instruction banner
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: kPrimary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: kPrimary.withValues(alpha: 0.2)),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('🔓', style: TextStyle(fontSize: 20)),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Door is Open!',
                                      style: TextStyle(color: kPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                                  SizedBox(height: 4),
                                  Text(
                                    'Your slot is now unlocked. Please retrieve your battery and close the door.',
                                    style: TextStyle(color: kTextSecondary, fontSize: 12, height: 1.5),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Slot card
                      AppCard(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: kPrimary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                                border: Border.all(color: kPrimary, width: 2),
                              ),
                              child: Center(
                                child: Text(
                                  status.slotIdentifier,
                                  style: const TextStyle(
                                    color: kPrimary,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(status.batteryUid,
                                style: const TextStyle(color: kTextPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            const Text('Ready for collection',
                                style: TextStyle(color: kTextSecondary, fontSize: 13)),
                          ],
                        ),
                      ),

                      const SizedBox(height: 48),
                      const CircularProgressIndicator(color: kPrimary, strokeWidth: 2),
                      const SizedBox(height: 16),
                      const Text('Waiting for door to close...',
                          style: TextStyle(color: kTextSecondary, fontSize: 12)),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessState(CollectController controller) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline, color: kPrimary, size: 80),
            const SizedBox(height: 24),
            const Text('Collection Confirmed!',
                style: TextStyle(color: kTextPrimary, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text('The door is closed and your session is complete.',
                textAlign: TextAlign.center,
                style: TextStyle(color: kTextSecondary, fontSize: 14)),
            const SizedBox(height: 40),
            PrimaryButton(
              label: 'Return to Dashboard',
              onPressed: () => controller.finishSession(),
            ),
          ],
        ),
      ),
    );
  }
}