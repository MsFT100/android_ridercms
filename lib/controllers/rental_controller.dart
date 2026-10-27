import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../models/rental_models.dart';
import '../providers/user_provider.dart';
import '../services/booth_service.dart';

/// Steps of the rental lifecycle. Mirrors `RentalFlow.tsx` one-to-one.
enum RentalStep {
  boothScan,
  issuing,
  collecting,
  active,
  returning,
  verifyReturn,
  waitingReturn,
  chargingComplete,
  bill,
  payment,
  paymentConfirmed,
  unlockOwn,
  collected,
  closed,
  error,
}

enum RentalPaymentStage { idle, waiting, success, failed }

/// Drives the whole rental battery journey: issue → collect → use → return →
/// bill → pay → unlock own battery.
///
/// The rider never chooses a battery; the entry point hands over an
/// [AssignedRental] (highest-SOC pool battery) and this controller opens its
/// slot.
class RentalController extends GetxController {
  final BoothService _boothService = BoothService();

  static const Duration collectingInterval = Duration(milliseconds: 1500);
  static const Duration activeInterval = Duration(seconds: 5);
  static const Duration paymentPollInterval = Duration(milliseconds: 2500);
  static const Duration paymentTimeout = Duration(seconds: 90);

  var step = RentalStep.issuing.obs;
  final config = RentalFeatureStatus().obs;
  var boothUid = ''.obs;
  var boothName = ''.obs;
  final assigned = Rxn<AssignedRental>();
  final active = Rxn<ActiveRental>();
  final bill = Rxn<RentalBill>();
  final returnSlot = Rxn<RentalSlotRef>();
  final ownSlot = Rxn<RentalSlotRef>();
  var error = ''.obs;
  var returnError = ''.obs;
  var isBusy = false.obs;
  var isIssuing = false.obs;
  var isStarting = true.obs;
  var paymentStage = RentalPaymentStage.idle.obs;

  /// Active rental id (also the id of the deposit row on the server).
  int? sessionId;

  Timer? _pollTimer;
  bool _disposed = false;

  /// STK request awaiting a result; set until it is known paid or failed.
  String? _pendingCheckoutId;

  String get displayBoothName =>
      boothName.value.trim().isNotEmpty ? boothName.value.trim() : boothUid.value;

  String get rentalBatteryId =>
      assigned.value?.batteryUid ??
      active.value?.batteryUid ??
      'Rental battery';

  String get assignedSlotIdentifier =>
      assigned.value?.slotIdentifier ??
      active.value?.sourceSlot.slotIdentifier ??
      '';

  int get ownBatterySoc => active.value?.ownDeposit.currentSoc ?? 0;

  @override
  void onInit() {
    super.onInit();
    start();
  }

  /// Reads the navigation arguments and restores the correct step.
  ///
  /// Two entry points are supported:
  ///  * dashboard → `assigned` + `config` (start a new rental),
  ///  * splash/dashboard resume → nothing, so the active rental is fetched.
  Future<void> start() async {
    final dynamic args = Get.arguments;
    ActiveRental? initialActive;

    if (args is Map) {
      boothUid.value = args['boothUid']?.toString() ?? '';
      boothName.value = args['boothName']?.toString() ?? '';
      final dynamic rawAssigned = args['assigned'];
      if (rawAssigned is AssignedRental) assigned.value = rawAssigned;
      final dynamic rawConfig = args['config'];
      if (rawConfig is RentalFeatureStatus) config.value = rawConfig;
      final dynamic rawActive = args['activeRental'];
      if (rawActive is ActiveRental) initialActive = rawActive;
    }

    isStarting.value = true;
    try {
      ActiveRental? current = initialActive;
      if (current == null) {
        final token = await _token();
        if (token == null) {
          _fail('Authentication failed. Please log in again.');
          return;
        }
        current = await _boothService.getActiveRental(token);
      }
      if (_disposed) return;
      isStarting.value = false;
      _applyActive(current);
    } catch (e) {
      if (!_disposed) _fail(_message(e));
    } finally {
      if (!_disposed) isStarting.value = false;
    }
  }

  void _applyActive(ActiveRental? current) {
    if (current == null) {
      if (assigned.value != null) {
        // A rental battery was pre-assigned: start the issue sequence.
        if (boothUid.value.isEmpty) {
          boothUid.value = assigned.value!.boothUid;
        }
        goTo(
          config.value.requireBoothScanBeforeIssue
              ? RentalStep.boothScan
              : RentalStep.issuing,
        );
        return;
      }
      // Nothing to resume — nothing to rent.
      Get.offAllNamed('/dashboard');
      return;
    }

    active.value = current;
    sessionId = current.sessionId;
    error.value = '';

    // Resumed sessions were not opened from the dashboard, so the booth has to
    // be recovered from the rental snapshot itself.
    if (boothUid.value.isEmpty && current.sourceSlot.boothUid.isNotEmpty) {
      boothUid.value = current.sourceSlot.boothUid;
    }
    if (current.returnSlot?.isValid == true) {
      returnSlot.value = current.returnSlot;
    }
    if (current.ownDeposit.slotIdentifier.isNotEmpty) {
      ownSlot.value = RentalSlotRef(
        boothUid: current.ownDeposit.boothUid.isNotEmpty
            ? current.ownDeposit.boothUid
            : boothUid.value,
        slotIdentifier: current.ownDeposit.slotIdentifier,
      );
    }

    if (current.isPending) {
      goTo(RentalStep.collecting);
      return;
    }
    if (current.returned) {
      goTo(
        current.returnCompleted
            ? RentalStep.chargingComplete
            : RentalStep.waitingReturn,
      );
      return;
    }
    goTo(RentalStep.active);
  }

  /// Central transition point: resets polling and starts the work for [next].
  void goTo(RentalStep next) {
    _cancelPolling();
    step.value = next;

    switch (next) {
      case RentalStep.issuing:
        _issue();
      case RentalStep.collecting:
        _startPolling(RentalStep.collecting, collectingInterval);
      case RentalStep.active:
        _startPolling(RentalStep.active, activeInterval);
      case RentalStep.waitingReturn:
        _startPolling(RentalStep.waitingReturn, collectingInterval);
      case RentalStep.bill:
        loadBill();
      default:
        break;
    }
  }

  void _startPolling(RentalStep forStep, Duration interval) {
    _cancelPolling();
    unawaited(_tick(forStep));
    _pollTimer = Timer.periodic(interval, (_) => _tick(forStep));
  }

  void _cancelPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> _tick(RentalStep forStep) async {
    if (_disposed || step.value != forStep) return;
    final token = await _token();
    if (token == null) return;

    try {
      final current = await _boothService.getActiveRental(token);
      if (_disposed || step.value != forStep) return;

      if (current == null) {
        // The rental finished elsewhere (paid on another device) — stop polling.
        _cancelPolling();
        return;
      }

      active.value = current;
      sessionId = current.sessionId;

      if (forStep == RentalStep.collecting && current.isActive) {
        goTo(RentalStep.active);
      } else if (forStep == RentalStep.waitingReturn &&
          current.returnCompleted) {
        goTo(RentalStep.chargingComplete);
      }
    } catch (_) {
      // Transient failure: the next tick retries.
    }
  }

  /// PK / open the assigned slot for a new rental.
  Future<void> _issue() async {
    if (isIssuing.value) return;

    final rental = assigned.value;
    if (rental == null) {
      _fail('No rental battery was assigned. Please try again.');
      return;
    }

    isIssuing.value = true;
    error.value = '';

    try {
      final token = await _token();
      if (token == null) {
        _fail('Authentication failed. Please log in again.');
        return;
      }

      final result = await _boothService.issueRental(
        token,
        boothUid: boothUid.value.isNotEmpty ? boothUid.value : rental.boothUid,
        slotIdentifier: rental.slotIdentifier,
      );
      if (_disposed) return;

      sessionId = result.sessionId;

      if (result.status.toLowerCase() == 'in_progress') {
        try {
          active.value = await _boothService.getActiveRental(token);
        } catch (_) {
          // The active snapshot is optional here.
        }
        goTo(RentalStep.active);
      } else {
        goTo(RentalStep.collecting);
      }
    } catch (e) {
      if (!_disposed) _fail(_message(e));
    } finally {
      if (!_disposed) isIssuing.value = false;
    }
  }

  /// Booth QR gate before issuing. Returns `true` when the code matches.
  bool matchesBooth(String code) =>
      code.trim().toLowerCase() == boothUid.value.trim().toLowerCase();

  bool onBoothScanned(String code) {
    if (!matchesBooth(code)) return false;
    goTo(RentalStep.issuing);
    return true;
  }

  /// Battery QR gate before the return is considered complete.
  bool onReturnBatteryScanned(String code) {
    final expected = active.value?.batteryUid ?? assigned.value?.batteryUid ?? '';
    if (expected.isEmpty || code.trim().toLowerCase() != expected.toLowerCase()) {
      return false;
    }
    goTo(RentalStep.waitingReturn);
    return true;
  }

  /// Reserves a free slot at the booth and opens it for the return.
  Future<void> requestReturn() async {
    final id = sessionId;
    if (id == null) {
      returnError.value = 'No rental session found.';
      return;
    }
    if (boothUid.value.isEmpty) {
      returnError.value = 'No booth selected for the return.';
      return;
    }

    isBusy.value = true;
    returnError.value = '';

    try {
      final token = await _token();
      if (token == null) {
        throw BoothApiException('Authentication failed. Please log in again.');
      }

      final result = await _boothService.returnRental(token, id, boothUid.value);
      if (_disposed) return;

      returnSlot.value = result.returnSlot;
      try {
        active.value = await _boothService.getActiveRental(token);
      } catch (_) {
        // Non-fatal: the reserved slot is already known.
      }

      goTo(
        config.value.requireReturnScan
            ? RentalStep.verifyReturn
            : RentalStep.waitingReturn,
      );
    } catch (e) {
      returnError.value = _message(e);
    } finally {
      if (!_disposed) isBusy.value = false;
    }
  }

  /// Consolidated bill preview (own charging + rental energy + rental time).
  Future<void> loadBill() async {
    final id = sessionId;
    if (id == null) {
      _fail('No rental session found.');
      return;
    }
    if (bill.value != null && bill.value!.sessionId == id) return;

    try {
      final token = await _token();
      if (token == null) return;
      final result = await _boothService.getRentalBill(token, id);
      if (_disposed || step.value != RentalStep.bill) return;
      bill.value = result;
    } catch (e) {
      if (!_disposed) _fail(_message(e));
    }
  }

  void startPayment() {
    paymentStage.value = RentalPaymentStage.idle;
    goTo(RentalStep.payment);
  }

  void backToBill() => goTo(RentalStep.bill);

  /// STK push + status polling (dev booths auto-approve).
  Future<bool> pay() async {
    final id = sessionId;
    if (id == null) return false;

    paymentStage.value = RentalPaymentStage.waiting;

    try {
      final token = await _token();
      if (token == null) {
        paymentStage.value = RentalPaymentStage.failed;
        return false;
      }

      // A previous attempt that timed out may still be paid on the rider's
      // phone. Resume watching that request instead of sending a second STK
      // push, which could charge them twice.
      String? checkoutId = _pendingCheckoutId;

      if (checkoutId == null) {
        final result = await _boothService.payRental(token, id);
        if (_disposed) return false;

        bill.value = RentalBill(
          sessionId: id,
          amount: result.amount,
          consolidation: result.consolidation,
        );

        if (result.isPaid) {
          paymentStage.value = RentalPaymentStage.success;
          return true;
        }

        checkoutId = result.checkoutRequestId;
        if (checkoutId == null || checkoutId.isEmpty) {
          paymentStage.value = RentalPaymentStage.failed;
          return false;
        }
        _pendingCheckoutId = checkoutId;
      }

      final deadline = DateTime.now().add(paymentTimeout);
      while (DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(paymentPollInterval);
        if (_disposed) return false;
        try {
          // Fresh token per poll: the one above can expire during the wait.
          final pollToken = await _token() ?? token;
          final status =
              await _boothService.getRentalPaymentStatus(pollToken, checkoutId);
          final normalized = status.toLowerCase();
          if (normalized == 'paid') {
            _pendingCheckoutId = null;
            paymentStage.value = RentalPaymentStage.success;
            return true;
          }
          if (normalized == 'failed') {
            // Definitively failed: the next attempt may send a new request.
            _pendingCheckoutId = null;
            paymentStage.value = RentalPaymentStage.failed;
            return false;
          }
        } catch (_) {
          // Keep polling until the deadline.
        }
      }

      // Timed out without an answer: keep [_pendingCheckoutId] so "Try Again"
      // re-checks this request first.
      paymentStage.value = RentalPaymentStage.failed;
      return false;
    } catch (_) {
      if (!_disposed) paymentStage.value = RentalPaymentStage.failed;
      return false;
    }
  }

  void continueAfterPayment() => goTo(RentalStep.paymentConfirmed);

  void continueToUnlockOwn() => goTo(RentalStep.unlockOwn);

  /// Opens the slot holding the rider's own (fully charged) battery.
  Future<void> unlockOwn() async {
    final id = sessionId;
    if (id == null) return;

    isBusy.value = true;
    error.value = '';

    try {
      final token = await _token();
      if (token == null) {
        throw BoothApiException('Authentication failed. Please log in again.');
      }
      final result = await _boothService.unlockOwnBattery(token, id);
      if (_disposed) return;
      ownSlot.value = result.ownSlot;
      goTo(RentalStep.collected);
    } catch (e) {
      if (!_disposed) error.value = _message(e);
    } finally {
      if (!_disposed) isBusy.value = false;
    }
  }

  void continueToClosed() => goTo(RentalStep.closed);

  /// Retry the issue sequence after an error.
  void retry() {
    error.value = '';
    goTo(
      config.value.requireBoothScanBeforeIssue
          ? RentalStep.boothScan
          : RentalStep.issuing,
    );
  }

  /// Leaves the flow and refreshes the dashboard's battery list.
  void finish() {
    _cancelPolling();
    Get.offAllNamed('/dashboard');
  }

  void _fail(String message) {
    error.value = message;
    goTo(RentalStep.error);
  }

  Future<String?> _token() async {
    final BuildContext? context = Get.context;
    if (context == null) return null;
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      return await userProvider.getFreshToken();
    } catch (e) {
      debugPrint('RentalController: failed to read token: $e');
      return null;
    }
  }

  String _message(Object error) {
    if (error is BoothApiException) {
      return error.message.isNotEmpty ? error.message : 'Something went wrong.';
    }
    final raw = error.toString();
    return raw
        .replaceFirst('Exception: ', '')
        .replaceFirst('BoothApiException: ', '');
  }

  @override
  void onClose() {
    _disposed = true;
    _cancelPolling();
    super.onClose();
  }
}
