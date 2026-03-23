import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import '../providers/user_provider.dart';
import '../services/booth_service.dart';

enum DoorStatus { opening, open, insert, closing, closed }

class SlotAssignedController extends GetxController {
  final BoothService _boothService = BoothService();
  
  var doorStatus = DoorStatus.opening.obs;
  var step = 0.obs;
  var slotIdentifier = '---'.obs;
  var boothName = 'Station'.obs;
  
  Timer? _pollingTimer;

  final steps = const [
    {'label': 'Opening door...', 'icon': Icons.lock_open},
    {'label': 'Door Open – Insert Battery', 'icon': Icons.door_front_door},
    {'label': 'Battery Inserted', 'icon': Icons.battery_full},
    {'label': 'Closing door...', 'icon': Icons.lock},
    {'label': 'Door Closed – Charging Started', 'icon': Icons.bolt},
  ];

  @override
  void onInit() {
    super.onInit();
    final dynamic args = Get.arguments;
    
    // Support nested slot structure from backend response
    if (args != null) {
      if (args['slotIdentifier'] != null) {
        slotIdentifier.value = args['slotIdentifier'].toString();
      } else if (args['slot'] != null && args['slot']['identifier'] != null) {
        slotIdentifier.value = args['slot']['identifier'].toString();
      }
      
      boothName.value = args['boothName'] ?? 'Station';
    }

    // UI sequence simulation for visuals
    _simulateSequence();
    
    // Start real polling for backend confirmation
    _startPolling();
  }

  void _simulateSequence() {
    Future.delayed(const Duration(seconds: 2), () {
      if (doorStatus.value == DoorStatus.opening) {
        doorStatus.value = DoorStatus.open;
        step.value = 1;
      }
    });
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      final BuildContext? context = Get.context;
      if (context == null) return;
      
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      
      try {
        final token = await userProvider.getFreshToken();
        if (token == null) return;

        final status = await _boothService.getMyBatteryStatus(token);

        if (kDebugMode) {
          print("Polled Status: ${status?.sessionStatus}");
        }
        
        if (status != null && status.sessionStatus != 'pending') {
          _pollingTimer?.cancel();
          
          doorStatus.value = DoorStatus.closed;
          step.value = 4;
          
          Future.delayed(const Duration(seconds: 1), () {
            Get.offAllNamed('/charging');
          });
        }
      } catch (e) {
        if (kDebugMode) print("Polling error: $e");
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
    super.onClose();
  }
}
