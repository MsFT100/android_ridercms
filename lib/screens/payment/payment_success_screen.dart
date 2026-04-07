import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ridercms/screens/home/scan_screen.dart';
import 'package:ridercms/utils/themes/app_theme.dart';
import '../../models/booth_models.dart';
import '../../widgets/common_widgets.dart';

class PaymentSuccessScreen extends StatelessWidget {
  const PaymentSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final WithdrawalSession session = Get.arguments['session'];
    final String checkoutRequestId = Get.arguments['checkoutRequestId'];

    return Scaffold(
      backgroundColor: kBgDark,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Success header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(24, 48, 24, 32),
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
                          const SizedBox(height: 24),
                          const Text(
                            'Payment Successful!',
                            style: TextStyle(
                                color: kTextPrimary,
                                fontSize: 28,
                                fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'KSh ${session.amount.toStringAsFixed(0)} paid via M-Pesa',
                            style: const TextStyle(color: kTextSecondary, fontSize: 15),
                          ),
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: kBgCard,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                            ),
                            child: Column(
                              children: [
                                const Text('TRANSACTION ID',
                                    style: TextStyle(
                                        color: kTextSecondary, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
                                const SizedBox(height: 4),
                                Text(checkoutRequestId,
                                    style: const TextStyle(
                                        color: kTextPrimary,
                                        fontSize: 13,
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
                          AppCard(
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: kPrimary.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.qr_code_scanner, color: kPrimary),
                                ),
                                const SizedBox(width: 16),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Verification Required',
                                        style: TextStyle(color: kTextPrimary, fontWeight: FontWeight.bold),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Please scan the booth QR code to release your battery.',
                                        style: TextStyle(color: kTextSecondary, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 40),
                          
                          // Instructions
                          _buildInstructionStep(
                            number: '1',
                            text: 'Walk to the charging booth',
                          ),
                          _buildInstructionStep(
                            number: '2',
                            text: 'Locate the QR code on the station',
                          ),
                          _buildInstructionStep(
                            number: '3',
                            text: 'Click the scan button below',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Scan Button
            Padding(
              padding: const EdgeInsets.all(24),
              child: PrimaryButton(
                label: 'Scan Booth QR →',
                onPressed: () => Get.to(() => const ScanScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionStep({required String number, required String text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              border: Border.all(color: kPrimary.withValues(alpha: 0.5)),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(color: kPrimary, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            text,
            style: const TextStyle(color: kTextSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
