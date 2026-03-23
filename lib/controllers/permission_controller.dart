import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionController extends GetxController {
  var isLocationGranted = false.obs;
  var isCameraGranted = false.obs;

  @override
  void onInit() {
    super.onInit();
    checkInitialPermissions();
  }

  Future<void> checkInitialPermissions() async {
    isLocationGranted.value = await Permission.location.isGranted;
    isCameraGranted.value = await Permission.camera.isGranted;

    if (!isLocationGranted.value || !isCameraGranted.value) {
      await requestAllPermissions();
    } else {
      if (kDebugMode) {
        print("All permissions granted");
      }
    }
  }

  Future<bool> requestLocationPermission() async {
    final status = await Permission.location.request();
    isLocationGranted.value = status.isGranted;
    return status.isGranted;
  }

  Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    isCameraGranted.value = status.isGranted;
    return status.isGranted;
  }

  Future<void> requestAllPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
      Permission.camera,
    ].request();

    isLocationGranted.value = statuses[Permission.location]?.isGranted ?? false;
    isCameraGranted.value = statuses[Permission.camera]?.isGranted ?? false;
  }
}
