import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../models/booth_models.dart';
import '../providers/user_provider.dart';
import '../services/booth_service.dart';

enum ActiveSessionType { none, charging, payment }

class ChargingController extends GetxController {
  final BoothService _boothService = BoothService();
  final FirebaseDatabase _db = FirebaseDatabase.instance;
  
  var batteryStatus = Rxn<MyBatteryStatus>();
  var isLoading = true.obs;
  var elapsedSeconds = 0.obs;
  var sessionType = ActiveSessionType.none.obs;
  
  StreamSubscription? _statusSubscription;
  Timer? _elapsedTimer;

  bool hasActiveSession() {
    return sessionType.value != ActiveSessionType.none;
  }

  @override
  void onInit() {
    super.onInit();
    _startElapsedTimer();
    // Start fetching status immediately when controller is initialized
    checkSessionStatus();
  }

  void _startElapsedTimer() {
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      elapsedSeconds.value++;
    });
  }

  /// Fetches status and determines the active session type.
  Future<ActiveSessionType> checkSessionStatus({String? manualToken}) async {
    isLoading.value = true;
    String? token = manualToken;
    
    try {
      if (token == null) {
        final BuildContext? context = Get.context;
        if (context == null) {
          isLoading.value = false;
          return ActiveSessionType.none;
        }
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        token = await userProvider.getFreshToken();
      }

      if (token == null) {
        isLoading.value = false;
        return ActiveSessionType.none;
      }

      // 1. Check for pending withdrawal FIRST
      final pendingWithdrawal = await _boothService.getPendingWithdrawal(token);
      if (pendingWithdrawal != null) {
        sessionType.value = ActiveSessionType.payment;
        isLoading.value = false;
        return ActiveSessionType.payment;
      }

      // 2. Check for active charging session
      final status = await _boothService.getMyBatteryStatus(token);
      
      if (status != null) {
        // If session is "completed" and battery is already removed, consider it NO session.
        final bool isBatteryGone = status.telemetry?['batteryInserted'] == false;
        final bool isSessionOver = status.sessionStatus.toLowerCase() == 'completed' || 
                                 status.sessionStatus.toLowerCase() == 'collected';
        
        if (isSessionOver && isBatteryGone) {
          batteryStatus.value = null;
          sessionType.value = ActiveSessionType.none;
          isLoading.value = false;
          return ActiveSessionType.none;
        }

        batteryStatus.value = status;
        sessionType.value = ActiveSessionType.charging;
        _listenToFirebase(status);
        isLoading.value = false;
        return ActiveSessionType.charging;
      }
      
      batteryStatus.value = null;
      sessionType.value = ActiveSessionType.none;
      isLoading.value = false;
      return ActiveSessionType.none;
    } catch (e) {
      debugPrint('Error checking session status: $e');
      sessionType.value = ActiveSessionType.none;
      isLoading.value = false;
      return ActiveSessionType.none;
    }
  }

  void _listenToFirebase(MyBatteryStatus status) {
    _statusSubscription?.cancel();
    final ref = _db.ref('booths/${status.boothUid}/slots/${status.slotIdentifier}');
    
    _statusSubscription = ref.onValue.listen((event) {
      final data = event.snapshot.value;
      if (data == null || data is! Map) return;

      final int chargeLevel = data['chargeLevel'] ?? data['soc'] ?? status.chargeLevel;
      final String sessionStatus = data['sessionStatus'] ?? data['status'] ?? status.sessionStatus;
      
      final Map<String, dynamic> telemetry = {};
      if (data['telemetry'] != null) {
        telemetry.addAll(Map<String, dynamic>.from(data['telemetry'] as Map));
      } else {
        telemetry['temperatureC'] = data['temperatureC'] ?? data['temp'];
        telemetry['voltage'] = data['voltage'] ?? data['volt'];
        telemetry['batteryInserted'] = data['batteryInserted'];
      }

      // Update the reactive status variable
      batteryStatus.value = MyBatteryStatus(
        batteryUid: status.batteryUid,
        boothUid: status.boothUid,
        slotIdentifier: status.slotIdentifier,
        chargeLevel: chargeLevel,
        sessionStatus: sessionStatus,
        telemetry: telemetry.isNotEmpty ? telemetry : status.telemetry,
      );

      // Handle session termination from Firebase more accurately
      final bool isBatteryGone = telemetry['batteryInserted'] == false;
      final String normalizedStatus = sessionStatus.toLowerCase();
      
      if (normalizedStatus == 'collected' || normalizedStatus == 'inactive' || (normalizedStatus == 'completed' && isBatteryGone)) {
        _stopTimers();
        batteryStatus.value = null;
        sessionType.value = ActiveSessionType.none;
        
        // If we're currently on the charging screen, go back to dashboard
        if (Get.currentRoute == '/charging') {
          Get.offAllNamed('/dashboard');
        }
      }
    }, onError: (error) {
      debugPrint('Firebase Realtime DB Error: $error');
    });
  }

  Future<void> initiateCollection() async {
    isLoading.value = true;
    try {
      final BuildContext? context = Get.context;
      if (context == null) return;
      
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final token = await userProvider.getFreshToken();
      
      if (token == null) {
        Get.snackbar('Error', 'Authentication failed');
        return;
      }

      final response = await _boothService.stopCharging(token);
      debugPrint('Stop Charging Response: $response');

      Get.toNamed('/stop-charging');
    } catch (e) {
      Get.snackbar('Action Failed', e.toString(), 
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> startWithdrawal() async {
    try {
      final BuildContext? context = Get.context;
      if (context == null) return;
      
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final token = await userProvider.getFreshToken();
      
      if (token == null) {
        Get.snackbar('Error', 'Authentication failed');
        return;
      }

      await _boothService.initiateWithdrawal(token);
      // Automatically proceed to payment screen
      Get.offAllNamed('/payment');
    } catch (e) {
      Get.snackbar('Withdrawal Failed', e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white
      );
      // If it fails, we might want to go back to the charging screen or dashboard
      Get.offAllNamed('/dashboard');
    }
  }

  void _stopTimers() {
    _statusSubscription?.cancel();
    _elapsedTimer?.cancel();
  }

  String formatTime(int secs) {
    final m = secs ~/ 60;
    final s = secs % 60;
    return '${m}m ${s}s';
  }

  @override
  void onClose() {
    _stopTimers();
    super.onClose();
  }
}
