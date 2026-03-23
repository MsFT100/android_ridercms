import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ridercms/utils/themes/app_theme.dart';
import '../../widgets/common_widgets.dart';

class PaymentSuccessScreen extends StatefulWidget {
  const PaymentSuccessScreen({super.key});

  @override
  State<PaymentSuccessScreen> createState() => _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends State<PaymentSuccessScreen> {
  bool _doorsOpening = true;

  static const _batteries = [
    {'id': 'BATT102', 'slot': 'A03'},
    {'id': 'BATT103', 'slot': 'A04'},
  ];

  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _doorsOpening = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgDark,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Success header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF0d2a1a), kBgDark],
                  ),
                ),
                child: Column(
                  children: [
                    // Checkmark icon
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            color: kPrimary.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                        ),
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [kPrimary, kPrimaryDark],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: kPrimary.withValues(alpha: 0.5),
                                blurRadius: 32,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.check_circle_outline,
                              size: 48,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Payment Successful!',
                      style: TextStyle(
                          color: kTextPrimary,
                          fontSize: 28,
                          fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'KSh 284 paid via M-Pesa',
                      style: TextStyle(color: kTextSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: kBgCard,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text('Txn: ',
                              style: TextStyle(
                                  color: kTextSecondary, fontSize: 12)),
                          Text('MPE240310001234',
                              style: TextStyle(
                                  color: kTextPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'monospace')),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    // Door opening status
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _doorsOpening
                            ? kWarning.withValues(alpha: 0.1)
                            : kPrimary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _doorsOpening
                              ? kWarning.withValues(alpha: 0.2)
                              : kPrimary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            _doorsOpening
                                ? Icons.hourglass_bottom
                                : Icons.lock_open,
                            color: _doorsOpening ? kWarning : kPrimary,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _doorsOpening
                                      ? 'Opening doors...'
                                      : 'All doors are open!',
                                  style: TextStyle(
                                    color: _doorsOpening ? kWarning : kPrimary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _doorsOpening
                                      ? 'Triggering door release for all charged batteries'
                                      : 'Proceed to collect your batteries from the slots below',
                                  style: const TextStyle(
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

                    // Battery slots
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'COLLECT FROM THESE SLOTS',
                        style: TextStyle(
                            color: kTextSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: _batteries.map((battery) {
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                                right: battery == _batteries.last ? 0 : 12),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 500),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: _doorsOpening
                                    ? kBgCard
                                    : kPrimary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: _doorsOpening
                                      ? Colors.white.withValues(alpha: 0.06)
                                      : kPrimary,
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    _doorsOpening
                                        ? Icons.hourglass_bottom
                                        : Icons.lock_open,
                                    size: 28,
                                    color: _doorsOpening ? kWarning : kPrimary,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    battery['slot']!,
                                    style: const TextStyle(
                                        color: kPrimary,
                                        fontSize: 24,
                                        fontWeight: FontWeight.w900,
                                        fontFamily: 'monospace'),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    battery['id']!,
                                    style: const TextStyle(
                                        color: kTextSecondary,
                                        fontSize: 11,
                                        fontFamily: 'monospace'),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _doorsOpening ? 'Opening...' : 'Open',
                                    style: TextStyle(
                                      color:
                                      _doorsOpening ? kWarning : kPrimary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    PrimaryButton(
                      label: _doorsOpening
                          ? 'Opening Doors...'
                          : 'Proceed to Collect →',
                      onPressed: _doorsOpening
                          ? null
                          : () => Navigator.pushNamed(context, '/collect'),
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
