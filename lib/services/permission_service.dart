import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:get/get.dart'; // Import Get
import 'package:ridercms/utils/themes/app_theme.dart'; // Import your theme constants

class PermissionService {
  static Future<void> _handlePermission(Permission permission) async {
    final status = await permission.status;

    if (status.isGranted) {
      return;
    }

    if (status.isDenied) {
      final result = await permission.request();
      if (!result.isGranted) {
        showPermissionDialog(permission);
      }
    }

    if (status.isPermanentlyDenied) {
      showPermissionDialog(permission);
    }
  }

  static void showPermissionDialog(Permission permission) {
    final permissionDetails = _getPermissionDetails(permission);

    // Using Get.dialog instead of showDialog (No context needed)
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: kBgCard, // Using your theme constant
        title: Row(
          children: [
            Icon(permissionDetails.icon, color: kAccent), // Using your theme constant
            const SizedBox(width: 10),
            Text(
              permissionDetails.title,
              style: const TextStyle(color: kTextPrimary),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              permissionDetails.message,
              style: const TextStyle(fontSize: 14, color: kTextPrimary),
            ),
            const SizedBox(height: 12),
            const Text(
              "You can enable this in your device's system settings.",
              style: TextStyle(fontSize: 12, color: kTextSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(), // Using Get to navigate back
            child: const Text(
              "Later",
              style: TextStyle(color: kTextSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary, // Fixed from AppTheme.lightPrimary
              minimumSize: const Size(120, 40), // Adjusted size for dialog
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              Get.back();
              await openAppSettings();
            },
            child: const Text(
              "Open Settings",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  /// Maps permission to explanation details
  static _PermissionInfo _getPermissionDetails(Permission permission) {
    switch (permission) {
      case Permission.location:
        return _PermissionInfo(
          title: "Location Access",
          message: "Location is required to match you with nearby ride requests.",
          icon: Icons.location_on,
        );
      case Permission.notification:
        return _PermissionInfo(
          title: "Notifications",
          message: "We alert you about new rides, trip updates, and payments.",
          icon: Icons.notifications_active,
        );
      case Permission.camera:
        return _PermissionInfo(
          title: "Camera Access",
          message: "Camera is needed to upload documents or profile pictures.",
          icon: Icons.camera_alt,
        );
      case Permission.storage:
        return _PermissionInfo(
          title: "Storage Access",
          message: "Storage permission lets you upload and manage documents.",
          icon: Icons.folder,
        );
      default:
        return _PermissionInfo(
          title: "Permission Needed",
          message: "This permission is necessary for full app functionality.",
          icon: Icons.info_outline,
        );
    }
  }

  // Individual request methods (Context removed since GetX doesn't need it)
  static Future<bool> requestLocationPermission() async {
    await _handlePermission(Permission.location);
    return await Permission.location.isGranted;
  }

  static Future<bool> requestCameraPermission() async {
    await _handlePermission(Permission.camera);
    return await Permission.camera.isGranted;
  }

  static Future<bool> requestNotificationPermission() async {
    await _handlePermission(Permission.notification);
    return await Permission.notification.isGranted;
  }
}

class _PermissionInfo {
  final String title;
  final String message;
  final IconData icon;

  _PermissionInfo({
    required this.title,
    required this.message,
    required this.icon,
  });
}