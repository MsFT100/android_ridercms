import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../models/booth_models.dart';
import '../providers/user_provider.dart';
import '../services/booth_service.dart';

class ChargingController extends GetxController {
  final BoothService _boothService = BoothService();
  
  var batteryStatus = Rxn<MyBatteryStatus>();
  var isLoading = true.obs;
  var elapsedSeconds = 0.obs;
  
  Timer? _statusTimer;
  Timer? _elapsedTimer;

  @override
  void onInit() {
    super.onInit();
    _startElapsedTimer();
    _startPolling();
  }

  void _startElapsedTimer() {
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      elapsedSeconds.value++;
    });
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
    final token = await userProvider.getFreshToken();
    if (token == null) return;

    try {
      final status = await _boothService.getMyBatteryStatus(token);
      
      if (status == null) {
        // Battery likely collected, end session
        _stopTimers();
        Get.offAllNamed('/dashboard');
        return;
      }

      batteryStatus.value = status;
      isLoading.value = false;
    } catch (e) {
      // Silently continue polling
    }
  }

  void _stopTimers() {
    _statusTimer?.cancel();
    _elapsedTimer?.cancel();
  }

  String formatTime(int secs) {
    final m = secs ~/ 60;
    final s = secs % 60;
    return '${m}m ${s}s';
  }

  Future<void> initiateCollection() async {
    // This will be handled in the billing/payment flow usually
    Get.toNamed('/payment'); 
  }

  @override
  void onClose() {
    _stopTimers();
    super.onClose();
  }
}
