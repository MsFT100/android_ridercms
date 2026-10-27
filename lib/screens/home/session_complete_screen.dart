import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ridercms/controllers/session_complete_controller.dart';
import 'package:ridercms/utils/themes/app_theme.dart';
import 'package:ridercms/widgets/common_widgets.dart';

class SessionCompleteScreen extends StatefulWidget {
  const SessionCompleteScreen({super.key});

  @override
  State<SessionCompleteScreen> createState() => _SessionCompleteScreenState();
}

class _SessionCompleteScreenState extends State<SessionCompleteScreen> {
  late final SessionCompleteController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.put(SessionCompleteController());
  }

  @override
  void dispose() {
    Get.delete<SessionCompleteController>();
    super.dispose();
  }

  /// Battery rows come from navigation arguments as maps with `id`, `slot`,
  /// `fee`, `chargeTime`, `startCharge` and `endCharge`.
  List<Map<String, dynamic>> get _batteries => _controller.batteries
      .whereType<Map>()
      .map((b) => Map<String, dynamic>.from(b))
      .toList();

  int get _chargeAdded => _batteries.fold<int>(0, (sum, b) {
        final start = (b['startCharge'] as num?)?.toInt() ?? 0;
        final end = (b['endCharge'] as num?)?.toInt() ?? start;
        return sum + (end - start).clamp(0, 100);
      });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgDark,
      body: Stack(
        children: [
          // Background decoration
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kPrimary.withValues(alpha: 0.05),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // Success Header
                  const Center(
                    child: Column(
                      children: [
                        Icon(Icons.check_circle_rounded,
                            color: kPrimary, size: 80),
                        SizedBox(height: 16),
                        Text(
                          'Session Complete',
                          style: TextStyle(
                              color: kTextPrimary,
                              fontSize: 24,
                              fontWeight: FontWeight.w800),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Your batteries are ready to go',
                          style: TextStyle(color: kTextSecondary, fontSize: 14),
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Battery details
                        const Text(
                          'CHARGING DETAILS',
                          style: TextStyle(
                              color: kTextSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5),
                        ),
                        const SizedBox(height: 12),
                        ..._batteries.map(
                          (battery) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: AppCard(
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: kPrimary.withValues(alpha: 0.15),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: const Center(
                                          child: Icon(Icons.battery_full,
                                              color: kPrimary),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${battery['id'] ?? 'Own battery'}',
                                              style: const TextStyle(
                                                  color: kTextPrimary,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w700,
                                                  fontFamily: 'monospace'),
                                            ),
                                            Text('Slot ${battery['slot']}',
                                                style: const TextStyle(
                                                    color: kTextSecondary,
                                                    fontSize: 11)),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text('KSh ${battery['fee'] ?? '-'}',
                                              style: const TextStyle(
                                                  color: kTextPrimary,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w700)),
                                          Text('${battery['chargeTime'] ?? ''}',
                                              style: const TextStyle(
                                                  color: kTextSecondary,
                                                  fontSize: 11)),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Text('${battery['startCharge'] ?? 0}%',
                                          style: const TextStyle(
                                              color: kWarning,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600)),
                                      const SizedBox(width: 8),
                                      const Expanded(
                                          child: AppProgressBar(value: 1.0)),
                                      const SizedBox(width: 8),
                                      Text('${battery['endCharge'] ?? 0}%',
                                          style: const TextStyle(
                                              color: kPrimary,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Payment summary
                        const Text(
                          'PAYMENT SUMMARY',
                          style: TextStyle(
                              color: kTextSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5),
                        ),
                        const SizedBox(height: 12),
                        AppCard(
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Total Paid',
                                      style: TextStyle(
                                          color: kTextPrimary,
                                          fontWeight: FontWeight.w700)),
                                  Text(
                                      'KSh ${_controller.totalAmount.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                          color: kPrimary,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              _SummaryRow(
                                  label: 'Payment Method', value: 'M-Pesa'),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Transaction ID',
                                      style: TextStyle(
                                          color: kTextSecondary, fontSize: 12)),
                                  Text(_controller.transactionId,
                                      style: const TextStyle(
                                          color: kTextSecondary,
                                          fontSize: 12,
                                          fontFamily: 'monospace')),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Stats
                        Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                  iconData: Icons.battery_full,
                                  value: '${_batteries.length}',
                                  label: 'Batteries'),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatCard(
                                  iconData: Icons.timer,
                                  value: _controller.formatDuration(
                                      _controller.durationMinutes),
                                  label: 'Total Time'),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatCard(
                                  iconData: Icons.flash_on,
                                  value: '$_chargeAdded%',
                                  label: 'Charged'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Rating
                        AppCard(
                          child: Column(
                            children: [
                              const Text('Rate this session',
                                  style: TextStyle(
                                      color: kTextPrimary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(5, (i) {
                                  return GestureDetector(
                                    onTap: () => setState(
                                        () => _controller.setRating(i + 1)),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 4),
                                      child: Icon(Icons.star,
                                          size: 32,
                                          color: i < _controller.rating.value
                                              ? Colors.amber
                                              : Colors.white
                                                  .withValues(alpha: 0.3)),
                                    ),
                                  );
                                }),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Fixed bottom actions
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              decoration: BoxDecoration(
                color: kBgCard,
                border: Border(
                    top: BorderSide(
                        color: Colors.white.withValues(alpha: 0.06))),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PrimaryButton(
                    label: 'Start New Session',
                    onPressed: () => Navigator.pushNamedAndRemoveUntil(
                        context, '/scan', (route) => false),
                  ),
                  const SizedBox(height: 12),
                  GhostButton(
                    label: 'Return Home',
                    onPressed: () => Navigator.pushNamedAndRemoveUntil(
                        context, '/dashboard', (route) => false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: kTextSecondary, fontSize: 13)),
        Text(value,
            style: const TextStyle(
                color: kTextPrimary, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData iconData;
  final String value;
  final String label;

  const _StatCard(
      {required this.iconData, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Column(
        children: [
          Icon(iconData, color: kPrimary, size: 20),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(
                  color: kTextPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(color: kTextSecondary, fontSize: 10)),
        ],
      ),
    );
  }
}
