import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ridercms/screens/home/scan_screen.dart';
import '../../controllers/charging_controller.dart';
import '../../utils/themes/app_theme.dart';
import '../../widgets/common_widgets.dart';

class ChargingScreen extends StatelessWidget {
  const ChargingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ChargingController>();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // Redirect to dashboard instead of closing the app or going back to splash
        Get.offAllNamed('/dashboard');
      },
      child: Scaffold(
        backgroundColor: kBgDark,
        body: SafeArea(
          child: Obx(() {
            // PROMPT FIX: Show loading spinner if isLoading is true to prevent flicker
            if (controller.isLoading.value) {
              return const Center(child: CircularProgressIndicator(color: kPrimary));
            }

            // Show "No active session" UI if loading is done and batteryStatus is null
            if (controller.batteryStatus.value == null) {
              return _buildNoSessionUI();
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                    child: Row(
                      children: [
                        // Custom Back button that goes to Dashboard
                        BackBtn(onTap: () => Get.offAllNamed('/dashboard')),
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
                              Text(
                                '${controller.batteryStatus.value?.boothUid ?? "Station"} · Active',
                                style: const TextStyle(color: kTextSecondary, fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
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
      
                  // Battery status card
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                    child: AppCard(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Battery Status',
                            style: TextStyle(color: kTextSecondary, fontSize: 14),
                          ),
                          Builder(builder: (context) {
                            final status = controller.batteryStatus.value;
                            String sessionText = status?.sessionStatus.toUpperCase() ?? '...';
                            
                            // FIX: Don't show COMPLETED if charge is below 100%
                            if (sessionText == 'COMPLETED' && (status?.chargeLevel ?? 0) < 100) {
                              sessionText = 'CHARGING';
                            }
      
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: kPrimary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              constraints: const BoxConstraints(maxWidth: 150),
                              child: Text(
                                sessionText,
                                style: const TextStyle(
                                  color: kPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
      
                  // Battery visualization & details card
                  Builder(builder: (context) {
                    final status = controller.batteryStatus.value;
                    if (status == null) return const SizedBox();
      
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                      child: AppCard(
                        child: Column(
                          children: [
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Upright Phone-style Battery UI (Bigger with text inside)
                                _BatteryLevelIndicator(level: status.chargeLevel),
                                const SizedBox(width: 32), // Slightly reduced from 40 to help with space
                                
                                // Station Info - Wrapped in Flexible to prevent RenderFlex overflow
                                Flexible(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'STATION ID',
                                        style: TextStyle(color: kTextSecondary, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        status.boothUid,
                                        style: const TextStyle(
                                          color: kTextPrimary,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                          fontFamily: 'monospace',
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                      const SizedBox(height: 24),
                                      const Text(
                                        'ASSIGNED SLOT',
                                        style: TextStyle(color: kTextSecondary, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Slot ${status.slotIdentifier}',
                                        style: const TextStyle(
                                          color: kPrimary,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w900,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 40),
                            const Divider(color: Color(0x0FFFFFFF), height: 1),
                            const SizedBox(height: 20),
      
                            // Stats row (Voltage rounded)
                            Row(
                              children: [
                                _StatItem(
                                  label: 'TEMPERATURE',
                                  value: '${status.telemetry?['temperatureC'] ?? "---"}°C',
                                  icon: Icons.thermostat,
                                ),
                                const SizedBox(width: 12),
                                _StatItem(
                                  label: 'VOLTAGE',
                                  value: '${_formatVoltage(status.telemetry?['voltage'])}V',
                                  icon: Icons.bolt,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            );
          }),
        ),
        bottomNavigationBar: Obx(() {
          // Hide bottom bar if no session
          if (controller.isLoading.value || controller.batteryStatus.value == null) {
            return const SizedBox.shrink();
          }
          return Container(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            decoration: BoxDecoration(
              color: kBgCard,
              border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
            ),
            child: PrimaryButton(
              label: controller.isLoading.value ? 'Fetching status...' : 'Collect Battery →',
              onPressed: controller.isLoading.value || controller.batteryStatus.value == null
                  ? null // Disabled state
                  : () => controller.initiateCollection(),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildNoSessionUI() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: kBgCard,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.bolt_outlined, size: 64, color: kTextSecondary),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Active Session',
              style: TextStyle(color: kTextPrimary, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'You don\'t have a battery currently charging. Scan a station QR code to start a session.',
              textAlign: TextAlign.center,
              style: TextStyle(color: kTextSecondary, fontSize: 15, height: 1.5),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: 200,
              child: PrimaryButton(
                label: 'Return to Dashboard',
                onPressed: () => Get.offAllNamed('/dashboard'),
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: 200,
              child: PrimaryButton(
                label: 'Scan Now',
                onPressed: () => Get.to(ScanScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatVoltage(dynamic voltage) {
    if (voltage == null) return "---";
    try {
      double v = double.parse(voltage.toString());
      return v.toStringAsFixed(1);
    } catch (_) {
      return voltage.toString();
    }
  }
}

class _BatteryLevelIndicator extends StatelessWidget {
  final int level;

  const _BatteryLevelIndicator({required this.level});

  Color _getBatteryColor() {
    if (level < 20) return Colors.redAccent;
    if (level < 60) return Colors.orangeAccent;
    return kPrimary;
  }

  Color _getBatteryDarkColor() {
    if (level < 20) return Colors.red.shade900;
    if (level < 60) return Colors.orange.shade900;
    return kPrimaryDark;
  }

  @override
  Widget build(BuildContext context) {
    final color = _getBatteryColor();
    final darkColor = _getBatteryDarkColor();

    return Container(
      width: 100,
      height: 180,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        border: Border.all(color: kTextSecondary.withValues(alpha: 0.2), width: 3),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          // Background/Fill
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: kBgCard2,
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          // Level Fill with Gradient
          FractionallySizedBox(
            heightFactor: (level / 100).clamp(0.08, 1.0),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [color, darkColor],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 15,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),
          // Battery Cap
          Positioned(
            top: -14,
            left: 30,
            right: 30,
            child: Container(
              height: 8,
              decoration: BoxDecoration(
                color: kTextSecondary.withValues(alpha: 0.2),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ),
          ),
          // Content inside Battery
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  level >= 100 ? Icons.done_all : Icons.bolt,
                  color: Colors.white,
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  '$level%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatItem({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kBgCard2,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: kTextSecondary),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(color: kTextSecondary, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(color: kTextPrimary, fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}
