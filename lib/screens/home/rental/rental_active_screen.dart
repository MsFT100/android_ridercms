import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/rental_controller.dart';
import '../../../utils/themes/app_theme.dart';
import '../../../widgets/common_widgets.dart';

/// `active` step — the rider is using the rental battery while their own
/// battery keeps charging at the station.
class RentalActiveScreen extends StatefulWidget {
  const RentalActiveScreen({super.key});

  @override
  State<RentalActiveScreen> createState() => _RentalActiveScreenState();
}

class _RentalActiveScreenState extends State<RentalActiveScreen> {
  final RentalController _controller = Get.find<RentalController>();
  Timer? _ticker;
  int _elapsedMinutes = 0;

  @override
  void initState() {
    super.initState();
    _updateElapsed();
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) => _updateElapsed());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _updateElapsed() {
    final active = _controller.active.value;
    final raw = active?.startedAt ?? active?.issuedAt;
    final start = raw == null ? null : DateTime.tryParse(raw)?.toLocal();
    if (start == null) return;
    final minutes = DateTime.now().difference(start).inMinutes;
    if (!mounted) return;
    setState(() => _elapsedMinutes = minutes < 0 ? 0 : minutes);
  }

  String get _durationLabel {
    final hours = _elapsedMinutes ~/ 60;
    final minutes = _elapsedMinutes % 60;
    return hours > 0 ? '${hours}h ${minutes}m' : '$minutes min';
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final active = _controller.active.value;
      final ownSoc = _controller.ownBatterySoc.clamp(0, 100);

      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                BackBtn(onTap: _controller.finish),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Live Session',
                    style: TextStyle(
                      color: kPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.6,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: kPrimary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: kPrimary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'ACTIVE',
                        style: TextStyle(
                          color: kPrimary,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Rental Session Active',
              style: TextStyle(
                color: kTextPrimary,
                fontSize: 26,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "You're using a rental battery while your own battery continues "
              'charging at the station.',
              style: TextStyle(color: kTextSecondary, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: kBgCard,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: kPrimary.withValues(alpha: 0.25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.battery_charging_full, color: kPrimary),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Rental battery',
                          style: TextStyle(
                            color: kTextSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                      Text(
                        _durationLabel,
                        style: const TextStyle(
                          color: kTextPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _controller.rentalBatteryId,
                    style: const TextStyle(
                      color: kTextPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'monospace',
                    ),
                  ),
                  if (active?.issueSoc != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Issued at ${active!.issueSoc}% charge',
                      style: const TextStyle(
                        color: kTextSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: kBgCard,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 64,
                    height: 64,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: ownSoc / 100,
                          strokeWidth: 6,
                          backgroundColor: kBgCard2,
                          valueColor: const AlwaysStoppedAnimation<Color>(kPrimary),
                        ),
                        Text(
                          '$ownSoc%',
                          style: const TextStyle(
                            color: kPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Your own battery',
                          style: TextStyle(
                            color: kTextPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          active?.ownDeposit.slotIdentifier.isNotEmpty == true
                              ? 'Charging in slot ${active!.ownDeposit.slotIdentifier}'
                              : 'Charging at the station',
                          style: const TextStyle(
                            color: kTextSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            PrimaryButton(
              label: 'Return Battery',
              onPressed: () => _controller.goTo(RentalStep.returning),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _controller.finish,
              child: const Text(
                'Back to Dashboard',
                style: TextStyle(color: kTextSecondary),
              ),
            ),
          ],
        ),
      );
    });
  }
}
