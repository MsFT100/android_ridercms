import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/rental_controller.dart';
import '../../../utils/themes/app_theme.dart';
import '../../../widgets/common_widgets.dart';
import 'rental_progress_view.dart';

/// `bill` step — own charging + rental energy + rental time, consolidated.
class ConsolidatedRentalBillScreen extends StatelessWidget {
  const ConsolidatedRentalBillScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<RentalController>();

    return Obx(() {
      final bill = controller.bill.value;

      if (bill == null) {
        return const RentalProgressView(
          title: 'Calculating your bill',
          subtitle: 'Adding up charging, energy and time…',
        );
      }

      final c = bill.consolidation;
      final total = bill.amount > 0
          ? bill.amount
          : c.ownCharging + c.rentalEnergy + c.rentalTime;

      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            Center(
              child: Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: kPrimary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: kPrimary.withValues(alpha: 0.3)),
                ),
                child: const Icon(Icons.receipt_long, color: kPrimary, size: 34),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'PAYMENT SUMMARY',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: kPrimary,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Your Bill is Ready',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: kTextPrimary,
                fontSize: 26,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Your battery charging and rental charges have been combined into '
              'one payment.',
              textAlign: TextAlign.center,
              style: TextStyle(color: kTextSecondary, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 24),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'CHARGING & RENTAL',
                                style: TextStyle(
                                  color: kTextSecondary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Current session',
                                style: TextStyle(
                                  color: kTextPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        StatusBadge(
                          label: 'Complete',
                          color: kPrimary,
                          bgColor: kPrimary.withValues(alpha: 0.12),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Color(0x14FFFFFF)),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _BillRow(
                          icon: Icons.bolt,
                          label: 'Own battery charging',
                          description: 'Energy used to charge your battery',
                          amount: c.ownCharging,
                        ),
                        const SizedBox(height: 12),
                        _BillRow(
                          icon: Icons.battery_std,
                          label: 'Rental energy',
                          description: 'Energy consumed from rental battery',
                          amount: c.rentalEnergy,
                        ),
                        const SizedBox(height: 12),
                        _BillRow(
                          icon: Icons.timer_outlined,
                          label: 'Rental time',
                          description:
                              'Duration of your rental session (${c.durationMinutes} min)',
                          amount: c.rentalTime,
                        ),
                        const SizedBox(height: 20),
                        const Divider(height: 1, color: Color(0x1AFFFFFF)),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Total amount',
                                style: TextStyle(
                                  color: kTextSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'KES ${total.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: kPrimary,
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const Text(
                                  'Including rental & charging',
                                  style: TextStyle(
                                    color: kTextSecondary,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AppCard(
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: kPrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text(
                        'M',
                        style: TextStyle(
                          color: kPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'M-Pesa',
                          style: TextStyle(
                            color: kTextPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Secure mobile payment',
                          style: TextStyle(
                            color: kTextSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.check_circle, color: kPrimary, size: 20),
                ],
              ),
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Pay KES ${total.toStringAsFixed(2)}',
              onPressed: total <= 0 ? null : controller.startPayment,
            ),
            const SizedBox(height: 12),
            const Text(
              'Secure payment • Your battery stays locked until payment is confirmed',
              textAlign: TextAlign.center,
              style: TextStyle(color: kTextSecondary, fontSize: 10),
            ),
          ],
        ),
      );
    });
  }
}

class _BillRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final double amount;

  const _BillRow({
    required this.icon,
    required this.label,
    required this.description,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: kBgCard2,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: kAccent, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: kTextPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: const TextStyle(color: kTextSecondary, fontSize: 11),
              ),
            ],
          ),
        ),
        Text(
          'KES ${amount.toStringAsFixed(2)}',
          style: const TextStyle(
            color: kTextPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
