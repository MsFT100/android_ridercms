import 'package:flutter/material.dart';
import '../../models/booth_models.dart';
import '../../utils/themes/app_theme.dart';
import '../common_widgets.dart';
import 'battery_card.dart';

/// Inline "Your Batteries" block used by the dashboard.
///
/// Renders up to [maxCards] live cards (all when `maxCards <= 0`) plus an
/// "Add Another Battery" action. The dashboard uses `maxCards: 2` and shows a
/// "View all" affordance when more are charging, so the feed stays short.
class BatterySection extends StatelessWidget {
  final List<MyBatteryStatus> batteries;
  final int maxCards;
  final ValueChanged<int> onCollect;
  final VoidCallback onAddBattery;
  final VoidCallback? onViewAll;

  /// An unpaid withdrawal blocks collection until the rider pays.
  final bool pendingPayment;
  final VoidCallback? onPayPending;

  const BatterySection({
    super.key,
    required this.batteries,
    required this.onCollect,
    required this.onAddBattery,
    this.maxCards = 2,
    this.onViewAll,
    this.pendingPayment = false,
    this.onPayPending,
  });

  @override
  Widget build(BuildContext context) {
    if (batteries.isEmpty) return const SizedBox.shrink();

    final visible = maxCards <= 0
        ? batteries
        : batteries.take(maxCards).toList(growable: false);
    final truncated = visible.length < batteries.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (pendingPayment) ...[
          _PaymentBanner(onPay: onPayPending),
          const SizedBox(height: 16),
        ],
        Row(
          children: [
            Expanded(
              child: Text(
                batteries.length == 1 ? 'Your Battery' : 'Your Batteries',
                style: const TextStyle(
                  color: kTextPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: kPrimary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${batteries.length}',
                style: const TextStyle(
                  color: kPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (truncated && onViewAll != null)
              TextButton(
                onPressed: onViewAll,
                child: const Text(
                  'View all',
                  style: TextStyle(color: kTextSecondary),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < visible.length; i++) ...[
          BatteryCard(
            status: visible[i],
            collectEnabled: !pendingPayment,
            onCollect: () => onCollect(i),
          ),
          const SizedBox(height: 16),
        ],
        if (!pendingPayment)
          GhostButton(
            label: '+ Add Another Battery',
            onPressed: onAddBattery,
          ),
      ],
    );
  }
}

class _PaymentBanner extends StatelessWidget {
  final VoidCallback? onPay;

  const _PaymentBanner({this.onPay});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kWarning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kWarning.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.receipt_long, color: kWarning, size: 22),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Payment pending',
                  style: TextStyle(
                    color: kTextPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Complete your payment to collect your batteries.',
                  style: TextStyle(color: kTextSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onPay,
            child: const Text('Pay now', style: TextStyle(color: kWarning)),
          ),
        ],
      ),
    );
  }
}
