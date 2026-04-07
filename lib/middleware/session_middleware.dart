import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/charging_controller.dart';

class SessionMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    // Check if controller exists, if not, initialize it. 
    // This prevents "Controller not found" errors during navigation.
    if (!Get.isRegistered<ChargingController>()) {
      Get.put(ChargingController());
    }
    
    final chargingController = Get.find<ChargingController>();

    if (chargingController.hasActiveSession()) {
      return const RouteSettings(name: '/charging');
    }
    return null;
  }
}
