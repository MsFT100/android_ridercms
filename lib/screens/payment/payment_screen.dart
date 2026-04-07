import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/payment_controller.dart';
import '../../utils/themes/app_theme.dart';
import '../../widgets/common_widgets.dart';

class PaymentScreen extends StatelessWidget {
  const PaymentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(PaymentController());

    return Scaffold(
      backgroundColor: kBgDark,
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator(color: kPrimary));
        }

        final session = controller.withdrawalSession.value;
        if (session == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: kDanger),
                const SizedBox(height: 16),
                const Text('No active session found', style: TextStyle(color: kTextPrimary)),
                const SizedBox(height: 24),
                SizedBox(width: 200, child:
                PrimaryButton(
                  label: 'Go Back',
                  onPressed: () => Get.back(),
                ),),
              ],
            ),
          );
        }

        return Stack(
          children: [
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 150),
                child: Column(
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                      child: Row(
                        children: [
                          const BackBtn(),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Payment',
                                  style: TextStyle(
                                      color: kTextPrimary,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700)),
                              Text('Session #${session.sessionId}',
                                  style: const TextStyle(
                                      color: kTextSecondary, fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Charging summary
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('CHARGING SUMMARY',
                              style: TextStyle(
                                  color: kTextSecondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5)),
                          const SizedBox(height: 12),
                          AppCard(
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.battery_charging_full, color: kPrimary),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('Battery Charging Fee',
                                              style: TextStyle(
                                                  color: kTextPrimary,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600)),
                                          Text('Final Charge: ${session.soc}%',
                                              style: const TextStyle(
                                                  color: kTextSecondary,
                                                  fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                    Text('KSh ${session.amount.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                            color: kTextPrimary,
                                            fontWeight: FontWeight.w700)),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Divider(color: Colors.white.withValues(alpha: 0.06), height: 1),
                                const SizedBox(height: 16),
                                _SummaryRow(label: 'Subtotal', value: 'KSh ${session.amount.toStringAsFixed(0)}'),
                                const SizedBox(height: 8),
                                _SummaryRow(label: 'Service Fee', value: 'KSh 0'), // Simplified for now
                                const SizedBox(height: 16),
                                Divider(color: Colors.white.withValues(alpha: 0.06), height: 1),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Total Amount',
                                        style: TextStyle(
                                            color: kTextPrimary,
                                            fontWeight: FontWeight.w700)),
                                    Text('KSh ${session.amount.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                            color: kPrimary,
                                            fontSize: 24,
                                            fontWeight: FontWeight.w900)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // M-Pesa section
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('PAYMENT METHOD',
                              style: TextStyle(
                                  color: kTextSecondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5)),
                          const SizedBox(height: 12),
                          AppCard(
                            borderColor: kPrimary,
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: kPrimary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Center(child: Icon(Icons.phone_android, color: kPrimary)),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('M-Pesa', style: TextStyle(color: kTextPrimary, fontWeight: FontWeight.w700)),
                                      Text('Pay via M-Pesa STK Push', style: TextStyle(color: kTextSecondary, fontSize: 12)),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.check_circle, color: kPrimary),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text('M-Pesa Phone Number',
                              style: TextStyle(
                                  color: kTextSecondary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: controller.phoneController,
                            keyboardType: TextInputType.phone,
                            style: const TextStyle(color: kTextPrimary, fontWeight: FontWeight.w700),
                            decoration: InputDecoration(
                              hintText: '2547XXXXXXXX',
                              hintStyle: TextStyle(color: kTextSecondary.withValues(alpha: 0.5)),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                              'Confirm your number. You will receive an M-Pesa prompt to enter your PIN.',
                              style: TextStyle(color: kTextSecondary, fontSize: 12, height: 1.4)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Fixed bottom pay button
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                decoration: BoxDecoration(
                  color: kBgCard,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 20, spreadRadius: 5)
                  ],
                  border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Obx(() => PrimaryButton(
                      label: controller.isProcessing.value 
                        ? 'Processing Payment...' 
                        : 'Pay KSh ${session.amount.toStringAsFixed(0)} via M-Pesa',
                      onPressed: controller.isProcessing.value 
                        ? null 
                        : () => controller.processPayment(),
                    )),
                  ],
                ),
              ),
            ),
            
            // Loading Overlay
            Obx(() => controller.isProcessing.value 
              ? Container(
                  color: Colors.black.withValues(alpha: 0.6),
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: kPrimary),
                        SizedBox(height: 24),
                        Text('Requesting M-Pesa PIN...', 
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                )
              : const SizedBox.shrink()
            ),
          ],
        );
      }),
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
        Text(value, style: const TextStyle(color: kTextPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
