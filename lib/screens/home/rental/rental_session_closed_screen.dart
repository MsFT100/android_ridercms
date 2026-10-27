import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/rental_controller.dart';
import '../../../utils/themes/app_theme.dart';
import '../../../widgets/common_widgets.dart';

/// `closed` step — final confirmation before the rider goes back home.
class RentalSessionClosedScreen extends StatelessWidget {
  const RentalSessionClosedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<RentalController>();

    return Obx(() {
      final amount = controller.bill.value?.amount ?? 0;
      final minutes = controller.bill.value?.consolidation.durationMinutes ?? 0;

      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
        child: Column(
          children: [
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                color: kPrimary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(color: kPrimary.withValues(alpha: 0.35)),
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: kPrimary,
                size: 48,
              ),
            ),
            const SizedBox(height: 22),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: kPrimary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: kPrimary.withValues(alpha: 0.25)),
              ),
              child: const Text(
                'SESSION COMPLETED',
                style: TextStyle(
                  color: kPrimary,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              "You're all done!",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: kTextPrimary,
                fontSize: 27,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Your battery rental and charging session have been completed '
              'successfully.',
              textAlign: TextAlign.center,
              style: TextStyle(color: kTextSecondary, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 26),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: kPrimary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.receipt_long,
                            color: kPrimary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'SESSION STATUS',
                                style: TextStyle(
                                  color: kTextSecondary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Completed successfully',
                                style: TextStyle(
                                  color: kTextPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.check_circle, color: kPrimary, size: 20),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Color(0x14FFFFFF)),
                  Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        _SummaryRow(
                          icon: Icons.battery_charging_full,
                          label: 'Charging',
                          value: 'Completed',
                        ),
                        const SizedBox(height: 12),
                        _SummaryRow(
                          icon: Icons.timer_outlined,
                          label: 'Rental duration',
                          value: minutes > 0 ? '$minutes min' : 'Returned',
                        ),
                        const SizedBox(height: 12),
                        _SummaryRow(
                          icon: Icons.payments_outlined,
                          label: 'Amount paid',
                          value: 'KES ${amount.toStringAsFixed(2)}',
                          highlight: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            PrimaryButton(
              label: 'Back to Dashboard',
              onPressed: controller.finish,
            ),
            const SizedBox(height: 8),
            const Text(
              'Session completed successfully.',
              textAlign: TextAlign.center,
              style: TextStyle(color: kTextSecondary, fontSize: 10),
            ),
          ],
        ),
      );
    });
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool highlight;

  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: highlight ? kPrimary : kAccent, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: kTextSecondary, fontSize: 12),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: highlight ? kPrimary : kTextPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
