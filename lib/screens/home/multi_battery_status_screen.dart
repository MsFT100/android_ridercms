import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/charging_controller.dart';
import '../../models/booth_models.dart';
import '../../utils/rental_launcher.dart';
import '../../utils/themes/app_theme.dart';
import '../../widgets/common_widgets.dart';
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
                      return _BatteryCard(
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

class _BatteryCard extends StatelessWidget {
  final MyBatteryStatus status;
  final VoidCallback onCollect;

  const _BatteryCard({required this.status, required this.onCollect});

  @override
  Widget build(BuildContext context) {
    final soc = status.soc;
    final canCollect = soc >= 20 && !status.isPending;
    final telemetry = status.telemetry;
    final doorKnown = telemetry != null;
    final locked = telemetry?.doorLocked ?? false;
    final doorColor = !doorKnown ? kTextSecondary : (locked ? kPrimary : kDanger);
    final temperature = telemetry?.temperature;
    final voltage = telemetry?.voltage;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kBgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SocRing(level: soc),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            status.boothUid.isEmpty ? 'Station' : status.boothUid,
                            style: const TextStyle(
                              color: kTextPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'monospace',
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _StatusBadge(status: status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Slot ${status.slotIdentifier}',
                      style: const TextStyle(color: kTextSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          locked ? Icons.lock : Icons.lock_open,
                          size: 14,
                          color: doorColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          !doorKnown
                              ? 'Door status unknown'
                              : (locked ? 'Door locked' : 'Door open'),
                          style: TextStyle(
                            color: doorColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Color(0x0FFFFFFF), height: 1),
          const SizedBox(height: 16),
          Row(
            children: [
              _Metric(
                icon: Icons.thermostat,
                label: 'TEMP',
                value: temperature == null
                    ? '---'
                    : '${temperature.toStringAsFixed(1)}°C',
              ),
              const SizedBox(width: 12),
              _Metric(
                icon: Icons.bolt,
                label: 'VOLTAGE',
                value: voltage == null ? '---' : '${voltage.toStringAsFixed(1)}V',
              ),
            ],
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: status.isPending
                ? 'Confirming deposit...'
                : canCollect
                    ? 'Collect Battery & Pay'
                    : 'Charging to 20% ($soc%)',
            onPressed: canCollect ? onCollect : null,
          ),
        ],
      ),
    );
  }
}

class _SocRing extends StatelessWidget {
  final int level;

  const _SocRing({required this.level});

  Color get _color {
    if (level < 20) return kDanger;
    if (level < 60) return kWarning;
    return kPrimary;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 72,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: (level.clamp(0, 100)) / 100,
            strokeWidth: 6,
            backgroundColor: kBgCard2,
            valueColor: AlwaysStoppedAnimation<Color>(_color),
          ),
          Text(
            '$level%',
            style: TextStyle(
              color: _color,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final MyBatteryStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final charging = status.telemetry?.relayOn ?? true;
    final label = status.isPending
        ? 'PENDING'
        : charging
            ? 'CHARGING'
            : 'STANDBY';
    final color = status.isPending
        ? kWarning
        : charging
            ? kPrimary
            : kTextSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _Metric({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: kBgCard2,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: kTextSecondary),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: kTextSecondary,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: kTextPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
