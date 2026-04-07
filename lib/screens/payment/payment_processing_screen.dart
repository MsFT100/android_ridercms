import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ridercms/widgets/common_widgets.dart';
import '../../models/booth_models.dart';
import '../../services/booth_service.dart';
import '../../utils/themes/app_theme.dart';

class PaymentProcessingScreen extends StatefulWidget {
  const PaymentProcessingScreen({super.key});

  @override
  State<PaymentProcessingScreen> createState() => _PaymentProcessingScreenState();
}

class _Step {
  final String label;
  final int durationMs;
  const _Step({required this.label, required this.durationMs});
}

const List<_Step> _steps = [
  _Step(label: 'Connecting to M-Pesa...', durationMs: 1500),
  _Step(label: 'Waiting for PIN entry...', durationMs: 5000),
  _Step(label: 'Verifying transaction...', durationMs: 2500),
  _Step(label: 'Finalizing session...', durationMs: 1500),
];

class _PaymentProcessingScreenState extends State<PaymentProcessingScreen>
    with SingleTickerProviderStateMixin {
  final BoothService _boothService = BoothService();
  int _currentStep = 0;
  bool _isFinalizing = false;
  Timer? _pollingTimer;
  late AnimationController _pulseController;

  late final String checkoutRequestId;
  late final WithdrawalSession session;
  late final String token;

  @override
  void initState() {
    super.initState();
    checkoutRequestId = Get.arguments['checkoutRequestId'];
    session = Get.arguments['session'];
    token = Get.arguments['token'];

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
      lowerBound: 0.9,
      upperBound: 1.2,
    )..repeat(reverse: true);

    _startProgressAnimation();
    _startPolling();
  }

  void _startProgressAnimation() {
    int total = 0;
    for (int i = 0; i < _steps.length; i++) {
      Future.delayed(Duration(milliseconds: total), () {
        if (mounted && _currentStep < i) {
          setState(() => _currentStep = i);
        }
      });
      total += _steps[i].durationMs;
    }
  }

  void _startPolling() {
    int attempts = 0;
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      attempts++;
      if (attempts > 30) { // 90 seconds timeout
        _handleFailure('Payment timed out. Please check your M-Pesa.');
        return;
      }

      try {
        final status = await _boothService.getWithdrawalStatus(token, checkoutRequestId);
        final normalizedStatus = status.toLowerCase();
        
        debugPrint('M-Pesa Status Received: $normalizedStatus');

        // Added 'paid' to support your backend's specific status string
        if (normalizedStatus == 'completed' || normalizedStatus == 'success' || normalizedStatus == 'paid') {
          _handleSuccess();
        } else if (normalizedStatus == 'failed' || normalizedStatus == 'cancelled') {
          _handleFailure('M-Pesa transaction was cancelled or failed.');
        }
      } catch (e) {
        debugPrint('Polling Error: $e');
        // Silently continue polling
      }
    });
  }

  void _handleSuccess() {
    _pollingTimer?.cancel();
    if (!mounted) return;
    setState(() => _isFinalizing = true);
    
    Future.delayed(const Duration(milliseconds: 1500), () {
      Get.offNamed('/payment-success', arguments: {
        'session': session,
        'checkoutRequestId': checkoutRequestId,
      });
    });
  }

  void _handleFailure(String error) {
    _pollingTimer?.cancel();
    if (!mounted) return;
    Get.offNamed('/payment-failed', arguments: {'error': error});
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Stack(
                alignment: Alignment.center,
                children: [
                  ScaleTransition(
                    scale: _pulseController,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        color: kPrimary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: kBgCard,
                      shape: BoxShape.circle,
                      border: Border.all(color: kPrimary.withValues(alpha: 0.3), width: 2),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(color: kPrimary, strokeWidth: 3),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              Text(
                _isFinalizing ? "Finalizing Transaction" : "Processing Payment",
                style: const TextStyle(color: kTextPrimary, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                "Please wait while your payment is being processed.",
                textAlign: TextAlign.center,
                style: TextStyle(color: kTextSecondary, fontSize: 15),
              ),
              const SizedBox(height: 8),
              const Text(
                "Please do not close this screen or go back",
                textAlign: TextAlign.center,
                style: TextStyle(color: kTextSecondary, fontSize: 13, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 48),
              // Steps
              ..._steps.asMap().entries.map((entry) {
                final i = entry.key;
                final step = entry.value;
                final isCompleted = i < _currentStep || _isFinalizing;
                final isCurrent = i == _currentStep && !_isFinalizing;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    children: [
                      Icon(
                        isCompleted ? Icons.check_circle : Icons.radio_button_checked,
                        color: isCompleted ? kPrimary : (isCurrent ? kPrimary : kTextSecondary.withValues(alpha: 0.3)),
                        size: 20,
                      ),
                      const SizedBox(width: 16),
                      Text(
                        step.label,
                        style: TextStyle(
                          color: isCompleted || isCurrent ? kTextPrimary : kTextSecondary.withValues(alpha: 0.5),
                          fontSize: 15,
                          fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const Spacer(),
              // Amount Info
              AppCard(
                child: Column(
                  children: [
                    const Text("Amount to be paid", style: TextStyle(color: kTextSecondary, fontSize: 12)),
                    const SizedBox(height: 8),
                    Text(
                      "KSh ${session.amount}",
                      style: const TextStyle(color: kPrimary, fontSize: 32, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
