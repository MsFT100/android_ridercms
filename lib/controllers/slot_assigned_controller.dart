import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import '../models/booth_models.dart';
import '../providers/user_provider.dart';
import '../services/booth_service.dart';
import 'charging_controller.dart';

enum DoorStatus { opening, open, insert, closing, closed }

/// Tracks one deposit session until the hardware confirms it.
///
/// Besides the Firebase slot listener it polls `/my-battery-status` for this
/// specific `sessionId` and `/deposit-sessions/:id/status` so a booth-side
/// cancellation can never leave the rider stuck on "waiting".
class SlotAssignedController extends GetxController {
  final BoothService _boothService = BoothService();
  final FirebaseDatabase _db = FirebaseDatabase.instance;

  var doorStatus = DoorStatus.opening.obs;
  var slotIdentifier = '---'.obs;
  var boothName = 'Station'.obs;
  var boothUid = ''.obs;
  var sessionId = RxnInt();

  /// The backend closed this deposit (cancelled/failed) before completion.
  var cancelled = false.obs;
  var cancelReason = ''.obs;

  StreamSubscription? _statusSubscription;
  Timer? _pollingTimer;
  bool _finished = false;

  @override
  void onInit() {
    super.onInit();
    final dynamic args = Get.arguments;

    if (args is Map) {
      if (args['slotIdentifier'] != null) {
        slotIdentifier.value = args['slotIdentifier'].toString();
      } else if (args['slot'] is Map && args['slot']['identifier'] != null) {
        slotIdentifier.value = args['slot']['identifier'].toString();
      }
      if (args['sessionId'] != null) {
        sessionId.value =
            int.tryParse(args['sessionId'].toString());
      }
      boothName.value = args['boothName'] ?? 'Station';
      boothUid.value = args['boothUid'] ?? '';
    }

    // A dev booth completes the deposit before the app even navigates here.
    if (args is Map && args['slot'] is Map && args['slot']['status'] == 'completed') {
      _onSequenceComplete();
      return;
    }

    _simulateOpening();

    if (boothUid.value.isNotEmpty && slotIdentifier.value != '---') {
      _startFirebaseListener();
    }
    _startPolling();
  }

  void _simulateOpening() {
    Future.delayed(const Duration(seconds: 2), () {
      if (!_finished && doorStatus.value == DoorStatus.opening) {
        doorStatus.value = DoorStatus.open;
      }
    });
  }

  void _startFirebaseListener() {
    final ref = _db.ref('booths/${boothUid.value}/slots/${slotIdentifier.value}');

    _statusSubscription = ref.onValue.listen((event) {
      final data = event.snapshot.value;
      if (data == null || data is! Map) return;

      final dynamic rawTelemetry = data['telemetry'];
      final Map telemetry = rawTelemetry is Map ? rawTelemetry : data;
      final bool doorLocked =
          _asBool(telemetry['doorLocked'] ?? data['locked']);
      final bool batteryInserted =
          _asBool(telemetry['batteryInserted'] ?? data['present']);

      if (batteryInserted && doorLocked) {
        _onSequenceComplete();
      } else if (batteryInserted) {
        doorStatus.value = DoorStatus.insert;
      } else if (!doorLocked) {
        doorStatus.value = DoorStatus.open;
      }
    });
  }

  /// Realtime DB values may arrive as bool, 0/1 or "true"/"false".
  bool _asBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) return value.toLowerCase() == 'true' || value == '1';
    return false;
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      await _pollOnce();
    });
  }

  Future<void> _pollOnce() async {
    if (_finished) return;
    final BuildContext? context = Get.context;
    if (context == null) return;

    final userProvider = Provider.of<UserProvider>(context, listen: false);

    try {
      final token = await userProvider.getFreshToken();
      if (token == null) return;

      final statuses = await _boothService.getMyBatteryStatuses(token);
      final mine = _findMine(statuses);

      if (mine != null && mine.isTerminal) {
        _onCancelled(
          mine.sessionStatus.toLowerCase() == 'failed'
              ? 'The booth could not complete your deposit.'
              : 'Your deposit was cancelled.',
        );
        return;
      }
      if (mine != null && mine.sessionStatus.toLowerCase() != 'pending') {
        _onSequenceComplete();
        return;
      }

      // Not in the completed-deposit feed: check whether it was cancelled.
      if (mine == null && sessionId.value != null) {
        final status =
            await _boothService.getDepositSessionStatus(token, sessionId.value!);
        if (status.isTerminal) {
          _onCancelled(
            status.sessionStatus == 'failed'
                ? 'The booth could not complete your deposit.'
                : 'Your deposit was cancelled.',
          );
        }
      }
    } catch (e) {
      if (kDebugMode) print('Slot polling error: $e');
    }
  }

  MyBatteryStatus? _findMine(List<MyBatteryStatus> statuses) {
    if (statuses.isEmpty) return null;
    if (sessionId.value == null) return statuses.first;
    for (final status in statuses) {
      if (status.sessionId == sessionId.value) return status;
    }
    return null;
  }

  void _onSequenceComplete() {
    if (_finished) return;
    _finished = true;
    _pollingTimer?.cancel();
    _statusSubscription?.cancel();
    doorStatus.value = DoorStatus.closed;
    // Make the new battery visible to the multi-battery views straight away.
    if (Get.isRegistered<ChargingController>()) {
      Get.find<ChargingController>().refreshBatteries(silent: true);
    }
  }

  void _onCancelled(String reason) {
    if (_finished) return;
    _finished = true;
    _pollingTimer?.cancel();
    _statusSubscription?.cancel();
    cancelled.value = true;
    cancelReason.value = reason;
  }

  Future<void> cancelSession() async {
    final BuildContext? context = Get.context;
    if (context == null) return;

    final userProvider = Provider.of<UserProvider>(context, listen: false);

    try {
      final token = await userProvider.getFreshToken();
      if (token == null) throw 'Authentication failed';

      await _boothService.cancelActiveSession(token);
      _pollingTimer?.cancel();
      _statusSubscription?.cancel();
      Get.offAllNamed('/dashboard');
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to cancel session: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
    }
  }

  @override
  void onClose() {
    _pollingTimer?.cancel();
    _statusSubscription?.cancel();
    super.onClose();
  }
}
