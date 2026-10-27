import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/rental_controller.dart';
import '../../../utils/themes/app_theme.dart';
import 'consolidated_rental_bill_screen.dart';
import 'own_battery_charging_complete_screen.dart';
import 'rental_active_screen.dart';
import 'rental_battery_collected_screen.dart';
import 'rental_booth_scan_screen.dart';
import 'rental_collecting_screen.dart';
import 'rental_error_screen.dart';
import 'rental_issuing_screen.dart';
import 'rental_payment_confirmed_screen.dart';
import 'rental_payment_screen.dart';
import 'rental_progress_view.dart';
import 'rental_session_closed_screen.dart';
import 'rental_waiting_return_screen.dart';
import 'return_rental_battery_screen.dart';
import 'unlock_own_battery_screen.dart';
import 'verify_rental_return_screen.dart';

/// Host for the rental journey. The whole flow lives on one route; the
/// [RentalController] state machine decides which step body is shown, exactly
/// like the web `RentalFlow.tsx`.
class RentalFlowScreen extends StatefulWidget {
  const RentalFlowScreen({super.key});

  @override
  State<RentalFlowScreen> createState() => _RentalFlowScreenState();
}

class _RentalFlowScreenState extends State<RentalFlowScreen> {
  late final RentalController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<RentalController>();
  }

  @override
  void dispose() {
    // Each visit must start from fresh state; `fenix` rebuilds the controller
    // (and re-runs `start()`) the next time the flow opens.
    if (Get.isRegistered<RentalController>()) {
      Get.delete<RentalController>();
    }
    super.dispose();
  }

  void _handleBack() {
    // Never abandon the screen while an STK push is in flight.
    if (_controller.paymentStage.value == RentalPaymentStage.waiting) return;
    _controller.finish();
  }

  Widget _bodyFor(RentalStep step) {
    switch (step) {
      case RentalStep.boothScan:
        return const RentalBoothScanScreen();
      case RentalStep.issuing:
        return const RentalIssuingScreen();
      case RentalStep.collecting:
        return const RentalCollectingScreen();
      case RentalStep.active:
        return const RentalActiveScreen();
      case RentalStep.returning:
        return const ReturnRentalBatteryScreen();
      case RentalStep.verifyReturn:
        return const VerifyRentalReturnScreen();
      case RentalStep.waitingReturn:
        return const RentalWaitingReturnScreen();
      case RentalStep.chargingComplete:
        return const OwnBatteryChargingCompleteScreen();
      case RentalStep.bill:
        return const ConsolidatedRentalBillScreen();
      case RentalStep.payment:
        return const RentalPaymentScreen();
      case RentalStep.paymentConfirmed:
        return const RentalPaymentConfirmedScreen();
      case RentalStep.unlockOwn:
        return const UnlockOwnBatteryScreen();
      case RentalStep.collected:
        return const RentalBatteryCollectedScreen();
      case RentalStep.closed:
        return const RentalSessionClosedScreen();
      case RentalStep.error:
        return const RentalErrorScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBack();
      },
      child: Scaffold(
        backgroundColor: kBgDark,
        body: SafeArea(
          child: Obx(() {
            if (_controller.isStarting.value) {
              return const RentalProgressView(
                title: 'Loading your rental',
                subtitle: 'Checking for an active rental session…',
              );
            }

            final step = _controller.step.value;
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: KeyedSubtree(
                key: ValueKey<RentalStep>(step),
                child: _bodyFor(step),
              ),
            );
          }),
        ),
      ),
    );
  }
}
