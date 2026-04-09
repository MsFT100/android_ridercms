import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ridercms/utils/themes/app_theme.dart';
import '../../controllers/charging_controller.dart';

class ChargingStopWaitScreen extends StatefulWidget {
  const ChargingStopWaitScreen({super.key});

  @override
  State<ChargingStopWaitScreen> createState() => _ChargingStopWaitScreenState();
}

class _ChargingStopWaitScreenState extends State<ChargingStopWaitScreen> with SingleTickerProviderStateMixin {
  int _secondsRemaining = 25;
  Timer? _timer;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
      lowerBound: 0.8,
      upperBound: 1.1,
    )..repeat(reverse: true);

    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        _timer?.cancel();
        _initiateWithdrawal();
      }
    });
  }

  void _initiateWithdrawal() {
    // Call the controller to handle backend withdrawal initiation
    final controller = Get.find<ChargingController>();
    controller.startWithdrawal();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Spacer(),
              
              // Animated Pulse
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    ScaleTransition(
                      scale: _pulseController,
                      child: Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          color: kPrimary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Container(
                      width: 100,
                      height: 100,
                      decoration: const BoxDecoration(
                        color: kBgCard,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '$_secondsRemaining',
                          style: const TextStyle(
                            color: kPrimary,
                            fontSize: 40,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 48),
              const Text(
                'Stopping Charge',
                style: TextStyle(
                  color: kTextPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Please wait a few moments while we safely stop the power flow to your battery.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: kTextSecondary,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
              
              const Spacer(),
              
              // Warning card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kWarning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: kWarning.withValues(alpha: 0.2)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: kWarning),
                    SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Do not close the app or disconnect from the internet during this process.',
                        style: TextStyle(color: kTextSecondary, fontSize: 12),
                      ),
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
