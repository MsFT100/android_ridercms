import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import '../providers/user_provider.dart';
import '../services/booth_service.dart';

enum DoorStatus { opening, open, insert, closing, closed }

class SlotAssignedController extends GetxController {
  final BoothService _boothService = BoothService();
  final FirebaseDatabase _db = FirebaseDatabase.instance;

  var doorStatus = DoorStatus.opening.obs;
  var slotIdentifier = '---'.obs;
  var boothName = 'Station'.obs;
  var boothUid = ''.obs;

  StreamSubscription? _statusSubscription;
  Timer? _pollingTimer;

  @override
  void onInit() {
    super.onInit();
    final dynamic args = Get.arguments;
    
    if (args != null) {
      if (args['slotIdentifier'] != null) {
        slotIdentifier.value = args['slotIdentifier'].toString();
      } else if (args['slot'] != null && args['slot']['identifier'] != null) {
        slotIdentifier.value = args['slot']['identifier'].toString();
      }
      
      boothName.value = args['boothName'] ?? 'Station';
      boothUid.value = args['boothUid'] ?? '';
    }

    // UI sequence simulation for initial visuals
    _simulateOpening();

    // Start Realtime Database listener
    if (boothUid.value.isNotEmpty && slotIdentifier.value != '---') {
      _startFirebaseListener();
    }
    
    // Fallback polling
    _startPolling();
  }

  void _simulateOpening() {
    Future.delayed(const Duration(seconds: 2), () {
      if (doorStatus.value == DoorStatus.opening) {
        doorStatus.value = DoorStatus.open;
      }
    });
  }

  void _startFirebaseListener() {
    final ref = _db.ref('booths/${boothUid.value}/slots/${slotIdentifier.value}');
    
    _statusSubscription = ref.onValue.listen((event) {
      final data = event.snapshot.value;
      if (data == null || data is! Map) return;

      final bool doorLocked = data['doorLocked'] ?? data['locked'] ?? false;
      final bool batteryInserted = data['batteryInserted'] ?? data['present'] ?? false;

      if (batteryInserted && doorLocked) {
        _onSequenceComplete();
      } else if (batteryInserted) {
        doorStatus.value = DoorStatus.insert;
      } else if (!doorLocked) {
        doorStatus.value = DoorStatus.open;
      }
    });
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      final BuildContext? context = Get.context;
      if (context == null) return;

      final userProvider = Provider.of<UserProvider>(context, listen: false);

      try {
        final token = await userProvider.getFreshToken();
        if (token == null) return;

        final status = await _boothService.getMyBatteryStatus(token);

        if (status != null && status.sessionStatus != 'pending') {
          _onSequenceComplete();
        }
      } catch (e) {
        if (kDebugMode) print("Polling error: $e");
      }
    });
  }

  void _onSequenceComplete() {
    _pollingTimer?.cancel();
    _statusSubscription?.cancel();
    
    doorStatus.value = DoorStatus.closed;

    // Navigate to charging screen after a short delay
    Future.delayed(const Duration(seconds: 1), () {
      if (Get.currentRoute == '/slot-assigned') {
        Get.offAllNamed('/charging');
      }
    });
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
      Get.snackbar('Error', 'Failed to cancel session: $e', 
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white
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
