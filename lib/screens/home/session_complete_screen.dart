import 'package:flutter/material.dart';
import 'package:ridercms/utils/themes/app_theme.dart';
import 'package:ridercms/widgets/common_widgets.dart';

class SessionCompleteScreen extends StatefulWidget {
  const SessionCompleteScreen({super.key});

  @override
  State<SessionCompleteScreen> createState() => _SessionCompleteScreenState();
}

class _SessionCompleteScreenState extends State<SessionCompleteScreen> {
  int _rating = 0;

  final List<Map<String, dynamic>> _batteries = [
    {
      'id': 'BAT-990122',
      'slot': 'A2',
      'fee': '135',
      'chargeTime': '1h 12m',
      'startCharge': 12,
      'endCharge': 100,
    },
    {
      'id': 'BAT-990145',
      'slot': 'B4',
      'fee': '135',
      'chargeTime': '1h 26m',
      'startCharge': 8,
      'endCharge': 100,
    },
  ];

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
                                              battery['id']! as String,
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
                                          Text('KSh ${battery['fee']}',
                                              style: const TextStyle(
                                                  color: kTextPrimary,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w700)),
                                          Text(battery['chargeTime']! as String,
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
                                      Text('${battery['startCharge']}%',
                                          style: const TextStyle(
                                              color: kWarning,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600)),
                                      const SizedBox(width: 8),
                                      const Expanded(
                                          child: AppProgressBar(value: 1.0)),
                                      const SizedBox(width: 8),
                                      Text('${battery['endCharge']}%',
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
                              _SummaryRow(label: 'Subtotal', value: 'KSh 270'),
                              const SizedBox(height: 8),
                              _SummaryRow(label: 'Service Fee', value: 'KSh 14'),
                              const SizedBox(height: 12),
                              Divider(
                                  color: Colors.white.withValues(alpha: 0.06),
                                  height: 1),
                              const SizedBox(height: 12),
                              const Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Total Paid',
                                      style: TextStyle(
                                          color: kTextPrimary,
                                          fontWeight: FontWeight.w700)),
                                  Text('KSh 284',
                                      style: TextStyle(
                                          color: kPrimary,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              _SummaryRow(
                                  label: 'Payment Method', value: 'M-Pesa'),
                              const SizedBox(height: 4),
                              const Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Transaction ID',
                                      style: TextStyle(
                                          color: kTextSecondary, fontSize: 12)),
                                  Text('MPE240310001234',
                                      style: TextStyle(
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
                        const Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                  iconData: Icons.battery_full,
                                  value: '2',
                                  label: 'Batteries'),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: _StatCard(
                                  iconData: Icons.timer,
                                  value: '2h 38m',
                                  label: 'Total Time'),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: _StatCard(
                                  iconData: Icons.flash_on,
                                  value: '133%',
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
                                    onTap: () =>
                                        setState(() => _rating = i + 1),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 4),
                                      child: Icon(Icons.star,
                                          size: 32,
                                          color: i < _rating
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
