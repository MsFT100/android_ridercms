import 'dart:async';
import 'package:flutter/material.dart';

class PaymentProcessingScreen extends StatefulWidget {
  const PaymentProcessingScreen({super.key});

  @override
  State<PaymentProcessingScreen> createState() =>
      _PaymentProcessingScreenState();
}

class _Step {
  final String label;
  final int durationMs;

  const _Step({required this.label, required this.durationMs});
}

const List<_Step> _steps = [
  _Step(label: 'Connecting to M-Pesa...', durationMs: 1500),
  _Step(label: 'Sending payment prompt...', durationMs: 2000),
  _Step(label: 'Waiting for confirmation...', durationMs: 2500),
  _Step(label: 'Verifying transaction...', durationMs: 1500),
  _Step(label: 'Payment confirmed!', durationMs: 1000),
];

class _PaymentProcessingScreenState extends State<PaymentProcessingScreen>
    with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  bool _done = false;

  final List<Timer> _timers = [];
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
      lowerBound: 0.9,
      upperBound: 1.2,
    )..repeat(reverse: true);

    int total = 0;

    for (int i = 0; i < _steps.length; i++) {
      final idx = i;

      _timers.add(
        Timer(Duration(milliseconds: total), () {
          if (!mounted) return;

          setState(() {
            _currentStep = idx;
          });

          if (idx == _steps.length - 1) {
            _finishProcess();
          }
        }),
      );

      total += _steps[i].durationMs;
    }
  }

  void _finishProcess() {
    _timers.add(
      Timer(const Duration(milliseconds: 800), () {
        if (!mounted) return;

        setState(() {
          _done = true;
        });

        _pulseController.stop();

        _timers.add(
          Timer(const Duration(milliseconds: 800), () {
            if (!mounted) return;

            Navigator.pushReplacementNamed(context, '/payment-success');
          }),
        );
      }),
    );
  }

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }

    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                /// Animated Circle
                Stack(
                  alignment: Alignment.center,
                  children: [
                    if (!_done)
                      ScaleTransition(
                        scale: _pulseController,
                        child: Container(
                          width: 128,
                          height: 128,
                          decoration: const BoxDecoration(
                            color: Color(0x22FFFFFF),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),

                    AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      width: 128,
                      height: 128,
                      decoration: BoxDecoration(
                        color: _done ? Colors.green : const Color(0xFF1E1E1E),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white24,
                          width: 3,
                        ),
                      ),
                      child: Center(
                        child: _done
                            ? const Text(
                          "✓",
                          style: TextStyle(
                            fontSize: 48,
                            color: Colors.white,
                          ),
                        )
                            : const CircularProgressIndicator(
                          color: Colors.green,
                          strokeWidth: 3,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                /// Title
                Text(
                  _done ? "Payment Successful!" : "Processing Payment",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                const Text(
                  "Please do not close this screen",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 40),

                /// Steps
                ..._steps.asMap().entries.map((entry) {
                  final i = entry.key;
                  final step = entry.value;

                  final isCompleted = i < _currentStep || _done;
                  final isCurrent = i == _currentStep && !_done;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? Colors.green
                                : isCurrent
                                ? Colors.greenAccent
                                : Colors.grey,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              isCompleted
                                  ? "✓"
                                  : isCurrent
                                  ? "•"
                                  : "${i + 1}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: Text(
                            step.label,
                            style: TextStyle(
                              color: isCompleted
                                  ? Colors.green
                                  : isCurrent
                                  ? Colors.white
                                  : Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 40),

                /// Amount Card
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Column(
                    children: [
                      Text(
                        "Amount",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "KSh 284",
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "via M-Pesa",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}