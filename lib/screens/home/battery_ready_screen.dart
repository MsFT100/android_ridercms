
import 'package:flutter/material.dart';
import 'package:ridercms/utils/themes/app_theme.dart';
import 'package:ridercms/widgets/common_widgets.dart';

class BatteryReadyScreen extends StatelessWidget {
  const BatteryReadyScreen({super.key});

  static const _batteries = [
    {'id': 'BATT102', 'slot': 'A03', 'chargeTime': '1h 52m'},
    {'id': 'BATT103', 'slot': 'A04', 'chargeTime': '2h 38m'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgDark,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header gradient section
              Container(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF0d2a1a), kBgDark],
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: const [
                        BackBtn(),
                        SizedBox(width: 12),
                        Text(
                          'Battery Ready!',
                          style: TextStyle(
                            color: kTextPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Big notification card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            kPrimary.withAlpha((0.2 * 255).round()),
                            kPrimaryDark.withAlpha((0.1 * 255).round())
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: kPrimary.withAlpha((0.3 * 255).round()),
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [kPrimary, kPrimaryDark],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: kPrimary.withAlpha((0.4 * 255).round()),
                                  blurRadius: 24,
                                )
                              ],
                            ),
                            child: const Center(
                              child: Text('🔔', style: TextStyle(fontSize: 36)),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Batteries Fully Charged!',
                            style: TextStyle(
                              color: kTextPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Your batteries are ready for collection at Westlands Station',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: kTextSecondary,
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Charged Batteries',
                      style: TextStyle(
                        color: kTextPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
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
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: kPrimary.withAlpha((0.15 * 255).round()),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Center(
                                      child: Text('🔋', style: TextStyle(fontSize: 24)),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          battery['id']!,
                                          style: const TextStyle(
                                            color: kTextPrimary,
                                            fontWeight: FontWeight.w700,
                                            fontFamily: 'monospace',
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        RichText(
                                          text: TextSpan(
                                            style: const TextStyle(
                                              color: kTextSecondary,
                                              fontSize: 12,
                                            ),
                                            children: [
                                              const TextSpan(text: 'Slot: '),
                                              TextSpan(
                                                text: battery['slot'],
                                                style: const TextStyle(
                                                  color: kPrimary,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: kPrimary.withAlpha((0.15 * 255).round()),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Text(
                                          '✅ 100%',
                                          style: TextStyle(
                                            color: kPrimary,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        battery['chargeTime']!,
                                        style: const TextStyle(color: kTextSecondary, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const AppProgressBar(value: 1.0),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Station info
                    AppCard(
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: kAccent.withAlpha((0.15 * 255).round()),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Text('📍', style: TextStyle(fontSize: 24)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Westlands Station',
                                  style: TextStyle(
                                    color: kTextPrimary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Westlands Rd, Nairobi · Open until 10 PM',
                                  style: TextStyle(
                                    color: kTextSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Text(
                            'Directions',
                            style: TextStyle(
                              color: kPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Reminder
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: kWarning.withAlpha((0.1 * 255).round()),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: kWarning.withAlpha((0.2 * 255).round()),
                        ),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('⏰', style: TextStyle(fontSize: 20)),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Collection Reminder',
                                  style: TextStyle(
                                    color: kWarning,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Please collect your batteries within 2 hours to avoid additional storage fees.',
                                  style: TextStyle(
                                    color: kTextSecondary,
                                    fontSize: 12,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    PrimaryButton(
                      label: 'Proceed to Payment →',
                      onPressed: () => Navigator.pushNamed(context, '/payment'),
                    ),
                    const SizedBox(height: 12),
                    GhostButton(
                      label: 'Back to Session',
                      onPressed: () => Navigator.pushNamed(context, '/charging'),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}