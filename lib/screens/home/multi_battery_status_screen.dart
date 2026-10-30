import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/charging_controller.dart';
import '../../utils/rental_launcher.dart';
import '../../utils/themes/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/home/battery_card.dart';
import 'scan_screen.dart';

/// Lists every battery the rider currently has deposited, mirroring the web
/// `MultiBatteryStatus` component: one card per battery with live SOC,
/// temperature, voltage, door state and a per-battery "Collect & Pay" action.
class MultiBatteryStatusScreen extends StatefulWidget {
  const MultiBatteryStatusScreen({super.key});

  @override
  State<MultiBatteryStatusScreen> createState() =>
      _MultiBatteryStatusScreenState();
}

class _MultiBatteryStatusScreenState extends State<MultiBatteryStatusScreen> {
  late final ChargingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<ChargingController>();
    _controller.startPolling();
    _controller.refreshBatteries();
  }

  @override
  void dispose() {
    _controller.stopPolling();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgDark,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 16, 8),
              child: Row(
                children: [
                  BackBtn(onTap: () => Get.offAllNamed('/dashboard')),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Your Batteries',
                      style: TextStyle(
                        color: kTextPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Obx(
                    () => Text(
                      '${_controller.batteryCount}',
                      style: const TextStyle(
                        color: kPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Obx(() {
                final batteries = _controller.batteries;

                if (_controller.isLoading.value && batteries.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(color: kPrimary),
                  );
                }

                if (batteries.isEmpty) {
                  return _EmptyState(onScan: () => _openScanner());
                }

                return RefreshIndicator(
                  color: kPrimary,
                  backgroundColor: kBgCard,
                  onRefresh: () => _controller.refreshBatteries(),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                    itemCount: batteries.length + 1,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      if (index == batteries.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Column(
                            children: [
                              GhostButton(
                                label: '+ Add Another Battery',
                                onPressed: _openScanner,
                              ),
                              const SizedBox(height: 4),
                              TextButton(
                                onPressed: () => openRental(context),
                                child: const Text(
                                  'Rent a Battery',
                                  style: TextStyle(color: kPrimary),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return BatteryCard(
                        status: batteries[index],
                        onCollect: () =>
                            _controller.initiateCollection(index: index),
                      );
                    },
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  void _openScanner() {
    Get.to(() => const ScanScreen());
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onScan;

  const _EmptyState({required this.onScan});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: kBgCard,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.battery_charging_full,
                  size: 56, color: kTextSecondary),
            ),
            const SizedBox(height: 24),
            const Text(
              'No batteries in a booth',
              style: TextStyle(
                color: kTextPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Deposit a battery at any station to start charging. You can keep '
              'several batteries charging at once.',
              textAlign: TextAlign.center,
              style: TextStyle(color: kTextSecondary, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 32),
            PrimaryButton(label: 'Scan a Station', onPressed: onScan),
            const SizedBox(height: 12),
            GhostButton(
              label: 'Back to Dashboard',
              onPressed: () => Get.offAllNamed('/dashboard'),
            ),
          ],
        ),
      ),
    );
  }
}
