import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../models/booth_models.dart';
import '../providers/user_provider.dart';
import '../services/booth_service.dart';

class CollectController extends GetxController {
  final BoothService _boothService = BoothService();
  
  var batteryStatus = Rxn<MyBatteryStatus>();
  var isLoading = true.obs;
  var isCollected = false.obs;
  
  Timer? _statusTimer;

  @override
  void onInit() {
    super.onInit();
    _startPolling();
  }

  void _startPolling() {
    _fetchStatus(); // Initial fetch
    
    _statusTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      await _fetchStatus();
    });
  }

  Future<void> _fetchStatus() async {
    final BuildContext? context = Get.context;
    if (context == null) return;
    
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final token = userProvider.getFreshToken();

    try {
      final status = await _boothService.getMyBatteryStatus(token as String);
      
      if (status == null) {
        // If status is null, it means the battery session is over (collected and door closed)
        _statusTimer?.cancel();
        isCollected.value = true;
        return;
      }

      batteryStatus.value = status;
      isLoading.value = false;
    } catch (e) {
      // Silently continue polling
    }
  }

  Future<void> finishSession() async {
    _statusTimer?.cancel();
    Get.offAllNamed('/session-complete');
  }

  @override
  void onClose() {
    _statusTimer?.cancel();
    super.onClose();
  }
}
