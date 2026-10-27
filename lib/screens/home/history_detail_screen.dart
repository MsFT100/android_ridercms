import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ridercms/models/booth_models.dart';
import 'package:ridercms/utils/themes/app_theme.dart';

class HistoryDetailScreen extends StatelessWidget {
  final UserTransaction item;

  const HistoryDetailScreen({super.key, required this.item});

  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  (String, IconData, Color) get _kind {
    switch (item.sessionType.toLowerCase()) {
      case 'deposit':
        return ('Battery Deposit', Icons.battery_charging_full_rounded, kPrimary);
      case 'withdrawal':
        return ('Battery Collection', Icons.battery_full_rounded, kAccent);
      case 'rental':
        return ('Battery Rental', Icons.swap_horiz_rounded, kWarning);
      default:
        return (
          item.sessionType.isEmpty ? 'Session' : item.sessionType,
          Icons.bolt_rounded,
          kTextSecondary,
        );
    }
  }

  Color get _statusColor {
    switch (item.status.toLowerCase()) {
      case 'completed':
      case 'paid':
        return kPrimary;
      case 'pending':
      case 'in_progress':
      case 'opening':
        return kWarning;
      case 'cancelled':
      case 'failed':
        return kDanger;
      default:
        return kTextSecondary;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '—';
    final hh = date.hour.toString().padLeft(2, '0');
    final mm = date.minute.toString().padLeft(2, '0');
    final ss = date.second.toString().padLeft(2, '0');
    return '${date.day} ${_months[date.month - 1]} ${date.year} · $hh:$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    final (label, icon, color) = _kind;
    final statusColor = _statusColor;
    final status = item.status.replaceAll('_', ' ');

    return Scaffold(
      backgroundColor: kBgDark,
      appBar: AppBar(
        backgroundColor: kBgDark2,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: kTextPrimary, size: 20),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Session Details',
          style: TextStyle(color: kTextPrimary, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top card with Icon, Label, and Status
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: kBgCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: color, size: 26),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: const TextStyle(
                            color: kTextPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.sessionType.toUpperCase(),
                          style: TextStyle(
                            color: kTextSecondary.withValues(alpha: 0.7),
                            fontSize: 12,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status.isEmpty ? '—' : status[0].toUpperCase() + status.substring(1),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Details Section
            const Text(
              'Session Information',
              style: TextStyle(
                color: kTextPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: kBgCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: Column(
                children: [
                  _buildDetailRow('Status', status.isEmpty ? '—' : status[0].toUpperCase() + status.substring(1), valueColor: statusColor),
                  _buildDivider(),
                  _buildDetailRow('Started At', _formatDate(item.startedAt)),
                  _buildDivider(),
                  _buildDetailRow('Completed At', _formatDate(item.completedAt)),
                  if (item.amount != null && item.amount! > 0) ...[
                    _buildDivider(),
                    _buildDetailRow('Amount', 'KES ${item.amount!.toStringAsFixed(0)}', valueColor: kPrimary),
                  ],
                  if (item.boothUid.isNotEmpty) ...[
                    _buildDivider(),
                    _buildDetailRow('Booth ID', item.boothUid),
                  ],
                  if (item.slotIdentifier.isNotEmpty) ...[
                    _buildDivider(),
                    _buildDetailRow('Slot', item.slotIdentifier),
                  ],
                  if (item.batteryUid != null && item.batteryUid!.isNotEmpty) ...[
                    _buildDivider(),
                    _buildDetailRow('Battery UID', item.batteryUid!),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Note Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kWarning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kWarning.withValues(alpha: 0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded, color: kWarning, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Note: Failed or cancelled sessions may disappear over time.',
                      style: TextStyle(
                        color: kTextSecondary.withValues(alpha: 0.9),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: kTextSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: valueColor ?? kTextPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: Colors.white.withValues(alpha: 0.04),
    );
  }
}
