import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../models/booth_models.dart';
import '../providers/user_provider.dart';
import '../services/booth_service.dart';

enum ActiveSessionType { none, charging, payment }

/// Owns the rider's **list** of deposited batteries and keeps each one live
/// with a dedicated Firebase listener.
///
/// The backend can return several deposits at once (`GET /my-battery-status`
/// answers with an array), so every screen works against [batteries] instead of
/// a single status object.
class ChargingController extends GetxController with WidgetsBindingObserver {
  final BoothService _boothService = BoothService();
  final FirebaseDatabase _db = FirebaseDatabase.instance;

  /// All batteries currently held by the rider at a booth.
  final batteries = <MyBatteryStatus>[].obs;

  /// Index of the battery the single-battery screens are showing.
  final activeIndex = 0.obs;

  var isLoading = true.obs;
  var sessionType = ActiveSessionType.none.obs;

  /// Rider has an unpaid withdrawal waiting (payment must resume).
  var hasPendingWithdrawal = false.obs;
  final pendingWithdrawal = Rxn<WithdrawalSession>();

  /// Set when the rider taps "Collect" on a specific battery; consumed by the
  /// stop-charging wait screen.
  final collectionSessionId = RxnInt();

  final Map<String, StreamSubscription> _listeners = {};
  Timer? _pollTimer;
  Future<void>? _inFlightRefresh;
  bool _inForeground = true;
  bool _pollWanted = false;
  int _pollClients = 0;
  Duration _pollInterval = const Duration(seconds: 2);

  /// Kept in sync with [activeBattery] so the single-battery screens that read
  /// `controller.batteryStatus.value` keep working.
  final _activeBattery = Rxn<MyBatteryStatus>();

  bool get hasAnyBattery => batteries.isNotEmpty;

  int get batteryCount => batteries.length;

  MyBatteryStatus? get activeBattery {
    if (batteries.isEmpty) return null;
    final index = activeIndex.value.clamp(0, batteries.length - 1);
    return batteries[index];
  }

  /// Backwards-compatible alias used by single-battery screens.
  Rxn<MyBatteryStatus> get batteryStatus => _activeBattery;

  void _syncActiveBattery() {
    _activeBattery.value = activeBattery;
  }

  bool hasActiveSession() => sessionType.value != ActiveSessionType.none;

  MyBatteryStatus? batteryAt(int index) {
    if (index < 0 || index >= batteries.length) return null;
    return batteries[index];
  }

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    ever(batteries, (_) => _syncActiveBattery());
    ever(activeIndex, (_) => _syncActiveBattery());
    // Initial load; Splash re-runs this once a token exists.
    checkSessionStatus();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _inForeground = state == AppLifecycleState.resumed;
    if (!_inForeground) {
      _cancelPollTimer();
    } else {
      _ensurePollTimer();
      // Catch up on anything that changed while the app was away.
      if (_pollWanted) refreshBatteries(silent: true);
    }
  }

  /// Solves the auth token, tolerating being called before a route exists.
  Future<String?> _token({bool forceRefresh = false}) async {
    final BuildContext? context = Get.context;
    if (context == null) return null;
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      return await userProvider.getFreshToken(forceRefresh: forceRefresh);
    } catch (e) {
      debugPrint('ChargingController: failed to read token: $e');
      return null;
    }
  }

  /// Starts refreshing the battery list on a timer.
  ///
  /// Reference-counted: screens stay mounted underneath each other (the
  /// dashboard under the charging view), so polling only stops once every
  /// screen that asked for it has called [stopPolling]. The shortest requested
  /// interval wins.
  void startPolling({Duration interval = const Duration(seconds: 2)}) {
    _pollClients++;
    _pollWanted = true;
    if (_pollClients == 1 || interval < _pollInterval) {
      _pollInterval = interval;
      _cancelPollTimer();
    }
    _ensurePollTimer();
  }

  /// Releases one [startPolling] request; polling stops with the last one.
  void stopPolling() {
    if (_pollClients > 0) _pollClients--;
    if (_pollClients > 0) return;
    _pollWanted = false;
    _cancelPollTimer();
  }

  void _ensurePollTimer() {
    if (!_inForeground || !_pollWanted) return;
    if (_pollTimer != null && _pollTimer!.isActive) return;
    _pollTimer = Timer.periodic(
      _pollInterval,
      (_) => refreshBatteries(silent: true),
    );
  }

  void _cancelPollTimer() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  /// Refreshes the battery list and derives the session type.
  Future<ActiveSessionType> checkSessionStatus({String? manualToken}) async {
    final token = manualToken ?? await _token();
    if (token == null) {
      isLoading.value = false;
      return sessionType.value;
    }

    isLoading.value = batteries.isEmpty;
    try {
      final pending = await _boothService.getPendingWithdrawals(token);
      pendingWithdrawal.value = pending.isEmpty ? null : pending.first;
      hasPendingWithdrawal.value = pending.isNotEmpty;

      await refreshBatteries(token: token, silent: true);

      if (pending.isNotEmpty) {
        sessionType.value = ActiveSessionType.payment;
      } else {
        sessionType.value =
            batteries.isEmpty ? ActiveSessionType.none : ActiveSessionType.charging;
      }
      return sessionType.value;
    } catch (e) {
      debugPrint('Error checking session status: $e');
      isLoading.value = false;
      if (!hasPendingWithdrawal.value) {
        sessionType.value =
            batteries.isEmpty ? ActiveSessionType.none : ActiveSessionType.charging;
      }
      return sessionType.value;
    }
  }

  /// Pulls the full battery array and reconciles it with the UI + listeners.
  ///
  /// Overlapping calls share the in-flight request, so callers that read
  /// [batteries] afterwards always see the result of a completed fetch.
  Future<void> refreshBatteries({String? token, bool silent = false}) {
    final running = _inFlightRefresh;
    if (running != null) return running;
    final request = _refreshBatteries(token: token, silent: silent)
        .whenComplete(() => _inFlightRefresh = null);
    _inFlightRefresh = request;
    return request;
  }

  Future<void> _refreshBatteries({String? token, bool silent = false}) async {
    if (!silent) isLoading.value = true;

    try {
      final authToken = token ?? await _token();
      if (authToken == null) return;

      List<MyBatteryStatus> fetched;
      try {
        fetched = await _boothService.getMyBatteryStatuses(authToken);
      } on BoothApiException catch (e) {
        if (!e.isAuthError) rethrow;
        // The cached token may have expired: retry once with a fresh one.
        final fresh = await _token(forceRefresh: true);
        if (fresh == null) rethrow;
        fetched = await _boothService.getMyBatteryStatuses(fresh);
      }

      // Drop sessions the backend has finished/closed, then merge by identity so
      // ordering and in-flight Firebase updates are preserved.
      final incoming = fetched.where(_isStillHeld).toList();
      final merged = <MyBatteryStatus>[];
      for (final status in incoming) {
        final index = batteries.indexWhere((b) => b.key == status.key);
        if (index >= 0) {
          final live = batteries[index];
          // Keep the freshest value field-by-field.
          merged.add(
            status.copyWith(
              chargeLevel: status.chargeLevel != 0
                  ? status.chargeLevel
                  : live.chargeLevel,
              telemetry: status.telemetry ?? live.telemetry,
              sessionStatus: status.sessionStatus.isNotEmpty
                  ? status.sessionStatus
                  : live.sessionStatus,
            ),
          );
        } else {
          merged.add(status);
        }
      }

      batteries.assignAll(merged);
      _clampActiveIndex();
      _syncListeners();

      if (!hasPendingWithdrawal.value) {
        sessionType.value = batteries.isEmpty
            ? ActiveSessionType.none
            : ActiveSessionType.charging;
      }
    } catch (e) {
      // Timer-driven and fire-and-forget callers have nowhere to handle this;
      // keep the last known list and try again on the next tick.
      debugPrint('ChargingController: refresh failed: $e');
    } finally {
      isLoading.value = false;
    }
  }

  bool _isStillHeld(MyBatteryStatus status) {
    if (status.isTerminal) return false;
    // A completed deposit whose battery is physically gone is over.
    if (status.sessionStatus.toLowerCase() == 'completed' &&
        status.telemetry != null &&
        status.telemetry!.reportsInsertion &&
        !status.telemetry!.batteryInserted) {
      return false;
    }
    return true;
  }

  void _clampActiveIndex() {
    if (batteries.isEmpty) {
      activeIndex.value = 0;
    } else if (activeIndex.value >= batteries.length) {
      activeIndex.value = batteries.length - 1;
    }
  }

  void selectBattery(int index) {
    if (index >= 0 && index < batteries.length) {
      activeIndex.value = index;
    }
  }

  /// Attaches one Firebase listener per battery and cancels stale ones.
  void _syncListeners() {
    final wanted = <String>{};

    for (final status in batteries) {
      if (status.boothUid.isEmpty || status.slotIdentifier.isEmpty) continue;
      final key = status.key;
      wanted.add(key);
      if (_listeners.containsKey(key)) continue;

      final ref =
          _db.ref('booths/${status.boothUid}/slots/${status.slotIdentifier}');
      _listeners[key] = ref.onValue.listen(
        (event) => _onSlotUpdate(key, event.snapshot.value),
        onError: (error) => debugPrint('Firebase Realtime DB error ($key): $error'),
      );
    }

    for (final key in _listeners.keys.toList()) {
      if (wanted.contains(key)) continue;
      _listeners.remove(key)?.cancel();
    }
  }

  void _onSlotUpdate(String key, dynamic data) {
    if (data is! Map) return;
    final index = batteries.indexWhere((b) => b.key == key);
    if (index < 0) return;

    final current = batteries[index];
    final dynamic rawTelemetry = data['telemetry'];
    BatteryTelemetry? telemetry = current.telemetry;
    if (rawTelemetry is Map) {
      telemetry = BatteryTelemetry.fromJson(
        Map<String, dynamic>.from(rawTelemetry),
      );
    }

    final double rawSoc = telemetry?.soc ??
        (data['chargeLevel'] is num
            ? (data['chargeLevel'] as num).toDouble()
            : (data['soc'] is num ? (data['soc'] as num).toDouble() : 0));

    final updated = current.copyWith(
      chargeLevel: rawSoc > 0 ? rawSoc.round() : current.chargeLevel,
      telemetry: telemetry,
    );

    // Battery physically removed and deposit fully confirmed → drop the card.
    final statusLower = current.sessionStatus.toLowerCase();
    if (telemetry != null &&
        telemetry.reportsInsertion &&
        !telemetry.batteryInserted &&
        (statusLower == 'completed' ||
            statusLower == 'collected' ||
            statusLower == 'cancelled' ||
            statusLower == 'failed')) {
      removeBatteryAt(index);
      return;
    }

    batteries[index] = updated;
  }

  void removeBatteryAt(int index) {
    if (index < 0 || index >= batteries.length) return;
    final removed = batteries.removeAt(index);
    _listeners.remove(removed.key)?.cancel();
    _clampActiveIndex();
    if (batteries.isEmpty && !hasPendingWithdrawal.value) {
      sessionType.value = ActiveSessionType.none;
    }
  }

  void removeBatteryBySessionId(int sessionId) {
    final index = batteries.indexWhere((b) => b.sessionId == sessionId);
    if (index >= 0) removeBatteryAt(index);
  }

  /// Stops charging for [index] (defaults to the active card) and moves to the
  /// relay wait screen.
  Future<void> initiateCollection({int? index}) async {
    final target = index == null ? activeBattery : batteryAt(index);
    if (target == null) return;

    isLoading.value = true;
    try {
      final token = await _token();
      if (token == null) {
        _snack('Authentication failed', isError: true);
        return;
      }

      collectionSessionId.value = target.sessionId;
      activeIndex.value = batteries.indexOf(target);

      await _boothService.stopCharging(token, target.sessionId);
      Get.toNamed(
        '/stop-charging',
        arguments: {'sessionId': target.sessionId},
      );
    } catch (e) {
      _snack('Action failed: ${_message(e)}', isError: true);
    } finally {
      isLoading.value = false;
    }
  }

  /// Creates the withdrawal session for the battery being collected.
  Future<void> startWithdrawal() async {
    final sessionId = collectionSessionId.value ?? activeBattery?.sessionId;
    if (sessionId == null) {
      _snack('No battery selected', isError: true);
      return;
    }

    try {
      final token = await _token();
      if (token == null) {
        _snack('Authentication failed', isError: true);
        return;
      }

      await _boothService.initiateWithdrawal(token, sessionId);
      Get.offAllNamed('/payment', arguments: {'sessionId': sessionId});
    } catch (e) {
      _snack('Withdrawal failed: ${_message(e)}', isError: true);
      Get.offAllNamed('/dashboard');
    }
  }

  String _message(Object error) {
    if (error is BoothApiException) return error.message;
    return error.toString().replaceFirst('Exception: ', '');
  }

  void _snack(String message, {bool isError = false}) {
    Get.snackbar(
      isError ? 'Error' : 'Maxtekhub',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: isError ? Colors.redAccent : null,
      colorText: isError ? Colors.white : null,
    );
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollClients = 0;
    stopPolling();
    for (final sub in _listeners.values) {
      sub.cancel();
    }
    _listeners.clear();
    super.onClose();
  }
}
